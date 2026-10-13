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

/// Silueta en alambre de una moto deportiva vista de tres cuartos, con
/// ruedas punteadas y recuadros de "fijación" de la IA — el mismo dibujo
/// guía del visor en `design.md` (lienzo original de 200×120).
class MotoWireframe extends StatelessWidget {
  final double width;
  final Color color;
  final bool showLockBoxes;

  const MotoWireframe({
    super.key,
    this.width = 224,
    this.color = AppColorsWireframe.stroke,
    this.showLockBoxes = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * 120 / 200),
      painter: _WireframePainter(color: color, showLockBoxes: showLockBoxes),
    );
  }
}

/// Colores fijos del dibujo (los recuadros verde y azul de fijación).
class AppColorsWireframe {
  AppColorsWireframe._();
  static const Color stroke = Color(0xFFFFB4AA);
  static const Color lockGreen = Color(0xFF47E266);
  static const Color lockBlue = Color(0xFFAAC7FF);
}

class _WireframePainter extends CustomPainter {
  final Color color;
  final bool showLockBoxes;

  _WireframePainter({required this.color, required this.showLockBoxes});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 120);

    Paint stroke(double width, [double opacity = 1, Color? c]) => Paint()
      ..color = (c ?? color).withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ruedas trasera y delantera.
    for (final cx in [45.0, 160.0]) {
      final wheel = Path()..addOval(Rect.fromCircle(center: Offset(cx, 85), radius: 22));
      _drawDashed(canvas, wheel, stroke(2, 0.8), 4, 2);
      canvas.drawCircle(Offset(cx, 85), 10, stroke(2, 0.4));
    }

    // Chasis y basculante.
    canvas.drawPath(
      Path()
        ..moveTo(45, 85)
        ..lineTo(80, 82)
        ..lineTo(105, 60)
        ..lineTo(140, 60)
        ..lineTo(160, 85),
      stroke(2.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(80, 82)
        ..lineTo(95, 90)
        ..lineTo(115, 88),
      stroke(2, 0.5),
    );

    // Tanque y carenado.
    canvas.drawPath(
      Path()
        ..moveTo(78, 52)
        ..cubicTo(88, 40, 110, 38, 122, 46)
        ..lineTo(135, 34)
        ..lineTo(152, 48)
        ..lineTo(142, 66)
        ..lineTo(118, 70)
        ..lineTo(95, 68)
        ..close(),
      stroke(2),
    );

    // Colín / asiento.
    canvas.drawPath(
      Path()
        ..moveTo(40, 50)
        ..lineTo(75, 52)
        ..lineTo(90, 62)
        ..lineTo(65, 62)
        ..close(),
      stroke(2),
    );

    // Parabrisas y manubrio.
    canvas.drawPath(
      Path()
        ..moveTo(125, 38)
        ..lineTo(138, 24)
        ..lineTo(148, 32),
      stroke(1.8),
    );
    canvas.drawLine(const Offset(132, 30), const Offset(126, 26), stroke(2.5));

    // Escape.
    canvas.drawLine(const Offset(56, 84), const Offset(88, 76), stroke(3, 0.6));

    if (showLockBoxes) {
      _drawDashed(
        canvas,
        Path()..addRRect(RRect.fromLTRBR(136, 24, 164, 48, const Radius.circular(4))),
        stroke(1, 1, AppColorsWireframe.lockGreen),
        3,
        2,
      );
      _drawDashed(
        canvas,
        Path()..addRRect(RRect.fromLTRBR(34, 65, 56, 83, const Radius.circular(2))),
        stroke(1, 1, AppColorsWireframe.lockBlue),
        2,
        2,
      );
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint, double dash, double gap) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WireframePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.showLockBoxes != showLockBoxes;
}
