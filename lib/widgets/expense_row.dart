import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../utils/currency.dart';

/// Una fila de la pantalla de gastos: ícono, etiqueta + subtítulo, y a la
/// derecha el valor formateado (modo lectura) o un campo numérico (modo
/// edición). El campo usa `initialValue` a propósito: así no pierde el
/// cursor mientras el usuario escribe, y se refresca solo cuando la fila
/// se vuelve a montar (por ejemplo, al salir y volver a entrar en modo
/// edición).
class ExpenseRow extends StatelessWidget {
  final Widget icon;
  final String label;
  final String subtitle;
  final int value;
  final bool editing;
  final ValueChanged<int> onChanged;
  final bool showDivider;

  const ExpenseRow({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.editing,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconBadge(child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (editing)
            SizedBox(
              width: 112,
              child: Semantics(
                textField: true,
                label: '$label anual, en pesos',
                child: TextFormField(
                  initialValue: value.toString(),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  onChanged: (text) => onChanged(int.tryParse(text) ?? 0),
                ),
              ),
            )
          else
            Text(
              formatCop(value),
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final Widget child;
  const _IconBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(11),
      ),
      child: child,
    );
  }
}
