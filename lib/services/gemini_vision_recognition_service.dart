import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/motorcycle.dart';
import 'motorcycle_recognition_service.dart';
import 'recognition_exception.dart';
import 'recognition_prompt.dart';

/// API key y modelo de Gemini se pasan en tiempo de compilación, igual que
/// los de Claude — nunca quedan escritos en el código ni como asset:
///
///   flutter run --dart-define-from-file=env.json
///
/// con un `env.json` (copiado de `env.json.example`, y en `.gitignore`)
/// que trae `GEMINI_API_KEY` y, opcionalmente, `GEMINI_MODEL`. La key se
/// crea en https://aistudio.google.com/apikey.
///
/// Igual que con Claude: en producción conviene poner un backend propio
/// que guarde la key y reenvíe la foto; basta con cambiar [_endpointFor].
const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
const String _model = String.fromEnvironment(
  'GEMINI_MODEL',
  // Alias que Google mantiene apuntando al Flash estable más reciente.
  defaultValue: 'gemini-flash-latest',
);

/// Modelo de respaldo cuando el principal sigue saturado (503) tras los
/// reintentos. Vacío para desactivarlo.
const String _fallbackModel = String.fromEnvironment(
  'GEMINI_FALLBACK_MODEL',
  defaultValue: 'gemini-flash-lite-latest',
);

/// Códigos que Gemini devuelve por saturación o fallos pasajeros: vale la
/// pena reintentar en vez de mostrar el error de una vez.
const Set<int> _retryableStatuses = {429, 500, 502, 503, 504};

/// Esquema de salida estructurada: Gemini garantiza que la respuesta sea
/// un JSON con exactamente estos campos, los mismos de `Motorcycle.fromJson`.
const Map<String, dynamic> _responseSchema = {
  'type': 'OBJECT',
  'properties': {
    'brand': {'type': 'STRING'},
    'model': {'type': 'STRING'},
    'category': {'type': 'STRING'},
    'engine_cc': {'type': 'INTEGER'},
    'estimated_year': {'type': 'INTEGER', 'nullable': true},
    'estimated_weight_kg': {'type': 'INTEGER', 'nullable': true},
    'fuel_efficiency_km_l': {'type': 'NUMBER', 'nullable': true},
    'engine_type': {'type': 'STRING', 'nullable': true},
    'usage': {'type': 'STRING', 'nullable': true},
    'confidence': {'type': 'NUMBER'},
  },
  'required': ['brand', 'model', 'category', 'engine_cc', 'confidence'],
  'propertyOrdering': [
    'brand',
    'model',
    'category',
    'engine_cc',
    'estimated_year',
    'estimated_weight_kg',
    'fuel_efficiency_km_l',
    'engine_type',
    'usage',
    'confidence',
  ],
};

/// Reconocimiento real usando la API de Gemini (Google AI) con la foto de
/// la cámara adjunta como `inline_data`.
class GeminiVisionRecognitionService implements MotorcycleRecognitionService {
  final Uri? _endpointOverride;
  final http.Client? _client;
  final String _key;
  /// Tiempo máximo de espera de cada solicitud.
  final Duration timeout;

  /// Tiempo máximo de todo el reconocimiento, sumando reintentos y el
  /// modelo de respaldo, para que el usuario no espere indefinidamente.
  final Duration totalTimeout;

  /// Intentos por modelo ante errores pasajeros (ver [_retryableStatuses]).
  final int maxAttempts;

  /// Espera base entre reintentos; se duplica en cada intento.
  final Duration retryDelay;

  GeminiVisionRecognitionService({
    Uri? endpoint,
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 30),
    this.totalTimeout = const Duration(seconds: 75),
    this.maxAttempts = 3,
    this.retryDelay = const Duration(seconds: 1),
  })  : _endpointOverride = endpoint,
        _client = client,
        _key = apiKey ?? _apiKey;

  /// true cuando hay una API key de Gemini configurada al compilar.
  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Modelo que se usará (útil para mostrarlo en la interfaz).
  static String get modelName => _model;

  Uri _endpointFor(String model) =>
      _endpointOverride ??
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$model:generateContent',
      );

  /// Modelo principal y, si es distinto, el de respaldo.
  static List<String> get _models => [
        _model,
        if (_fallbackModel.isNotEmpty && _fallbackModel != _model)
          _fallbackModel,
      ];

  @override
  Future<Motorcycle> recognize(File imageFile) async {
    if (_key.isEmpty) {
      throw const RecognitionException(
        'Falta configurar GEMINI_API_KEY (--dart-define-from-file=env.json). '
        'Mientras tanto se usa el modo de demostración.',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': imageMimeTypeFor(imageFile.path),
                'data': base64Encode(bytes),
              },
            },
            {'text': recognitionPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseSchema': _responseSchema,
      },
    });

    final client = _client ?? http.Client();
    try {
      final response = await _postWithRetries(client, body);
      return parseResponse(response.body);
    } on RecognitionException catch (e) {
      debugPrint('Gemini: ${e.message}\n${e.cause}');
      rethrow;
    } finally {
      if (_client == null) client.close();
    }
  }

  /// Envía la solicitud reintentando con espera exponencial ante errores
  /// pasajeros, y pasa al modelo de respaldo si el principal sigue
  /// saturado o se queda colgado (con alta demanda Gemini a veces no
  /// responde nada en vez de devolver 503). Todo cabe en [totalTimeout].
  /// Devuelve solo respuestas 200.
  Future<http.Response> _postWithRetries(http.Client client, String body) async {
    final deadline = DateTime.now().add(totalTimeout);
    http.Response? last;
    var timedOut = false;

    for (final model in _models) {
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        final remaining = deadline.difference(DateTime.now());
        if (remaining <= Duration.zero) break;
        final attemptTimeout = remaining < timeout ? remaining : timeout;

        try {
          last = await _post(client, model, body, attemptTimeout);
        } on TimeoutException {
          debugPrint(
            'Gemini $model intento $attempt/$maxAttempts: sin respuesta en '
            '${attemptTimeout.inSeconds} s',
          );
          timedOut = true;
          // Reintentar el mismo modelo colgado casi nunca funciona; se pasa
          // directo al de respaldo.
          break;
        }

        if (last.statusCode == 200) return last;
        timedOut = false;
        debugPrint(
          'Gemini $model intento $attempt/$maxAttempts: '
          '${last.statusCode} ${last.body}',
        );
        if (!_retryableStatuses.contains(last.statusCode)) {
          throw RecognitionException(
            _messageForStatus(last.statusCode, model),
            last.body,
          );
        }
        if (attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay * (1 << (attempt - 1)));
        }
      }
    }

    if (last == null || timedOut) {
      throw const RecognitionException(
        'Gemini está tardando demasiado en responder, probablemente por alta '
        'demanda. Espera unos segundos y toca "Reintentar".',
      );
    }
    throw RecognitionException(
      _messageForStatus(last.statusCode, _model),
      last.body,
    );
  }

  Future<http.Response> _post(
    http.Client client,
    String model,
    String body,
    Duration attemptTimeout,
  ) async {
    try {
      return await client
          .post(
            _endpointFor(model),
            headers: {
              'x-goog-api-key': _key,
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(attemptTimeout);
    } on SocketException {
      throw const RecognitionException(
        'No hay conexión a internet. El reconocimiento necesita datos o '
        'wifi para analizar la foto.',
      );
    } on http.ClientException catch (e) {
      throw RecognitionException('Error de red: ${e.message}', e);
    }
  }

  /// Convierte el cuerpo de una respuesta exitosa de `generateContent` en
  /// una [Motorcycle]. Es estático para poder probarlo sin red.
  static Motorcycle parseResponse(String responseBody) {
    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(responseBody) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw RecognitionException('La respuesta de Gemini no se pudo leer.', e);
    }

    final blockReason = (envelope['promptFeedback'] as Map?)?['blockReason'];
    if (blockReason != null) {
      throw RecognitionException(
        'Gemini rechazó la foto ($blockReason). Intenta con otra imagen.',
        envelope,
      );
    }

    final candidates = envelope['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw RecognitionException(
        'La respuesta de Gemini no trajo resultados.',
        envelope,
      );
    }

    final candidate = candidates.first as Map<String, dynamic>;
    final parts = (candidate['content'] as Map?)?['parts'];
    final text = parts is List
        ? parts
            .whereType<Map>()
            .where((p) => p['thought'] != true)
            .map((p) => p['text'])
            .whereType<String>()
            .join()
        : '';

    if (text.trim().isEmpty) {
      final reason = candidate['finishReason'];
      throw RecognitionException(
        reason == 'SAFETY'
            ? 'Gemini no pudo analizar esta foto. Intenta con otra imagen.'
            : 'La respuesta de Gemini no trajo datos para analizar.',
        envelope,
      );
    }

    final motoJson = extractJsonObject(text);
    if (motoJson == null) {
      throw RecognitionException(
        'No se pudo interpretar la respuesta como los datos de una moto.',
        text,
      );
    }

    final moto = Motorcycle.fromJson(motoJson);
    // Solo "Sin moto" significa que no hay moto: una confianza baja con una
    // marca real sigue siendo una estimación útil que el usuario corrige.
    if (moto.brand.toLowerCase() == 'sin moto') {
      throw RecognitionException(
        'No encontramos una moto en la foto. Encuádrala completa, con buena '
        'luz, y vuelve a intentarlo.',
        motoJson,
      );
    }
    return moto;
  }

  static String _messageForStatus(int status, String model) {
    switch (status) {
      case 400:
        return 'Gemini no aceptó la solicitud (400). Revisa que GEMINI_API_KEY '
            'y GEMINI_MODEL sean válidos.';
      case 401:
      case 403:
        return 'La API key de Gemini no tiene permiso ($status). Revisa '
            'GEMINI_API_KEY.';
      case 404:
        return 'El modelo "$model" no existe en Gemini (404). Revisa '
            'GEMINI_MODEL.';
      case 503:
        return 'Gemini está saturado en este momento (503). Espera unos '
            'segundos y toca "Reintentar".';
      case 429:
        return 'Se alcanzó el límite de uso de Gemini (429). Espera un momento '
            'e inténtalo de nuevo.';
      default:
        return 'El servicio de reconocimiento respondió con un error '
            '($status). Intenta de nuevo en un momento.';
    }
  }
}
