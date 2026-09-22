import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/colombia_rates_2026.dart';
import '../models/expense_inputs.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/expense_row.dart';
import '../widgets/mini_number_field.dart';
import 'welcome_screen.dart';

/// La pantalla principal de resultado: desglose de gastos anuales, editable
/// en el momento, con el total recalculándose en vivo.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _editing = false;

  void _update(AppState appState, ExpenseInputs Function(ExpenseInputs) updater) {
    final current = appState.expenses;
    if (current == null) return;
    appState.updateExpenses(updater(current));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final moto = appState.motorcycle;
        final expenses = appState.expenses;

        if (moto == null || expenses == null) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
            ),
            body: const Center(child: Text('Todavía no hay una moto ni gastos calculados.')),
          );
        }

        final impuestoSubtitle = moto.engineCc <= ColombiaRates2026.impuestoExentoHastaCc
            ? 'Exento (motos de ${ColombiaRates2026.impuestoExentoHastaCc} cc o menos)'
            : 'Avalúo × 1,5% (motos > ${ColombiaRates2026.impuestoExentoHastaCc} cc)';

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 68,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Volver al resultado',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gastos anuales', style: TextStyle(fontSize: 17)),
                Text(
                  '${moto.displayName} · ${moto.engineCc} cc · Tarifas 2026',
                  style: const TextStyle(fontSize: 12, color: AppColors.ink2, fontWeight: FontWeight.normal),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(_editing ? Icons.check : Icons.edit_outlined, size: 15),
                    label: Text(_editing ? 'Listo' : 'Editar valores'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: const BorderSide(color: AppColors.line),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: Column(
                      children: [
                        ExpenseRow(
                          icon: const Icon(Icons.shield_outlined, size: 19, color: AppColors.accent),
                          label: 'SOAT',
                          subtitle: 'Seguro obligatorio · ${_soatLabelShort(moto.engineCc)}',
                          value: expenses.soat,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(soat: v)),
                        ),
                        ExpenseRow(
                          icon: const Icon(Icons.speed_outlined, size: 19, color: AppColors.accent),
                          label: 'Tecnomecánica',
                          subtitle: 'Revisión técnico-mecánica anual',
                          value: expenses.tecnomecanica,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(tecnomecanica: v)),
                        ),
                        ExpenseRow(
                          icon: const Icon(Icons.percent, size: 18, color: AppColors.accent),
                          label: 'Impuesto vehicular',
                          subtitle: impuestoSubtitle,
                          value: expenses.impuesto,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(impuesto: v)),
                        ),
                        _GasolinaBlock(
                          expenses: expenses,
                          editing: _editing,
                          onKm: (v) => _update(appState, (e) => e.copyWith(kmAnual: v)),
                          onRendimiento: (v) => _update(appState, (e) => e.copyWith(rendimientoKmPorGalon: v)),
                          onPrecio: (v) => _update(appState, (e) => e.copyWith(precioGalon: v)),
                        ),
                        ExpenseRow(
                          icon: const Icon(Icons.build_outlined, size: 18, color: AppColors.accent),
                          label: 'Mantenimiento',
                          subtitle: 'Aceite, frenos, llantas, ajustes',
                          value: expenses.mantenimiento,
                          editing: _editing,
                          showDivider: false,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(mantenimiento: v)),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Estimado con tarifas 2026 investigadas (SOAT, tecnomecánica e '
                          'impuesto vehicular nacional; gasolina promedio según ciudad). '
                          'Ajusta cualquier valor con "Editar valores" para afinarlo a tu '
                          'caso — no reemplaza una cotización oficial.',
                          style: TextStyle(fontSize: 12, color: AppColors.ink2, height: 1.55),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            appState.reset();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Escanear otra moto'),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.line)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total estimado al año',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatCop(expenses.total),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '≈ mensual',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.65)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatCop(expenses.mensual),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentOnDark,
                              ),
                            ),
                          ],
                        ),
                      ],
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

  String _soatLabelShort(int cc) {
    for (final bracket in soatBrackets2026) {
      if (bracket.maxCc == null || cc <= bracket.maxCc!) return bracket.label;
    }
    return soatBrackets2026.last.label;
  }
}

class _GasolinaBlock extends StatelessWidget {
  final ExpenseInputs expenses;
  final bool editing;
  final ValueChanged<int> onKm;
  final ValueChanged<int> onRendimiento;
  final ValueChanged<int> onPrecio;

  const _GasolinaBlock({
    required this.expenses,
    required this.editing,
    required this.onKm,
    required this.onRendimiento,
    required this.onPrecio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.local_gas_station_outlined, size: 19, color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gasolina',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      editing
                          ? 'Según kilometraje y rendimiento'
                          : '${formatThousands(expenses.kmAnual)} km/año · '
                              '${expenses.rendimientoKmPorGalon} km/gal · '
                              '${formatCop(expenses.precioGalon)}/gal',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              if (!editing)
                Text(
                  formatCop(expenses.gasolina),
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          if (editing) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: MiniNumberField(
                    label: 'Km/año',
                    semanticLabel: 'Kilómetros recorridos por año',
                    value: expenses.kmAnual,
                    onChanged: onKm,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MiniNumberField(
                    label: 'Km/galón',
                    semanticLabel: 'Rendimiento en kilómetros por galón',
                    value: expenses.rendimientoKmPorGalon,
                    onChanged: onRendimiento,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: MiniNumberField(
                    label: '\$/galón',
                    semanticLabel: 'Precio del galón de gasolina',
                    value: expenses.precioGalon,
                    onChanged: onPrecio,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
