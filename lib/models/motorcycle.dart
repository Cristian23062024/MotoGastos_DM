/// Una motocicleta identificada por la cámara (o ingresada/corregida a mano
/// por el usuario en la pantalla de resultado).
class Motorcycle {
  final String brand;
  final String model;
  final String category;
  final int engineCc;
  final int? estimatedYear;
  final int? estimatedWeightKg;

  /// Consumo promedio estimado en ciclo urbano, en km por litro.
  final double? fuelEfficiencyKmL;

  /// Tipo de motor, p. ej. "4 Tiempos", "2 Tiempos" o "Eléctrica".
  final String? engineType;

  /// Uso típico, p. ej. "Uso urbano", "Trabajo", "Aventura".
  final String? usage;

  /// Confianza del reconocimiento, entre 0.0 y 1.0.
  final double confidence;

  const Motorcycle({
    required this.brand,
    required this.model,
    required this.category,
    required this.engineCc,
    required this.confidence,
    this.estimatedYear,
    this.estimatedWeightKg,
    this.fuelEfficiencyKmL,
    this.engineType,
    this.usage,
  });

  /// Litros que tiene un galón estadounidense, la unidad de venta de la
  /// gasolina en Colombia.
  static const double litrosPorGalon = 3.785;

  String get displayName =>
      model.trim().isEmpty ? brand : '$brand $model'.trim();

  int get confidencePercent => (confidence.clamp(0, 1) * 100).round();

  /// Rendimiento en km/galón derivado del consumo en km/L, o null si la IA
  /// no lo estimó.
  int? get kmPorGalon => fuelEfficiencyKmL == null || fuelEfficiencyKmL! <= 0
      ? null
      : (fuelEfficiencyKmL! * litrosPorGalon).round();

  Motorcycle copyWith({
    String? brand,
    String? model,
    String? category,
    int? engineCc,
    int? estimatedYear,
    int? estimatedWeightKg,
    double? fuelEfficiencyKmL,
    String? engineType,
    String? usage,
    double? confidence,
  }) {
    return Motorcycle(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      engineCc: engineCc ?? this.engineCc,
      estimatedYear: estimatedYear ?? this.estimatedYear,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      fuelEfficiencyKmL: fuelEfficiencyKmL ?? this.fuelEfficiencyKmL,
      engineType: engineType ?? this.engineType,
      usage: usage ?? this.usage,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Construye una [Motorcycle] a partir del JSON que devuelve el servicio
  /// de reconocimiento. Es deliberadamente tolerante: si la IA no llena
  /// algún campo, se usa un valor por defecto razonable en vez de fallar.
  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    return Motorcycle(
      brand: _asText(json['brand']) ?? 'Marca no identificada',
      model: _asText(json['model']) ?? '',
      category: _asText(json['category']) ?? 'Moto',
      engineCc: _asInt(json['engine_cc']) ?? 150,
      estimatedYear: _asInt(json['estimated_year']),
      estimatedWeightKg: _asInt(json['estimated_weight_kg']),
      fuelEfficiencyKmL: _asDouble(json['fuel_efficiency_km_l']),
      engineType: _asText(json['engine_type']),
      usage: _asText(json['usage']),
      confidence: _asDouble(json['confidence']) ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'category': category,
        'engine_cc': engineCc,
        'estimated_year': estimatedYear,
        'estimated_weight_kg': estimatedWeightKg,
        'fuel_efficiency_km_l': fuelEfficiencyKmL,
        'engine_type': engineType,
        'usage': usage,
        'confidence': confidence,
      };

  static String? _asText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
