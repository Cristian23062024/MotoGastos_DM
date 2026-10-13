import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/primary_button.dart';
import 'result_screen.dart';

/// Pantalla de espera mientras la foto capturada se envía al servicio de
/// reconocimiento. Dispara el análisis una sola vez al entrar y navega
/// automáticamente al resultado en cuanto `AppState` reporta éxito.
class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.status != RecognitionStatus.analyzing) {
        appState.analyze();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            if (appState.status == RecognitionStatus.success && !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ResultScreen()),
                );
              });
            }

            return Column(
              children: [
                MgHeader(
                  title: 'Analizando Moto',
                  leading: RoundGlassButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Tomar otra foto',
                    size: 40,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: appState.status == RecognitionStatus.error
                      ? _ErrorState(
                          message: appState.errorMessage ?? 'Ocurrió un error.',
                          onRetry: () => context.read<AppState>().analyze(),
                          onRetake: () => Navigator.of(context).pop(),
                        )
                      : _LoadingState(
                          imageFile: appState.capturedImage,
                          engine: appState.recognitionEngineName,
                          usingDemo: appState.usingDemoRecognition,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatefulWidget {
  final File? imageFile;
  final String engine;
  final bool usingDemo;

  const _LoadingState({
    required this.imageFile,
    required this.engine,
    required this.usingDemo,
  });

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  /// El paso "enviando" se marca como listo tras un instante: la petición
  /// ya salió y lo que queda es esperar la respuesta del modelo.
  bool _sent = false;
  Timer? _sentTimer;

  @override
  void initState() {
    super.initState();
    _sentTimer = Timer(
      const Duration(milliseconds: 1400),
      () => setState(() => _sent = true),
    );
  }

  @override
  void dispose() {
    _sentTimer?.cancel();
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.imageFile;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        children: [
          StatusPill(
            text: 'Escaneo inteligente · Paso 3 de 3',
            dotColor: AppColors.primaryContainer,
            pulsing: true,
            background: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text('Analizando tu moto', style: AppText.headlineLg),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              'Nuestra IA está identificando las características clave del vehículo',
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surfaceContainerLow.withValues(alpha: 0.8),
                      boxShadow: const [
                        BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12)),
                      ],
                    ),
                  ),
                  Positioned.fill(child: CustomPaint(painter: _RadarRingsPainter())),
                  Positioned.fill(
                    child: RotationTransition(
                      turns: _sweep,
                      child: CustomPaint(painter: _RadarSweepPainter()),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, _) => FractionallySizedBox(
                      widthFactor: 0.55 + 0.25 * _pulse.value,
                      heightFactor: 0.55 + 0.25 * _pulse.value,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryContainer
                              .withValues(alpha: 0.12 * (1 - _pulse.value)),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerHighest,
                          border: Border.all(
                            color: AppColors.primaryContainer.withValues(alpha: 0.7),
                            width: 2,
                          ),
                          boxShadow: AppColors.racingGlow(0.35),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: file != null
                            ? Image.file(file, fit: BoxFit.cover)
                            : const Icon(Icons.two_wheeler, size: 56, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      const StatusPill(
                        text: 'Objetivo fijado',
                        dotColor: AppColors.secondaryContainer,
                        background: Color(0xCC2F3542),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: _Readout(label: 'Motor IA', value: widget.engine),
                  ),
                  const Positioned(
                    bottom: 12,
                    right: 12,
                    child: _Readout(
                      label: 'AI Vision',
                      value: 'SCANNING',
                      valueColor: AppColors.primary,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _StepCard(
            state: _StepState.done,
            title: 'Foto capturada',
            subtitle: 'Encuadre y resolución válidos',
          ),
          const SizedBox(height: 8),
          _StepCard(
            state: _sent ? _StepState.done : _StepState.active,
            title: 'Enviando a ${widget.engine}',
            subtitle: 'Conexión cifrada',
          ),
          const SizedBox(height: 8),
          _StepCard(
            state: _sent ? _StepState.active : _StepState.pending,
            title: 'Estimando marca, cilindraje y año...',
            subtitle: 'Comparando con modelos que circulan en Colombia',
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('Esto toma solo unos segundos.', style: AppText.bodySm),
            ],
          ),
          if (widget.usingDemo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'Modo demostración: configura GEMINI_API_KEY para reconocimiento real',
                textAlign: TextAlign.center,
                style: AppText.bodySm.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  const _Readout({
    required this.label,
    required this.value,
    this.valueColor = AppColors.onSurface,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.labelCaps),
          Text(value, style: AppText.headlineSm.copyWith(color: valueColor, fontSize: 15)),
        ],
      ),
    );
  }
}

enum _StepState { done, active, pending }

class _StepCard extends StatelessWidget {
  final _StepState state;
  final String title;
  final String subtitle;

  const _StepCard({required this.state, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final active = state == _StepState.active;
    final Widget leading = switch (state) {
      _StepState.done => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.secondaryContainer.withValues(alpha: 0.2),
          ),
          child: const Icon(Icons.check_circle, size: 22, color: AppColors.secondary),
        ),
      _StepState.active => const SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceContainerHighest,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Icon(Icons.search, size: 16, color: AppColors.primary),
            ],
          ),
        ),
      _StepState.pending => Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceContainerHighest,
          ),
          child: const Icon(Icons.more_horiz, size: 20, color: AppColors.outline),
        ),
    };

    return GlassCard(
      color: active
          ? AppColors.surfaceContainerHigh.withValues(alpha: 0.9)
          : AppColors.surfaceContainer.withValues(alpha: 0.7),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySm.copyWith(
                    color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (state == _StepState.done)
            const CapsLabel('Listo', color: AppColors.secondary)
          else if (active)
            const _BouncingDots(),
        ],
      ),
    );
  }
}

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * math.sin(((_c.value - i * 0.2) % 1) * math.pi).abs()),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onRetake;

  const _ErrorState({required this.message, required this.onRetry, required this.onRetake});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          radius: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.error_outline, color: AppColors.primaryContainer, size: 34),
              ),
              const SizedBox(height: 16),
              Text('No pudimos analizar la foto', style: AppText.headlineSm, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Reintentar', icon: Icons.refresh, onPressed: onRetry),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Tomar otra foto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anillos concéntricos, ejes de mira y marcas de grados del radar.
class _RadarRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width / 320; // el diseño usa un lienzo de 320×320
    Paint ring(double width, double opacity) => Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.25 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    canvas.drawCircle(c, 145 * s, ring(1, 0.4));
    canvas.drawCircle(c, 110 * s, ring(1.5, 0.6));
    canvas.drawCircle(c, 75 * s, ring(1, 0.5));
    canvas.drawCircle(c, 40 * s, ring(1.5, 0.4));

    final axis = ring(1, 0.3);
    canvas.drawLine(Offset(c.dx, 12 * s), Offset(c.dx, 308 * s), axis);
    canvas.drawLine(Offset(12 * s, c.dy), Offset(308 * s, c.dy), axis);

    // Marcas cada 10 grados en el borde.
    final tick = ring(2, 0.7);
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + dir * 148 * s, c + dir * 154 * s, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarRingsPainter oldDelegate) => false;
}

/// Haz de barrido del radar: una cuña con degradado rojo y la línea
/// brillante que la encabeza. Se rota con un `RotationTransition`.
class _RadarSweepPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 3,
      math.pi / 3,
      true,
      Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 3,
          endAngle: 0,
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0),
            AppColors.primaryContainer.withValues(alpha: 0.4),
          ],
        ).createShader(rect),
    );
    canvas.drawLine(
      c,
      c + Offset(r, 0),
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) => false;
}
