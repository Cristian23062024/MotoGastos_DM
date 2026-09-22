import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/colombia_rates_2026.dart';
import '../models/motorcycle.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/stat_card.dart';
import 'expenses_screen.dart';

/// Muestra lo que la IA identificó (o lo último que el usuario corrigió) y
/// deja pasar a la pantalla de gastos.
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
            appBar: AppBar(
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            ),
            body: const Center(child: Text('No hay una moto reconocida todavía.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Repetir foto',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Resultado'),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 190,
                            width: double.infinity,
                            color: const Color(0xFFEDEAE0),
                            child: image != null
                                ? Image.file(image, fit: BoxFit.cover)
                                : const Center(
                                    child: Icon(Icons.two_wheeler, size: 56, color: Colors.black26),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.tealSoft,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 14, color: AppColors.teal),
                              const SizedBox(width: 6),
                              Text(
                                '${moto.confidencePercent}% de confianza',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(moto.displayName, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          moto.category,
                          style: const TextStyle(fontSize: 14.5, color: AppColors.ink2),
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.6,
                          children: [
                            StatCard(label: 'Cilindraje', value: '${moto.engineCc} cc'),
                            StatCard(
                              label: 'Año aprox.',
                              value: moto.estimatedYear?.toString() ?? '—',
                            ),
                            StatCard(
                              label: 'Categoría SOAT',
                              value: _soatCategoryLabel(moto.engineCc),
                            ),
                            StatCard(
                              label: 'Peso aprox.',
                              value: moto.estimatedWeightKg != null
                                  ? '${moto.estimatedWeightKg} kg'
                                  : '—',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Identificado por IA a partir de la foto.',
                                style: TextStyle(fontSize: 13, color: AppColors.ink2),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Ver gastos anuales estimados',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ExpensesScreen()),
                      ),
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

  String _soatCategoryLabel(int cc) {
    for (final bracket in soatBrackets2026) {
      if (bracket.maxCc == null || cc <= bracket.maxCc!) return bracket.label;
    }
    return soatBrackets2026.last.label;
  }

  void _showEditSheet(BuildContext context, Motorcycle moto) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _EditMotoSheet(motorcycle: moto),
    );
  }
}

class _EditMotoSheet extends StatefulWidget {
  final Motorcycle motorcycle;
  const _EditMotoSheet({required this.motorcycle});

  @override
  State<_EditMotoSheet> createState() => _EditMotoSheetState();
}

class _EditMotoSheetState extends State<_EditMotoSheet> {
  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _cc;
  late final TextEditingController _year;

  @override
  void initState() {
    super.initState();
    final m = widget.motorcycle;
    _brand = TextEditingController(text: m.brand);
    _model = TextEditingController(text: m.model);
    _cc = TextEditingController(text: m.engineCc.toString());
    _year = TextEditingController(text: m.estimatedYear?.toString() ?? '');
  }

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _cc.dispose();
    _year.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.motorcycle.copyWith(
      brand: _brand.text.trim().isEmpty ? widget.motorcycle.brand : _brand.text.trim(),
      model: _model.text.trim(),
      engineCc: int.tryParse(_cc.text) ?? widget.motorcycle.engineCc,
      estimatedYear: int.tryParse(_year.text),
    );
    context.read<AppState>().updateMotorcycle(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Corregir datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text(
            'Ajusta lo que la IA no haya identificado bien.',
            style: TextStyle(fontSize: 13, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Marca'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _model,
            decoration: const InputDecoration(labelText: 'Línea / modelo'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cc,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Cilindraje (cc)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Año aprox.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Guardar', onPressed: _save),
          ),
        ],
      ),
    );
  }
}
