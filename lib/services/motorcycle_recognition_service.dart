import 'dart:io';

import '../models/motorcycle.dart';

/// Contrato para cualquier motor de reconocimiento de motos por foto.
///
/// Hay dos implementaciones: [ClaudeVisionRecognitionService] (llama a una
/// API de visión en la nube) y [MockRecognitionService] (respuesta
/// simulada, para desarrollar sin conexión o sin una API key configurada).
/// Cambiar de una a otra no requiere tocar las pantallas: `AppState` decide
/// cuál usar.
abstract class MotorcycleRecognitionService {
  /// Analiza la foto en [imageFile] y devuelve la mejor estimación de la
  /// moto que aparece en ella. Debe lanzar [RecognitionException] (no
  /// otras excepciones sin envolver) si algo falla, para que la pantalla
  /// de análisis pueda mostrar un mensaje claro.
  Future<Motorcycle> recognize(File imageFile);
}
