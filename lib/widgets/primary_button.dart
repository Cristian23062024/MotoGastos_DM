import 'package:flutter/material.dart';

/// El botón de acción principal, reutilizado en varias pantallas
/// (Bienvenida, Resultado). Es un `ElevatedButton` normal — un botón real,
/// no un contenedor con `onTap`, para que siga siendo accesible con
/// teclado y lector de pantalla.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
