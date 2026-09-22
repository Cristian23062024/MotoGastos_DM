/// Formatea un número como pesos colombianos, con punto como separador de
/// miles (p. ej. 6598168 -> "$6.598.168"). Se implementa a mano para no
/// depender del paquete `intl` solo por esto.
String formatCop(num value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }

  return '${isNegative ? '-' : ''}\$${buffer.toString()}';
}

/// Igual que [formatCop] pero sin el símbolo de peso, útil dentro de
/// campos de texto editables.
String formatThousands(num value) {
  final withSign = formatCop(value);
  return withSign.replaceFirst('\$', '');
}
