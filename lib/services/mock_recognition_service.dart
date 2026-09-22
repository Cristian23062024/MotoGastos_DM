import 'dart:io';

import '../models/motorcycle.dart';
import 'motorcycle_recognition_service.dart';

/// Implementación de demostración: no llama a ninguna API, solo espera un
/// momento y devuelve una moto de ejemplo. Se usa automáticamente cuando la
/// app no tiene configurada una API key (ver `AppState`), para que se
/// pueda probar todo el flujo sin depender de un servicio externo.
class MockRecognitionService implements MotorcycleRecognitionService {
  const MockRecognitionService();

  @override
  Future<Motorcycle> recognize(File imageFile) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const Motorcycle(
      brand: 'Yamaha',
      model: 'FZ 150',
      category: 'Naked',
      engineCc: 149,
      estimatedYear: 2022,
      estimatedWeightKg: 127,
      confidence: 0.92,
    );
  }
}
