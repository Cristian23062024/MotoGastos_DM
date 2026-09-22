import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'analyzing_screen.dart';

/// Pantalla de captura: enciende la cámara trasera y deja tomar la foto de
/// la moto (o elegir una de la galería como alternativa).
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  String? _errorMessage;
  bool _capturing = false;

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
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

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
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
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (picked != null) _goToAnalyzing(File(picked.path));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la galería.')),
      );
    }
  }

  void _goToAnalyzing(File image) {
    context.read<AppState>().setCapturedImage(image);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalyzingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.viewfinder,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Escanear moto',
                    style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: const Color(0xFF17181C),
                    child: _errorMessage != null
                        ? _CameraError(message: _errorMessage!, onRetry: _initCamera)
                        : _controller == null
                            ? const Center(
                                child: CircularProgressIndicator(color: AppColors.accent),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!.value.previewSize?.height ?? 1,
                                      height: _controller!.value.previewSize?.width ?? 1,
                                      child: CameraPreview(_controller!),
                                    ),
                                  ),
                                  Positioned(
                                    left: 24,
                                    right: 24,
                                    top: 40,
                                    bottom: 96,
                                    child: CustomPaint(painter: _CornerGuidePainter()),
                                  ),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 20,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.55),
                                          borderRadius: BorderRadius.circular(100),
                                        ),
                                        child: const Text(
                                          'Encuadra la moto de tres cuartos',
                                          style: TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
              child: Text(
                'Buena luz y la placa visible ayudan a identificar mejor la marca, '
                'el modelo y el cilindraje.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.white.withOpacity(0.7)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 36),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _capture,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        border: Border.all(color: Colors.white.withOpacity(0.9), width: 4),
                      ),
                      child: Center(
                        child: _capturing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                              )
                            : const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _pickFromGallery,
                    child: Text(
                      'Elegir foto de la galería',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13.5),
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
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Volver',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
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
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white54, size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.5),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  child: const Text('Reintentar'),
                ),
                OutlinedButton(
                  onPressed: () => openAppSettings(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
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

/// Dibuja las cuatro esquinas guía sobre el visor, igual que en el
/// prototipo, sin tapar el centro del encuadre.
class _CornerGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const len = 18.0;

    // Esquina superior izquierda
    canvas.drawLine(const Offset(0, len), Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);

    // Esquina superior derecha
    canvas.drawLine(Offset(size.width - len, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(0, size.height - len), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(size.width - len, size.height),
      Offset(size.width, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height - len),
      Offset(size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerGuidePainter oldDelegate) => false;
}
