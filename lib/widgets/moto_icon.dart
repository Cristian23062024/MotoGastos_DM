import 'package:flutter/material.dart';

/// Ícono de línea de una moto vista de perfil, dibujado a mano (sin
/// depender de ningún paquete de íconos ni de emoji) — las dos ruedas, el
/// chasis y el manubrio, igual que en el prototipo.
class MotoIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;

  const MotoIcon({
    super.key,
    this.size = 40,
    required this.color,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MotoPainter(color: color, strokeWidth: strokeWidth),
    );
  }
}

class _MotoPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _MotoPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // El diseño original está pensado sobre un lienzo de 40x40.
    final scale = size.width / 40;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    canvas.drawCircle(p(10, 30), 6 * scale, paint);
    canvas.drawCircle(p(30, 30), 6 * scale, paint);

    final frame = Path()
      ..moveTo(p(10, 30).dx, p(10, 30).dy)
      ..lineTo(p(16, 18).dx, p(16, 18).dy)
      ..lineTo(p(24, 18).dx, p(24, 18).dy)
      ..lineTo(p(30, 30).dx, p(30, 30).dy);
    canvas.drawPath(frame, paint);

    final handlebar = Path()
      ..moveTo(p(16, 18).dx, p(16, 18).dy)
      ..lineTo(p(20, 10).dx, p(20, 10).dy)
      ..lineTo(p(26, 10).dx, p(26, 10).dy);
    canvas.drawPath(handlebar, paint);

    canvas.drawLine(p(20, 10), p(14, 10), paint);
  }

  @override
  bool shouldRepaint(covariant _MotoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
