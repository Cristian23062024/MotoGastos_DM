import 'dart:convert';

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
}
