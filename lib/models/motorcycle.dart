/// Una motocicleta identificada por la cámara (o ingresada/corregida a mano
/// por el usuario en la pantalla de resultado).
class Motorcycle {
  final String brand;
  final String model;
  final String category;
  final int engineCc;
  final int? estimatedYear;
  final int? estimatedWeightKg;

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
  });

  String get displayName =>
      model.trim().isEmpty ? brand : '$brand $model'.trim();

  int get confidencePercent => (confidence.clamp(0, 1) * 100).round();

  Motorcycle copyWith({
    String? brand,
    String? model,
    String? category,
    int? engineCc,
    int? estimatedYear,
    int? estimatedWeightKg,
    double? confidence,
  }) {
    return Motorcycle(
      brand: brand ?? this.brand,
      model: model ?? this.model,
      category: category ?? this.category,
      engineCc: engineCc ?? this.engineCc,
      estimatedYear: estimatedYear ?? this.estimatedYear,
      estimatedWeightKg: estimatedWeightKg ?? this.estimatedWeightKg,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Construye una [Motorcycle] a partir del JSON que devuelve el servicio
  /// de reconocimiento. Es deliberadamente tolerante: si la IA no llena
  /// algún campo, se usa un valor por defecto razonable en vez de fallar.
  factory Motorcycle.fromJson(Map<String, dynamic> json) {
    return Motorcycle(
      brand: (json['brand'] as String?)?.trim().isNotEmpty == true
          ? (json['brand'] as String).trim()
          : 'Marca no identificada',
      model: (json['model'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim().isNotEmpty == true
          ? (json['category'] as String).trim()
          : 'Moto',
      engineCc: _asInt(json['engine_cc']) ?? 150,
      estimatedYear: _asInt(json['estimated_year']),
      estimatedWeightKg: _asInt(json['estimated_weight_kg']),
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
        'confidence': confidence,
      };

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
