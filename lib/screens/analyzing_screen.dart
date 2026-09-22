import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
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
            if (appState.status == RecognitionStatus.success) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ResultScreen()),
                );
              });
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Analizando tu moto',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: appState.status == RecognitionStatus.error
                        ? _ErrorState(
                            message: appState.errorMessage ?? 'Ocurrió un error.',
                            onRetry: () => context.read<AppState>().analyze(),
                            onRetake: () => Navigator.of(context).pop(),
                          )
                        : _LoadingState(imageFile: appState.capturedImage, usingDemo: appState.usingDemoRecognition),
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

class _LoadingState extends StatelessWidget {
  final File? imageFile;
  final bool usingDemo;
  const _LoadingState({required this.imageFile, required this.usingDemo});

  @override
  Widget build(BuildContext context) {
    final file = imageFile;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEAE0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (file != null) Image.file(file, fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.15)),
              const Center(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    color: AppColors.accent,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Analizando tu moto con IA…',
          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        const Text(
          'Esto toma solo unos segundos.',
          style: TextStyle(fontSize: 13, color: AppColors.ink2),
        ),
        if (usingDemo) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'Modo demostración: configura tu API key para reconocimiento real',
              style: TextStyle(fontSize: 11.5, color: AppColors.ink),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: AppColors.accent, size: 40),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14.5, height: 1.5, color: AppColors.ink),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
              child: const Text('Reintentar'),
            ),
            OutlinedButton(
              onPressed: onRetake,
              style: OutlinedButton.styleFrom(minimumSize: const Size(140, 48)),
              child: const Text('Tomar otra foto'),
            ),
          ],
        ),
      ],
    );
  }
}
