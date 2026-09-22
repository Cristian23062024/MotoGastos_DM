import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/expense_inputs.dart';
import '../models/motorcycle.dart';
import '../services/claude_vision_recognition_service.dart';
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
      : recognitionService = service ??
            (ClaudeVisionRecognitionService.isConfigured
                ? ClaudeVisionRecognitionService()
                : const MockRecognitionService());

  final MotorcycleRecognitionService recognitionService;

  /// true si se está usando el reconocimiento simulado porque no hay
  /// ANTHROPIC_API_KEY / ANTHROPIC_MODEL configurados. Las pantallas lo
  /// usan para mostrar un aviso discreto de "modo demostración".
  bool get usingDemoRecognition => recognitionService is MockRecognitionService;

  File? capturedImage;
  Motorcycle? motorcycle;
  ExpenseInputs? expenses;

  RecognitionStatus status = RecognitionStatus.idle;
  String? errorMessage;

  void setCapturedImage(File file) {
    capturedImage = file;
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
    } catch (_) {
      status = RecognitionStatus.error;
      errorMessage = 'Ocurrió un error inesperado analizando la foto.';
    }
    notifyListeners();
  }

  /// El usuario corrigió los datos de la moto en la pantalla de resultado.
  /// Si cambió el cilindraje, se recalculan el SOAT y el impuesto
  /// sugeridos (dependen de él); el resto de los valores que ya haya
  /// editado en la pantalla de gastos se conserva.
  void updateMotorcycle(Motorcycle moto) {
    motorcycle = moto;
    final suggested = ExpenseInputs.sugeridoPara(moto);
    final current = expenses;
    expenses = current == null
        ? suggested
        : current.copyWith(soat: suggested.soat, impuesto: suggested.impuesto);
    notifyListeners();
  }

  void updateExpenses(ExpenseInputs inputs) {
    expenses = inputs;
    notifyListeners();
  }

  /// Vuelve al punto de partida para escanear otra moto.
  void reset() {
    capturedImage = null;
    motorcycle = null;
    expenses = null;
    status = RecognitionStatus.idle;
    errorMessage = null;
    notifyListeners();
  }
}
