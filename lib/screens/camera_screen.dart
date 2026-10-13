import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/moto_icon.dart';
import 'analyzing_screen.dart';

/// Pantalla de captura: enciende la cámara trasera dentro de un visor tipo
/// HUD y deja tomar la foto de la moto (o elegir una de la galería) para
/// enviarla al reconocimiento con IA.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  String? _errorMessage;
  bool _capturing = false;
  bool _torchOn = false;
  bool _showGrid = true;

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _scan.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      setState(() {
        _controller = null;
        _torchOn = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() => _errorMessage = null);
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No se encontró ninguna cámara en este dispositivo.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      final denied = e.code == 'CameraAccessDenied' || e.code == 'CameraAccessDeniedWithoutPrompt';
      setState(() {
        _errorMessage = denied
            ? 'MotoGastos necesita permiso de cámara para reconocer tu moto.'
            : 'No se pudo abrir la cámara (${e.description ?? e.code}).';
      });
    } catch (_) {
      setState(() => _errorMessage = 'No se pudo abrir la cámara.');
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final next = !_torchOn;
    try {
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _torchOn = next);
    } on CameraException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta cámara no tiene linterna.')),
      );
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      if (_torchOn) {
        await controller.setFlashMode(FlashMode.off);
        _torchOn = false;
      }
      _goToAnalyzing(File(photo.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo tomar la foto, intenta de nuevo.')),
      );
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      // Se limita el tamaño para que el envío a la IA sea rápido.
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 88,
      );
      if (picked != null) _goToAnalyzing(File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la galería.')),
      );
    }
  }

  void _goToAnalyzing(File image) {
    if (!mounted) return;
    context.read<AppState>().setCapturedImage(image);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.select<AppState, String>((s) => s.recognitionEngineName);
    final ready = _controller?.value.isInitialized ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MgHeader(
              title: 'Escanear Moto',
              leading: RoundGlassButton(
                icon: Icons.arrow_back,
                tooltip: 'Volver',
                size: 40,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  StatusPill(text: 'HUD · $engine', pulsing: ready),
                  const Spacer(),
                  RoundGlassButton(
                    icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                    tooltip: 'Alternar linterna',
                    size: 40,
                    iconColor: _torchOn ? AppColors.primary : AppColors.onSurface,
                    background: AppColors.surfaceContainer.withValues(alpha: 0.8),
                    onTap: ready ? _toggleTorch : null,
                  ),
                  const SizedBox(width: 8),
                  RoundGlassButton(
                    icon: Icons.grain,
                    tooltip: 'Modo retícula HUD',
                    size: 40,
                    iconColor: _showGrid ? AppColors.primary : AppColors.onSurfaceVariant,
                    background: AppColors.surfaceContainer.withValues(alpha: 0.8),
                    onTap: () => setState(() => _showGrid = !_showGrid),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ColoredBox(
                      color: AppColors.surfaceContainerLowest,
                      child: _errorMessage != null
                          ? _CameraError(message: _errorMessage!, onRetry: _initCamera)
                          : _buildViewport(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'Buena luz y la placa visible ayudan a identificar mejor la ',
                        children: [
                          TextSpan(
                            text: 'marca, el modelo y el cilindraje',
                            style: AppText.bodyMd.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                      style: AppText.bodyMd.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  _ShutterButton(
                    capturing: _capturing,
                    onTap: ready ? _capture : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    height: 48,
                    child: Material(
                      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _pickFromGallery,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Elegir foto de la galería',
                              style: AppText.headlineSm.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewport() {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.previewSize?.height ?? 1,
              height: controller.value.previewSize?.width ?? 1,
              child: CameraPreview(controller),
            ),
          )
        else
          const Center(child: CircularProgressIndicator()),
        // Viñeta para dar profundidad y que el HUD se lea sobre la imagen.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
                  Colors.transparent,
                  AppColors.surfaceContainerLowest.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        if (_showGrid)
          IgnorePointer(
            child: CustomPaint(painter: _HudGridPainter()),
          ),
        // Recuadro de encuadre con esquinas rojas, láser y silueta guía.
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.84,
            heightFactor: 0.66,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _CornerGuidePainter()),
                  Center(
                    child: Opacity(
                      opacity: 0.55,
                      child: LayoutBuilder(
                        builder: (context, box) => MotoWireframe(
                          width: (box.maxWidth * 0.8).clamp(120, 240),
                        ),
                      ),
                    ),
                  ),
                  if (ready)
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) => Align(
                        alignment: Alignment(0, Curves.easeInOut.transform(_scan.value) * 2 - 1),
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.9),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppColors.surfaceContainerHigh.withValues(alpha: 0.7),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.view_in_ar, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Encuadra la moto de tres cuartos',
                          style: AppText.labelMd,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HudTag(
                icon: ready ? Icons.check_circle : Icons.sync,
                iconColor: ready ? AppColors.secondary : AppColors.primary,
                text: ready ? 'Cámara lista' : 'Iniciando cámara',
              ),
              _HudTag(
                icon: _torchOn ? Icons.flash_on : Icons.flash_off,
                iconColor: AppColors.primary,
                text: _torchOn ? 'Linterna on' : 'Linterna off',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HudTag extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _HudTag({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: AppText.labelCaps.copyWith(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Obturador estilo "botón de ignición": círculo rojo con degradado dentro
/// de un aro de vidrio que late suavemente.
class _ShutterButton extends StatefulWidget {
  final bool capturing;
  final VoidCallback? onTap;

  const _ShutterButton({required this.capturing, required this.onTap});

  @override
  State<_ShutterButton> createState() => _ShutterButtonState();
}

class _ShutterButtonState extends State<_ShutterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      label: 'Capturar fotografía de la moto',
      excludeSemantics: true,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryContainer
                      .withValues(alpha: 0.1 + 0.15 * _pulse.value),
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceContainerHigh.withValues(alpha: 0.8),
                boxShadow: AppColors.cardShadow,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.primaryContainer, AppColors.inversePrimary],
                  ),
                  boxShadow: AppColors.racingGlow(0.5),
                ),
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: widget.onTap,
                    child: Center(
                      child: widget.capturing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(Icons.photo_camera, size: 32, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CameraError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: AppColors.primary, size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMd.copyWith(height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
                OutlinedButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('Abrir ajustes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Retícula del HUD: cuadrícula azul tenue, anillos de radar y mira
/// central, como en el visor de `design.md`.
class _HudGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.tertiary.withValues(alpha: 0.07)
      ..strokeWidth = 0.8;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      140,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primaryContainer.withValues(alpha: 0.12),
            AppColors.primaryContainer.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: 140)),
    );

    final redRing = Paint()
      ..color = AppColors.primaryContainer.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke;
    const dash = 6.0, gap = 4.0;
    final ring = Path()..addOval(Rect.fromCircle(center: center, radius: 110));
    for (final metric in ring.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), redRing);
      }
    }
    canvas.drawCircle(
      center,
      70,
      Paint()
        ..color = AppColors.tertiary.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _HudGridPainter oldDelegate) => false;
}

/// Cuatro esquinas rojas con brillo que marcan el área donde debe quedar
/// la moto, sin tapar el centro del encuadre.
class _CornerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const len = 24.0;
    final w = size.width, h = size.height;
    final corners = Path()
      ..moveTo(0, len)
      ..lineTo(0, 0)
      ..lineTo(len, 0)
      ..moveTo(w - len, 0)
      ..lineTo(w, 0)
      ..lineTo(w, len)
      ..moveTo(0, h - len)
      ..lineTo(0, h)
      ..lineTo(len, h)
      ..moveTo(w - len, h)
      ..lineTo(w, h)
      ..lineTo(w, h - len);

    canvas.drawPath(
      corners,
      Paint()
        ..color = AppColors.primaryContainer.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      corners,
      Paint()
        ..color = AppColors.primaryContainer
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) => false;
}
