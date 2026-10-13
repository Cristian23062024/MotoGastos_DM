import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense_inputs.dart';
import '../models/motorcycle.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/glass.dart';
import '../widgets/moto_icon.dart';
import '../widgets/primary_button.dart';
import 'camera_screen.dart';

/// Moto de referencia para el resumen de "costo promedio anual" de la
/// pantalla de inicio: una 150 cc urbana, la más común en Colombia.
const Motorcycle _referencia = Motorcycle(
  brand: 'Referencia',
  model: '150 cc',
  category: 'Urbana',
  engineCc: 150,
  confidence: 1,
);

/// Primera pantalla ("Inicio"): presenta la app y lleva a la cámara.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _openCamera(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final referenciaAnual = ExpenseInputs.sugeridoPara(_referencia).total;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const MgHeader(title: 'Inicio'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CapsLabel(
                                appState.usingDemoRecognition
                                    ? 'Estado: modo demostración'
                                    : 'Estado: IA lista',
                                color: AppColors.secondary,
                              ),
                              const SizedBox(height: 2),
                              Text('¡Hola, Rider!', style: AppText.displayHero),
                            ],
                          ),
                        ),
                        StatusPill(
                          text: appState.recognitionEngineName,
                          dotColor: appState.usingDemoRecognition
                              ? AppColors.primaryContainer
                              : AppColors.secondary,
                          background: AppColors.surfaceContainerHigh
                              .withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _HeroCard(onScan: () => _openCamera(context)),
                    const SizedBox(height: 20),
                    const _FeatureCard(
                      icon: Icons.photo_camera_outlined,
                      iconColor: AppColors.primary,
                      title: 'Reconocimiento con IA',
                      text: 'Gemini identifica marca, línea, cilindraje, año y '
                          'consumo desde una foto.',
                    ),
                    const SizedBox(height: 12),
                    const _FeatureCard(
                      icon: Icons.analytics_outlined,
                      iconColor: AppColors.tertiary,
                      title: 'Estimación y Trámites',
                      text: 'SOAT, tecno e impuestos con tarifas 2026 para '
                          'Colombia.',
                    ),
                    const SizedBox(height: 12),
                    const _FeatureCard(
                      icon: Icons.tune,
                      iconColor: AppColors.secondary,
                      title: 'Ajustable a tu caso',
                      text: 'Corrige los datos o edita cualquier valor y el '
                          'total se recalcula al instante.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.surfaceContainerLow,
                            AppColors.surfaceContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CapsLabel(
                                  'Costo promedio anual · moto 150 cc',
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${formatCop(referenciaAnual)} COP',
                                  style: AppText.headlineSm
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_down,
                              size: 20,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Escanear mi moto',
                      icon: Icons.photo_camera,
                      trailingIcon: Icons.arrow_forward,
                      onPressed: () => _openCamera(context),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estimado de referencia, no reemplaza una cotización oficial.',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(color: AppColors.outline),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onScan;
  const _HeroCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      color: AppColors.surfaceContainer.withValues(alpha: 0.7),
      shadow: const [
        BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 16)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu moto, en cifras', style: AppText.headlineMd),
                    const SizedBox(height: 2),
                    Text('Marca · cilindraje · año', style: AppText.bodySm),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'Tarifas 2026',
                  style: AppText.labelCaps.copyWith(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          Semantics(
            button: true,
            label: 'Escanear mi moto',
            child: InkWell(
              onTap: onScan,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 176,
                margin: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryContainer.withValues(alpha: 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const MotoWireframe(width: 240),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Gastos',
                    value: '5',
                    unit: 'rubros',
                    valueColor: AppColors.secondary,
                  ),
                ),
                Expanded(
                  child: _HeroMetric(label: 'Análisis', value: '~5', unit: 'seg'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color valueColor;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor = AppColors.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CapsLabel(label, color: AppColors.onSurfaceVariant),
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            text: value,
            style: AppText.telemetry.copyWith(color: valueColor),
            children: [
              TextSpan(text: ' $unit', style: AppText.bodySm),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 16,
      color: AppColors.surfaceContainer.withValues(alpha: 0.6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.headlineSm),
                const SizedBox(height: 2),
                Text(text, style: AppText.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
