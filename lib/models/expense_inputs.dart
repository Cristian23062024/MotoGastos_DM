import '../data/colombia_rates_2026.dart';
import 'motorcycle.dart';

/// Los seis números editables que arman el estimado de gasto anual.
/// Todo lo demás (gasolina, total, mensual) se calcula a partir de estos.
class ExpenseInputs {
  final int soat;
  final int tecnomecanica;
  final int impuesto;
  final int kmAnual;
  final int rendimientoKmPorGalon;
  final int precioGalon;
  final int mantenimiento;

  const ExpenseInputs({
    required this.soat,
    required this.tecnomecanica,
    required this.impuesto,
    required this.kmAnual,
    required this.rendimientoKmPorGalon,
    required this.precioGalon,
    required this.mantenimiento,
  });

  /// Valores por defecto sugeridos para una moto recién reconocida, a
  /// partir de las tarifas 2026 y su cilindraje.
  factory ExpenseInputs.sugeridoPara(Motorcycle moto) {
    return ExpenseInputs(
      soat: soatAnualParaCc(moto.engineCc),
      tecnomecanica: ColombiaRates2026.tecnomecanicaDefault,
      impuesto: estimarImpuestoVehicular(moto.engineCc),
      kmAnual: ColombiaRates2026.kmAnualDefault,
      rendimientoKmPorGalon: ColombiaRates2026.rendimientoKmPorGalonDefault,
      precioGalon: ColombiaRates2026.precioGalonDefault,
      mantenimiento: ColombiaRates2026.mantenimientoDefault,
    );
  }

  /// Galones de gasolina que se consumen al año.
  double get galonesAnuales =>
      rendimientoKmPorGalon > 0 ? kmAnual / rendimientoKmPorGalon : 0;

  /// Gasto anual estimado en gasolina.
  int get gasolina => (galonesAnuales * precioGalon).round();

  /// Suma de las cinco categorías: SOAT, tecnomecánica, impuesto,
  /// gasolina y mantenimiento.
  int get total => soat + tecnomecanica + impuesto + gasolina + mantenimiento;

  /// Equivalente mensual del total anual.
  int get mensual => (total / 12).round();

  ExpenseInputs copyWith({
    int? soat,
    int? tecnomecanica,
    int? impuesto,
    int? kmAnual,
    int? rendimientoKmPorGalon,
    int? precioGalon,
    int? mantenimiento,
  }) {
    return ExpenseInputs(
      soat: soat ?? this.soat,
      tecnomecanica: tecnomecanica ?? this.tecnomecanica,
      impuesto: impuesto ?? this.impuesto,
      kmAnual: kmAnual ?? this.kmAnual,
      rendimientoKmPorGalon: rendimientoKmPorGalon ?? this.rendimientoKmPorGalon,
      precioGalon: precioGalon ?? this.precioGalon,
      mantenimiento: mantenimiento ?? this.mantenimiento,
    );
  }
}
