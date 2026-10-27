import 'expense_inputs.dart';
import 'motorcycle.dart';

/// Un escaneo guardado: la moto (tal como quedó tras las correcciones del
/// usuario) y los gastos que editó. La foto no se guarda.
class SavedScan {
  /// Id de la fila en Supabase, o [localId] para el escaneo del invitado.
  final String id;
  final Motorcycle motorcycle;
  final ExpenseInputs expenses;
  final DateTime createdAt;

  static const String localId = 'local';

  const SavedScan({
    required this.id,
    required this.motorcycle,
    required this.expenses,
    required this.createdAt,
  });

  /// Mismo formato que la tabla `scans` de `supabase/schema.sql`.
  Map<String, dynamic> toJson() => {
        'id': id,
        'motorcycle': motorcycle.toJson(),
        'expenses': expenses.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  factory SavedScan.fromJson(Map<String, dynamic> json) => SavedScan(
        id: json['id'] as String,
        motorcycle:
            Motorcycle.fromJson(json['motorcycle'] as Map<String, dynamic>),
        expenses:
            ExpenseInputs.fromJson(json['expenses'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
