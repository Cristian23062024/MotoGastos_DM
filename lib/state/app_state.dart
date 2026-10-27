import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/expense_inputs.dart';
import '../models/motorcycle.dart';
import '../models/saved_scan.dart';
import '../services/claude_vision_recognition_service.dart';
import '../services/gemini_vision_recognition_service.dart';
import '../services/mock_recognition_service.dart';
import '../services/motorcycle_recognition_service.dart';
import '../services/recognition_exception.dart';

enum RecognitionStatus { idle, analyzing, success, error }

/// Estado compartido de todo el flujo: la foto tomada, la moto reconocida
/// (o corregida a mano) y los gastos calculados. Vive por encima del
/// `Navigator` (ver `app.dart`) para que las cinco pantallas lo compartan
/// sin tener que pasarse datos manualmente entre rutas.
class AppState extends ChangeNotifier {
  AppState({MotorcycleRecognitionService? service})
      : recognitionService = service ?? _defaultService();

  /// Gemini tiene prioridad; si no hay GEMINI_API_KEY se intenta con
  /// Claude, y si tampoco está configurado se usa la simulación.
  static MotorcycleRecognitionService _defaultService() {
    if (GeminiVisionRecognitionService.isConfigured) {
      return GeminiVisionRecognitionService();
    }
    if (ClaudeVisionRecognitionService.isConfigured) {
      return ClaudeVisionRecognitionService();
    }
    return const MockRecognitionService();
  }

  final MotorcycleRecognitionService recognitionService;

  /// true si se está usando el reconocimiento simulado porque no hay
  /// ninguna API key configurada. Las pantallas lo usan para mostrar un
  /// aviso discreto de "modo demostración".
  bool get usingDemoRecognition => recognitionService is MockRecognitionService;

  /// Nombre corto del motor de reconocimiento, para mostrar en la interfaz.
  String get recognitionEngineName => switch (recognitionService) {
        GeminiVisionRecognitionService() => 'Gemini Vision',
        ClaudeVisionRecognitionService() => 'Claude Vision',
        _ => 'Modo demo',
      };

  File? capturedImage;
  Motorcycle? motorcycle;
  ExpenseInputs? expenses;

  /// Id del escaneo ya guardado (ver `AccountState.saveScan`), para
  /// actualizarlo en vez de duplicarlo cuando el usuario edita valores.
  String? scanId;

  RecognitionStatus status = RecognitionStatus.idle;
  String? errorMessage;

  void setCapturedImage(File file) {
    capturedImage = file;
    scanId = null;
    status = RecognitionStatus.idle;
    errorMessage = null;
    notifyListeners();
  }

  /// Envía la foto capturada al servicio de reconocimiento y, si tiene
  /// éxito, prepara los gastos sugeridos para esa moto.
  Future<void> analyze() async {
    final image = capturedImage;
    if (image == null) {
      status = RecognitionStatus.error;
      errorMessage = 'No hay ninguna foto para analizar.';
      notifyListeners();
      return;
    }

    status = RecognitionStatus.analyzing;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await recognitionService.recognize(image);
      motorcycle = result;
      expenses = ExpenseInputs.sugeridoPara(result);
      status = RecognitionStatus.success;
    } on RecognitionException catch (e) {
      status = RecognitionStatus.error;
      errorMessage = e.message;
    } catch (e, stack) {
      debugPrint('Error inesperado reconociendo la moto: $e\n$stack');
      status = RecognitionStatus.error;
      errorMessage = 'Ocurrió un error inesperado analizando la foto.';
    }
    notifyListeners();
  }

  /// El usuario corrigió los datos de la moto en la pantalla de resultado.
  /// Se recalculan el SOAT y el impuesto sugeridos (dependen del
  /// cilindraje) y, si cambió el consumo, el rendimiento de gasolina; el
  /// resto de los valores que ya haya editado en la pantalla de gastos se
  /// conserva.
  void updateMotorcycle(Motorcycle moto) {
    final previous = motorcycle;
    motorcycle = moto;
    final suggested = ExpenseInputs.sugeridoPara(moto);
    final current = expenses;
    expenses = current == null
        ? suggested
        : current.copyWith(
            soat: suggested.soat,
            impuesto: suggested.impuesto,
            rendimientoKmPorGalon: previous?.kmPorGalon != moto.kmPorGalon
                ? suggested.rendimientoKmPorGalon
                : null,
          );
    notifyListeners();
  }

  void updateExpenses(ExpenseInputs inputs) {
    expenses = inputs;
    notifyListeners();
  }

  /// Reabre un escaneo guardado (sin foto) para verlo o editarlo.
  void openSavedScan(SavedScan scan) {
    capturedImage = null;
    motorcycle = scan.motorcycle;
    expenses = scan.expenses;
    scanId = scan.id;
    status = RecognitionStatus.success;
    errorMessage = null;
    notifyListeners();
  }

  /// Vuelve al punto de partida para escanear otra moto.
  void reset() {
    capturedImage = null;
    motorcycle = null;
    expenses = null;
    scanId = null;
    status = RecognitionStatus.idle;
    errorMessage = null;
    notifyListeners();
  }
}
