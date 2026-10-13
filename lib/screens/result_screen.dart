import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/motorcycle.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_card.dart';
import 'expenses_screen.dart';

/// Ficha técnica: muestra cada dato que la IA identificó (o lo último que
/// el usuario corrigió) en su tarjeta, y deja pasar a la pantalla de gastos.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final moto = appState.motorcycle;
        final image = appState.capturedImage;

        if (moto == null) {
          // No debería pasar en un flujo normal, pero se cubre por si acaso.
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  MgHeader(
                    title: 'Ficha Técnica',
                    leading: RoundGlassButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Volver',
                      size: 40,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: Text('No hay una moto reconocida todavía.')),
                  ),
                ],
              ),
            ),
          );
        }

        final subtitle = [
          moto.category,
          if (moto.usage != null) moto.usage!,
          if (moto.engineType != null) moto.engineType!,
        ].join(' · ');

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const MgHeader(title: 'Ficha Técnica De Moto'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            RoundGlassButton(
                              icon: Icons.arrow_back_ios_new,
                              tooltip: 'Repetir foto',
                              background: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  const CapsLabel('Diagnóstico IA', color: AppColors.primary),
                                  Text('Ficha Técnica', style: AppText.headlineSm),
                                ],
                              ),
                            ),
                            RoundGlassButton(
                              icon: Icons.tune,
                              tooltip: 'Corregir datos',
                              iconColor: AppColors.onSurfaceVariant,
                              background: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                              onTap: () => _showEditSheet(context, moto),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
                          border: Border.all(
                            color: AppColors.surfaceContainerHighest.withValues(alpha: 0.6),
                          ),
                          shadow: const [
                            BoxShadow(color: Color(0x73000000), blurRadius: 28, offset: Offset(0, 12)),
                          ],
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _ConfidencePill(percent: moto.confidencePercent),
                                  const Spacer(),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainer.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        [
                                          if (moto.model.isNotEmpty) moto.model,
                                          if (moto.estimatedYear != null) '${moto.estimatedYear}',
                                        ].join(' · '),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.labelCaps,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  height: 176,
                                  width: double.infinity,
                                  child: image != null
                                      ? Image.file(image, fit: BoxFit.cover)
                                      : const ColoredBox(
                                          color: AppColors.surfaceContainer,
                                          child: Icon(Icons.two_wheeler, size: 56, color: AppColors.outline),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                moto.displayName,
                                textAlign: TextAlign.center,
                                style: AppText.headlineLg,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                style: AppText.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.45,
                          children: [
                            StatCard(
                              icon: Icons.speed,
                              iconColor: AppColors.primary,
                              label: 'Cilindraje',
                              value: '${moto.engineCc}',
                              unit: 'cc',
                            ),
                            StatCard(
                              icon: Icons.calendar_today_outlined,
                              iconColor: AppColors.tertiary,
                              label: 'Año modelo',
                              value: moto.estimatedYear?.toString() ?? '—',
                            ),
                            StatCard(
                              icon: Icons.verified_user_outlined,
                              iconColor: AppColors.secondary,
                              label: 'Tarifa SOAT',
                              value: _soatRange(moto.engineCc),
                              unit: 'cc',
                              compact: true,
                            ),
                            StatCard(
                              icon: Icons.scale_outlined,
                              iconColor: AppColors.onSurfaceVariant,
                              label: 'Peso en seco',
                              value: moto.estimatedWeightKg?.toString() ?? '—',
                              unit: moto.estimatedWeightKg != null ? 'KG' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _ConsumptionBar(kmL: moto.fuelEfficiencyKmL),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 16, color: AppColors.outline),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Identificado por ${appState.recognitionEngineName} a partir de la foto.',
                                style: AppText.bodySm.copyWith(color: AppColors.outline),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showEditSheet(context, moto),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              label: const Text('Corregir'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: PrimaryButton(
                    label: 'Ver gastos anuales estimados',
                    trailingIcon: Icons.arrow_forward,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Rango de cilindraje de la tarifa SOAT 2026 que aplica a la moto.
  String _soatRange(int cc) {
    if (cc <= 50) return '≤ 50';
    if (cc <= 100) return '51–100';
    if (cc <= 200) return '101–200';
    return '> 200';
  }

  void _showEditSheet(BuildContext context, Motorcycle moto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _EditMotoSheet(motorcycle: moto),
    );
  }
}

class _ConfidencePill extends StatelessWidget {
  final int percent;
  const _ConfidencePill({required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent >= 70
        ? AppColors.secondary
        : percent >= 40
            ? AppColors.tertiary
            : AppColors.primaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color, blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 6),
          Text('$percent% certeza'.toUpperCase(), style: AppText.labelCaps.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ConsumptionBar extends StatelessWidget {
  final double? kmL;
  const _ConsumptionBar({required this.kmL});

  @override
  Widget build(BuildContext context) {
    final value = kmL;
    final (rating, color) = switch (value) {
      null => ('Sin dato', AppColors.outline),
      >= 40 => ('Eficiente', AppColors.secondary),
      >= 25 => ('Moderado', AppColors.tertiary),
      _ => ('Alto consumo', AppColors.primaryContainer),
    };
    return GlassCard(
      padding: const EdgeInsets.all(8),
      color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
      shadow: null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_gas_station_outlined, size: 18, color: AppColors.primaryContainer),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consumo promedio', style: AppText.bodySm.copyWith(color: AppColors.onSurface)),
                CapsLabel(
                  value == null
                      ? 'Se usará el valor de referencia'
                      : 'Ciclo urbano: ${_formatKmL(value)} km/l',
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              rating.toUpperCase(),
              style: AppText.labelCaps.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatKmL(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1).replaceAll('.', ',');

class _EditMotoSheet extends StatefulWidget {
  final Motorcycle motorcycle;
  const _EditMotoSheet({required this.motorcycle});

  @override
  State<_EditMotoSheet> createState() => _EditMotoSheetState();
}

class _EditMotoSheetState extends State<_EditMotoSheet> {
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _category;
  late final TextEditingController _cc;
  late final TextEditingController _year;
  late final TextEditingController _weight;
  late final TextEditingController _kmL;
  late final TextEditingController _engineType;
  late final TextEditingController _usage;

  @override
  void initState() {
    super.initState();
    final m = widget.motorcycle;
    _brand = TextEditingController(text: m.brand);
    _model = TextEditingController(text: m.model);
    _category = TextEditingController(text: m.category);
    _cc = TextEditingController(text: m.engineCc.toString());
    _year = TextEditingController(text: m.estimatedYear?.toString() ?? '');
    _weight = TextEditingController(text: m.estimatedWeightKg?.toString() ?? '');
    _kmL = TextEditingController(
      text: m.fuelEfficiencyKmL == null ? '' : _formatKmL(m.fuelEfficiencyKmL!),
    );
    _engineType = TextEditingController(text: m.engineType ?? '');
    _usage = TextEditingController(text: m.usage ?? '');
  }

  @override
  void dispose() {
    for (final c in [_brand, _model, _category, _cc, _year, _weight, _kmL, _engineType, _usage]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final m = widget.motorcycle;
    // Se construye de cero (no con copyWith) para que vaciar un campo
    // opcional lo borre de verdad en vez de conservar el valor anterior.
    final updated = Motorcycle(
      brand: text(_brand) ?? m.brand,
      model: _model.text.trim(),
      category: text(_category) ?? m.category,
      engineCc: int.tryParse(_cc.text) ?? m.engineCc,
      estimatedYear: int.tryParse(_year.text),
      estimatedWeightKg: int.tryParse(_weight.text),
      fuelEfficiencyKmL: double.tryParse(_kmL.text.replaceAll(',', '.')),
      engineType: text(_engineType),
      usage: text(_usage),
      confidence: m.confidence,
    );
    context.read<AppState>().updateMotorcycle(updated);
    Navigator.of(context).pop();
  }

  Widget _field(TextEditingController c, String label, {bool number = false, bool decimal = false}) {
    return TextField(
      controller: c,
      style: AppText.bodyMd,
      keyboardType: number || decimal
          ? TextInputType.numberWithOptions(decimal: decimal)
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.digitsOnly]
          : decimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
              : null,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: 12);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CapsLabel('Diagnóstico IA', color: AppColors.primary),
            Text('Corregir datos', style: AppText.headlineMd),
            const SizedBox(height: 4),
            Text('Ajusta lo que la IA no haya identificado bien.', style: AppText.bodySm),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _field(_brand, 'Marca')),
              gap,
              Expanded(child: _field(_model, 'Línea / modelo')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_category, 'Categoría')),
              gap,
              Expanded(child: _field(_usage, 'Uso')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_cc, 'Cilindraje (cc)', number: true)),
              gap,
              Expanded(child: _field(_year, 'Año modelo', number: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_weight, 'Peso (kg)', number: true)),
              gap,
              Expanded(child: _field(_kmL, 'Consumo (km/l)', decimal: true)),
            ]),
            const SizedBox(height: 12),
            _field(_engineType, 'Tipo de motor'),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Guardar', icon: Icons.check, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
