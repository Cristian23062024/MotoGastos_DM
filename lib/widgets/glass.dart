import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'moto_icon.dart';

/// Tarjeta translúcida ("vidrio esmerilado") sobre el fondo oscuro, la
/// pieza base de todas las pantallas de `design.md`. [blur] solo vale la
/// pena cuando hay contenido detrás (p. ej. sobre el visor de la cámara).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  final List<BoxShadow>? shadow;
  final BoxBorder? border;
  final bool blur;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = const Color(0xBF1A202C), // surface-container / 75 %
    this.radius = 12,
    this.shadow = AppColors.cardShadow,
    this.border,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: blur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: content,
              )
            : content,
      ),
    );
  }
}

/// Encabezado común: isotipo, "MOTOGASTOS" en rojo y el título de la
/// pantalla. Opcionalmente un botón a la izquierda (volver) y acciones a
/// la derecha.
class MgHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const MgHeader({super.key, required this.title, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          const _Logo(),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOTOGASTOS',
                  style: AppText.labelCaps.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 1.65,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: AppText.headlineSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: AppColors.racingGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.racingGlow(0.35),
      ),
      child: const Center(
        child: MotoIcon(size: 22, color: Colors.white, strokeWidth: 2.2),
      ),
    );
  }
}

/// Botón circular translúcido (volver, linterna, ajustes…).
class RoundGlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final double size;
  final Color iconColor;
  final Color background;

  const RoundGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.size = 44,
    this.iconColor = AppColors.onSurface,
    this.background = const Color(0xCC242A37), // surface-container-high / 80 %
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        shadowColor: Colors.black,
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

/// Píldora de estado con un punto de color, p. ej. "● GEMINI VISION".
class StatusPill extends StatefulWidget {
  final String text;
  final Color dotColor;
  final bool pulsing;
  final Color background;

  const StatusPill({
    super.key,
    required this.text,
    this.dotColor = AppColors.secondary,
    this.pulsing = false,
    this.background = const Color(0xCC1A202C),
  });

  @override
  State<StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _pulse.repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: widget.dotColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: widget.dotColor.withValues(alpha: 0.8), blurRadius: 8),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (widget.pulsing)
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => Transform.scale(
                      scale: 1 + _pulse.value,
                      child: Opacity(
                        opacity: 1 - _pulse.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                dot,
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            widget.text.toUpperCase(),
            style: AppText.labelCaps.copyWith(
              color: AppColors.onSurface,
              letterSpacing: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadro de 40×40 con un ícono de color, a la izquierda de cada tarjeta.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: size / 2, color: color),
    );
  }
}

/// Texto en mayúsculas espaciadas de las etiquetas de telemetría.
class CapsLabel extends StatelessWidget {
  final String text;
  final Color color;

  const CapsLabel(this.text, {super.key, this.color = AppColors.outline});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.labelCaps.copyWith(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
