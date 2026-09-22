import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/motorcycle.dart';
import 'motorcycle_recognition_service.dart';
import 'recognition_exception.dart';

/// API key y modelo se pasan en tiempo de compilación, NUNCA quedan escritos
/// en el código fuente ni empaquetados como asset (eso los dejaría
/// extraíbles del .apk/.ipa). Se usan así:
///
///   flutter run --dart-define-from-file=env.json
///
/// con un `env.json` (copiado de `env.json.example`, y en `.gitignore`)
/// que trae `ANTHROPIC_API_KEY` y `ANTHROPIC_MODEL`.
///
/// Para producción real: no llames la API de visión directamente desde el
/// celular. Pon un backend propio (aunque sea una función serverless
/// pequeña) que guarde la API key y reciba la foto del cliente — así la
/// clave nunca viaja dentro de la app instalada. Esta clase queda lista
/// para apuntar a ese backend simplemente cambiando [_endpoint].
const String _apiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
const String _model = String.fromEnvironment('ANTHROPIC_MODEL');

const String _promptTexto = '''
Eres un experto en motocicletas que circulan en Colombia. Observa la foto
y responde EXCLUSIVAMENTE con un objeto JSON (sin texto adicional, sin
explicación, sin bloque de código Markdown) con esta forma exacta:

{
  "brand": "marca, por ejemplo Yamaha",
  "model": "línea o referencia, por ejemplo FZ 150",
  "category": "tipo de moto: Naked, Scooter, Enduro, Deportiva, Trabajo, etc.",
  "engine_cc": 150,
  "estimated_year": 2022,
  "estimated_weight_kg": 127,
  "confidence": 0.85
}

"engine_cc" es el cilindraje estimado en centímetros cúbicos (entero).
"estimated_year" es el año aproximado de fabricación (entero, o null si de
verdad no se puede estimar). "estimated_weight_kg" es el peso aproximado en
kg (entero, o null). "confidence" es un número entre 0 y 1 que refleja qué
tan seguro estás. Si no reconoces la moto con certeza, da tu mejor
estimación razonada igual y baja "confidence" en vez de dejar campos vacíos.
''';

/// Reconocimiento real usando la API de mensajes de Anthropic (Claude) con
/// una imagen adjunta. Requiere una API key con acceso a un modelo con
/// visión — revisa el modelo vigente en
/// https://docs.claude.com/en/docs/about-claude/models antes de compilar.
class ClaudeVisionRecognitionService implements MotorcycleRecognitionService {
  final Uri _endpoint;
  final Duration timeout;

  ClaudeVisionRecognitionService({
    Uri? endpoint,
    this.timeout = const Duration(seconds: 40),
  }) : _endpoint = endpoint ?? Uri.parse('https://api.anthropic.com/v1/messages');

  /// true cuando hay API key y modelo configurados en tiempo de compilación.
  static bool get isConfigured => _apiKey.isNotEmpty && _model.isNotEmpty;

  @override
  Future<Motorcycle> recognize(File imageFile) async {
    if (!isConfigured) {
      throw const RecognitionException(
        'Falta configurar ANTHROPIC_API_KEY y ANTHROPIC_MODEL '
        '(--dart-define-from-file=env.json). Mientras tanto se usa el '
        'modo de demostración.',
      );
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mediaType = _mediaTypeFor(imageFile.path);

    final body = jsonEncode({
      'model': _model,
      'max_tokens': 700,
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': mediaType,
                'data': base64Image,
              },
            },
            {'type': 'text', 'text': _promptTexto},
          ],
        },
      ],
    });

    http.Response response;
    try {
      response = await http
          .post(
            _endpoint,
            headers: {
              'x-api-key': _apiKey,
              'anthropic-version': '2023-06-01',
              'content-type': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const RecognitionException(
        'El reconocimiento tardó demasiado. Verifica tu conexión e '
        'inténtalo de nuevo.',
      );
    } on SocketException {
      throw const RecognitionException(
        'No hay conexión a internet. El reconocimiento necesita datos o '
        'wifi para analizar la foto.',
      );
    } on HttpException catch (e) {
      throw RecognitionException('Error de red: ${e.message}', e);
    }

    if (response.statusCode != 200) {
      throw RecognitionException(
        'El servicio de reconocimiento respondió con un error '
        '(${response.statusCode}). Intenta de nuevo en un momento.',
        response.body,
      );
    }

    final Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw RecognitionException(
        'La respuesta del servicio no se pudo leer.',
        e,
      );
    }

    final content = envelope['content'];
    if (content is! List || content.isEmpty) {
      throw RecognitionException(
        'La respuesta del servicio no trajo contenido.',
        envelope,
      );
    }

    final firstBlock = content.first;
    final text = firstBlock is Map<String, dynamic> ? firstBlock['text'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw RecognitionException(
        'La respuesta del servicio no trajo texto para analizar.',
        envelope,
      );
    }

    final motoJson = _extractJsonObject(text);
    if (motoJson == null) {
      throw RecognitionException(
        'No se pudo interpretar la respuesta como los datos de una moto.',
        text,
      );
    }

    return Motorcycle.fromJson(motoJson);
  }

  /// El modelo a veces envuelve el JSON en una frase o en ```json ... ```
  /// pese a la instrucción; esto busca el primer objeto `{ ... }` del texto
  /// y lo decodifica, en vez de asumir que la respuesta es JSON puro.
  Map<String, dynamic>? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) return null;
    final candidate = text.substring(start, end + 1);
    try {
      final decoded = jsonDecode(candidate);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
  }
}
