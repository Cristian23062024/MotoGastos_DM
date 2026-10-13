import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:motogastos/models/expense_inputs.dart';
import 'package:motogastos/services/gemini_vision_recognition_service.dart';
import 'package:motogastos/services/recognition_exception.dart';

String _envelope(Object? partText) => jsonEncode({
      'candidates': [
        {
          'content': {
            'role': 'model',
            'parts': [
              {'text': partText},
            ],
          },
          'finishReason': 'STOP',
        },
      ],
    });

void main() {
  group('GeminiVisionRecognitionService.parseResponse', () {
    test('lleva cada campo de Gemini a su lugar en Motorcycle', () {
      final moto = GeminiVisionRecognitionService.parseResponse(_envelope(jsonEncode({
        'brand': 'Yamaha',
        'model': 'FZ 150',
        'category': 'Naked',
        'engine_cc': 149,
        'estimated_year': 2022,
        'estimated_weight_kg': 127,
        'fuel_efficiency_km_l': 42.5,
        'engine_type': '4 Tiempos',
        'usage': 'Uso urbano',
        'confidence': 0.91,
      })));

      expect(moto.displayName, 'Yamaha FZ 150');
      expect(moto.category, 'Naked');
      expect(moto.engineCc, 149);
      expect(moto.estimatedYear, 2022);
      expect(moto.estimatedWeightKg, 127);
      expect(moto.fuelEfficiencyKmL, 42.5);
      expect(moto.engineType, '4 Tiempos');
      expect(moto.usage, 'Uso urbano');
      expect(moto.confidencePercent, 91);
    });

    test('el consumo estimado alimenta el rendimiento de gasolina', () {
      final moto = GeminiVisionRecognitionService.parseResponse(_envelope(jsonEncode({
        'brand': 'Honda',
        'model': 'CB 190R',
        'category': 'Naked',
        'engine_cc': 184,
        'fuel_efficiency_km_l': 40,
        'confidence': 0.8,
      })));
      // 40 km/l × 3,785 l/galón ≈ 151 km/galón.
      expect(ExpenseInputs.sugeridoPara(moto).rendimientoKmPorGalon, 151);
    });

    test('tolera campos opcionales nulos', () {
      final moto = GeminiVisionRecognitionService.parseResponse(_envelope(jsonEncode({
        'brand': 'Bajaj',
        'model': 'Boxer',
        'category': 'Trabajo',
        'engine_cc': 100,
        'estimated_year': null,
        'fuel_efficiency_km_l': null,
        'confidence': 0.4,
      })));
      expect(moto.estimatedYear, isNull);
      expect(moto.kmPorGalon, isNull);
    });

    test('lanza RecognitionException si no hay moto en la foto', () {
      expect(
        () => GeminiVisionRecognitionService.parseResponse(_envelope(jsonEncode({
          'brand': 'Sin moto',
          'model': '',
          'category': 'Moto',
          'engine_cc': 0,
          'confidence': 0,
        }))),
        throwsA(isA<RecognitionException>()),
      );
    });

    test('lanza RecognitionException si la foto fue bloqueada', () {
      expect(
        () => GeminiVisionRecognitionService.parseResponse(
          jsonEncode({'promptFeedback': {'blockReason': 'SAFETY'}}),
        ),
        throwsA(isA<RecognitionException>()),
      );
    });

    test('lanza RecognitionException con texto que no es JSON', () {
      expect(
        () => GeminiVisionRecognitionService.parseResponse(_envelope('no sé')),
        throwsA(isA<RecognitionException>()),
      );
    });
  });

  group('GeminiVisionRecognitionService.recognize', () {
    late File image;
    final okBody = _envelope(jsonEncode({
      'brand': 'Yamaha',
      'model': 'FZ 150',
      'category': 'Naked',
      'engine_cc': 149,
      'confidence': 0.9,
    }));

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('moto');
      image = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);
    });

    GeminiVisionRecognitionService serviceWith(MockClient client) =>
        GeminiVisionRecognitionService(
          client: client,
          apiKey: 'test',
          retryDelay: Duration.zero,
        );

    test('reintenta cuando Gemini responde 503', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return calls < 3
            ? http.Response('{"error":{"code":503}}', 503)
            : http.Response(okBody, 200);
      });
      final moto = await serviceWith(client).recognize(image);
      expect(moto.displayName, 'Yamaha FZ 150');
      expect(calls, 3);
    });

    test('pasa al modelo de respaldo si el principal sigue saturado', () async {
      final models = <String>[];
      final client = MockClient((request) async {
        final model = request.url.pathSegments.last.split(':').first;
        models.add(model);
        return model == 'gemini-flash-latest'
            ? http.Response('{"error":{"code":503}}', 503)
            : http.Response(okBody, 200);
      });
      await serviceWith(client).recognize(image);
      expect(models, [
        'gemini-flash-latest',
        'gemini-flash-latest',
        'gemini-flash-latest',
        'gemini-flash-lite-latest',
      ]);
    });

    test('si el modelo principal se cuelga, pasa al de respaldo', () async {
      final models = <String>[];
      final client = MockClient((request) async {
        final model = request.url.pathSegments.last.split(':').first;
        models.add(model);
        if (model == 'gemini-flash-latest') {
          await Future<void>.delayed(const Duration(seconds: 5));
        }
        return http.Response(okBody, 200);
      });
      final service = GeminiVisionRecognitionService(
        client: client,
        apiKey: 'test',
        retryDelay: Duration.zero,
        timeout: const Duration(milliseconds: 50),
      );
      final moto = await service.recognize(image);
      expect(moto.brand, 'Yamaha');
      expect(models, ['gemini-flash-latest', 'gemini-flash-lite-latest']);
    });

    test('no reintenta errores definitivos como 400', () async {
      var calls = 0;
      final client = MockClient((_) async {
        calls++;
        return http.Response('{"error":{"code":400}}', 400);
      });
      await expectLater(
        serviceWith(client).recognize(image),
        throwsA(isA<RecognitionException>()),
      );
      expect(calls, 1);
    });

    test('acepta confianza 0 si sí identificó una marca', () async {
      final client = MockClient((_) async => http.Response(
            _envelope(jsonEncode({
              'brand': 'AKT',
              'model': 'NKD 125',
              'category': 'Naked',
              'engine_cc': 125,
              'confidence': 0,
            })),
            200,
          ));
      final moto = await serviceWith(client).recognize(image);
      expect(moto.brand, 'AKT');
    });
  });
}
