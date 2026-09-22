import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/moto_icon.dart';
import '../widgets/primary_button.dart';
import 'camera_screen.dart';

/// Primera pantalla: presenta la app y lleva a la cámara.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Center(
                        child: MotoIcon(size: 44, color: AppColors.accent),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('MotoGastos', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    const Text(
                      'Apunta la cámara a tu moto y conoce en segundos cuánto te '
                      'cuesta mantenerla al año en Colombia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: AppColors.ink2, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    const _Feature(
                      icon: Icons.camera_alt_outlined,
                      text: 'Reconocimiento por cámara con IA: identifica marca, '
                          'línea y cilindraje.',
                    ),
                    const SizedBox(height: 16),
                    const _Feature(
                      icon: Icons.receipt_long_outlined,
                      text: 'SOAT, tecnomecánica, impuesto, gasolina y '
                          'mantenimiento, en un solo estimado.',
                    ),
                    const SizedBox(height: 16),
                    const _Feature(
                      icon: Icons.edit_outlined,
                      text: 'Tarifas 2026 de referencia que puedes ajustar a tu caso.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        label: 'Escanear mi moto',
                        icon: Icons.camera_alt_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CameraScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Estimado de referencia, no reemplaza una cotización oficial.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, height: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
