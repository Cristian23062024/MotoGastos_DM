/// Tarifas y valores de referencia para motocicletas en Colombia, 2026.
///
/// Estos son valores INVESTIGADOS y editables: sirven como punto de partida
/// razonable, no como cotización oficial. El usuario puede ajustarlos en la
/// pantalla de gastos. Fuentes usadas al construir esta app (revisar y
/// actualizar cada año, pues varían con la UVT, decretos y el mercado):
///  - SOAT 2026 por cilindraje: El Tiempo, "Tarifas Soat 2026" (feb. 2026).
///  - Tecnomecánica 2026: El Tiempo, "Así quedaron las tarifas del 2026
///    para revisión tecnomecánica de motos" (feb. 2026).
///  - Impuesto vehicular: Dian.com.co, "Impuesto de motos en Colombia 2026"
///    (fórmula avalúo x 1,5% para motos > 125 cc; exentas las de 125 cc o
///    menos, que solo pagan derechos de semaforización en algunos
///    municipios).
///  - Gasolina corriente: promedio nacional y por ciudad, septiembre 2026
///    (Pulzo / Infobae, con datos de la CREG).
///  - Mantenimiento preventivo: rango estimado por talleres y guías de
///    costos (SYM Colombia, "Costos reales de tener moto 2026").
library;

/// Un rango de cilindraje y la tarifa anual de SOAT que le corresponde.
class SoatBracket {
  final String label;
  final int? maxCc; // null = sin límite superior (más de 200 cc)
  final int annualValue;

  const SoatBracket({
    required this.label,
    required this.maxCc,
    required this.annualValue,
  });
}

const List<SoatBracket> soatBrackets2026 = [
  SoatBracket(label: 'Ciclomotor (≤ 50 cc)', maxCc: 50, annualValue: 124100),
  SoatBracket(label: 'Motos hasta 100 cc', maxCc: 100, annualValue: 256200),
  SoatBracket(label: 'Motos de 101 a 200 cc', maxCc: 200, annualValue: 343300),
  SoatBracket(label: 'Motos de más de 200 cc', maxCc: null, annualValue: 761400),
];

/// Devuelve la tarifa anual de SOAT 2026 que corresponde a un cilindraje.
int soatAnualParaCc(int cc) {
  for (final bracket in soatBrackets2026) {
    if (bracket.maxCc == null || cc <= bracket.maxCc!) {
      return bracket.annualValue;
    }
  }
  return soatBrackets2026.last.annualValue;
}

/// Puntos de referencia (cilindraje -> avalúo comercial aproximado) usados
/// para estimar el impuesto vehicular por interpolación. Los valores base
/// vienen de ejemplos publicados de motos populares en Colombia; el
/// resultado es solo una guía inicial, el avalúo oficial se consulta en el
/// RUNT / Ministerio de Transporte (SIBGA).
class _AvaluoPoint {
  final int cc;
  final int avaluo;
  const _AvaluoPoint(this.cc, this.avaluo);
}

const List<_AvaluoPoint> _avaluoReferencia = [
  _AvaluoPoint(150, 8500000), // p. ej. Yamaha FZ 150
  _AvaluoPoint(190, 11000000), // p. ej. Honda CB190R
  _AvaluoPoint(200, 13500000), // p. ej. Bajaj Pulsar NS200
  _AvaluoPoint(310, 25000000), // p. ej. BMW G310R
  _AvaluoPoint(400, 30000000), // p. ej. Kawasaki Ninja 400
];

int _estimarAvaluo(int cc) {
  if (cc <= _avaluoReferencia.first.cc) {
    return _avaluoReferencia.first.avaluo;
  }
  for (var i = 0; i < _avaluoReferencia.length - 1; i++) {
    final a = _avaluoReferencia[i];
    final b = _avaluoReferencia[i + 1];
    if (cc >= a.cc && cc <= b.cc) {
      final t = (cc - a.cc) / (b.cc - a.cc);
      return (a.avaluo + (b.avaluo - a.avaluo) * t).round();
    }
  }
  final last = _avaluoReferencia.last;
  final prev = _avaluoReferencia[_avaluoReferencia.length - 2];
  final slope = (last.avaluo - prev.avaluo) / (last.cc - prev.cc);
  return (last.avaluo + slope * (cc - last.cc)).round();
}

/// Estima el impuesto vehicular anual 2026 para una moto de [cc]
/// centímetros cúbicos. Motos de 125 cc o menos están exentas del impuesto
/// (solo pagan derechos de semaforización en algunos municipios, que no se
/// incluyen aquí porque varían mucho por ciudad).
int estimarImpuestoVehicular(int cc) {
  if (cc <= ColombiaRates2026.impuestoExentoHastaCc) return 0;
  final avaluo = _estimarAvaluo(cc);
  return (avaluo * ColombiaRates2026.impuestoTasa).round();
}

/// Valores por defecto que no dependen del cilindraje.
class ColombiaRates2026 {
  ColombiaRates2026._();

  /// Precio promedio estimado de la revisión tecnomecánica de motos en 2026
  /// (rango oficial aproximado: 217.781 a 246.890 COP).
  static const int tecnomecanicaDefault = 230000;

  /// Tarifa del impuesto vehicular sobre el avalúo comercial.
  static const double impuestoTasa = 0.015;

  /// Motos de este cilindraje o menos están exentas del impuesto vehicular.
  static const int impuestoExentoHastaCc = 125;

  /// Kilometraje anual típico de un usuario que usa la moto a diario.
  static const int kmAnualDefault = 12000;

  /// Rendimiento típico de una moto urbana de baja/media cilindrada.
  static const int rendimientoKmPorGalonDefault = 38;

  /// Precio de referencia del galón de gasolina corriente (promedio
  /// aproximado en ciudades principales, septiembre 2026).
  static const int precioGalonDefault = 16300;

  /// Mantenimiento preventivo anual estimado (aceite, frenos, ajustes;
  /// no incluye cambios grandes como llantas o cadena, que son más
  /// esporádicos).
  static const int mantenimientoDefault = 750000;
}
