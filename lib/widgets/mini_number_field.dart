import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Uno de los tres campos pequeños del bloque de gasolina (km/año,
/// km/galón, $/galón), con su etiqueta encima.
class MiniNumberField extends StatelessWidget {
  final String label;
  final String semanticLabel;
  final int value;
  final ValueChanged<int> onChanged;

  const MiniNumberField({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.labelCaps),
        const SizedBox(height: 4),
        Semantics(
          textField: true,
          label: semanticLabel,
          child: TextFormField(
            initialValue: value.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: AppText.labelMd.copyWith(fontWeight: FontWeight.w600),
            onChanged: (text) => onChanged(int.tryParse(text) ?? 0),
          ),
        ),
      ],
    );
  }
}
