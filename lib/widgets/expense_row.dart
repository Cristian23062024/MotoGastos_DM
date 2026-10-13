import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/currency.dart';
import 'glass.dart';

/// Una tarjeta de la pantalla de gastos: ícono, etiqueta + subtítulo, y a
/// la derecha el valor formateado (modo lectura) o un campo numérico (modo
/// edición). El campo usa `initialValue` a propósito: así no pierde el
/// cursor mientras el usuario escribe, y se refresca solo cuando la fila
/// se vuelve a montar (por ejemplo, al salir y volver a entrar en modo
/// edición).
class ExpenseRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final int value;
  final bool editing;
  final ValueChanged<int> onChanged;

  const ExpenseRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.editing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconBadge(icon: icon, color: iconColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headlineSm,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.bodySm),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (editing)
            SizedBox(
              width: 120,
              child: Semantics(
                textField: true,
                label: '$label anual, en pesos',
                child: TextFormField(
                  initialValue: value.toString(),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.headlineSm,
                  decoration: const InputDecoration(prefixText: '\$ '),
                  onChanged: (text) => onChanged(int.tryParse(text) ?? 0),
                ),
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                formatCop(value),
                style: AppText.telemetry.copyWith(fontSize: 22),
              ),
            ),
        ],
      ),
    );
  }
}
