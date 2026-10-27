import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/colombia_rates_2026.dart';
import '../models/expense_inputs.dart';
import '../models/motorcycle.dart';
import '../state/account_state.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/expense_row.dart';
import '../widgets/glass.dart';
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
  Future<void> _lastSave = Future.value();

  @override
  void initState() {
    super.initState();
    // Llegar aquí cierra el escaneo: se guarda (en la cuenta o en el
    // dispositivo) y se vuelve a guardar al terminar de editar valores.
    WidgetsBinding.instance.addPostFrameCallback((_) => _save());
  }

  /// Encadena los guardados para que el segundo use el id que devolvió el
  /// primero y no inserte un duplicado.
  Future<void> _save() {
    final appState = context.read<AppState>();
    final account = context.read<AccountState>();
    return _lastSave = _lastSave.then((_) async {
      final moto = appState.motorcycle;
      final expenses = appState.expenses;
      if (moto == null || expenses == null) return;
      try {
        appState.scanId =
            await account.saveScan(moto, expenses, id: appState.scanId);
      } catch (e) {
        debugPrint('Error guardando el escaneo: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo guardar el escaneo.')),
          );
        }
      }
    });
  }

  void _toggleEditing() {
    if (_editing) _save();
    setState(() => _editing = !_editing);
  }

  void _update(AppState appState, ExpenseInputs Function(ExpenseInputs) updater) {
    final current = appState.expenses;
    if (current == null) return;
    appState.updateExpenses(updater(current));
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cómo se calcula?'),
        content: const Text(
          'Estimado con tarifas 2026 investigadas: SOAT según cilindraje, '
          'tecnomecánica promedio, impuesto vehicular (avalúo × 1,5 % para '
          'motos de más de 125 cc) y gasolina según kilometraje, rendimiento '
          'y precio del galón. El rendimiento parte del consumo que estimó la '
          'IA. Ajusta cualquier valor con "Editar valores" — no reemplaza una '
          'cotización oficial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyReport(Motorcycle moto, ExpenseInputs e) async {
    final report = StringBuffer()
      ..writeln('MotoGastos · ${moto.displayName} (${moto.engineCc} cc)')
      ..writeln('Gastos anuales estimados, tarifas 2026')
      ..writeln('SOAT: ${formatCop(e.soat)}')
      ..writeln('Tecnomecánica: ${formatCop(e.tecnomecanica)}')
      ..writeln('Impuesto vehicular: ${formatCop(e.impuesto)}')
      ..writeln('Gasolina (${formatThousands(e.kmAnual)} km): ${formatCop(e.gasolina)}')
      ..writeln('Mantenimiento: ${formatCop(e.mantenimiento)}')
      ..writeln('Total anual: ${formatCop(e.total)} COP')
      ..write('Cuota mensual: ${formatCop(e.mensual)}');
    await Clipboard.setData(ClipboardData(text: report.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informe copiado al portapapeles.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final moto = appState.motorcycle;
        final expenses = appState.expenses;

        if (moto == null || expenses == null) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  MgHeader(
                    title: 'Gastos Anuales',
                    leading: RoundGlassButton(
                      icon: Icons.arrow_back,
                      tooltip: 'Volver',
                      size: 40,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Expanded(
                    child: Center(child: Text('Todavía no hay una moto ni gastos calculados.')),
                  ),
                ],
              ),
            ),
          );
        }

        final impuestoSubtitle = moto.engineCc <= ColombiaRates2026.impuestoExentoHastaCc
            ? 'Exento (≤ ${ColombiaRates2026.impuestoExentoHastaCc} cc)'
            : 'Avalúo × 1,5% (> ${ColombiaRates2026.impuestoExentoHastaCc} cc)';

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                const MgHeader(title: 'Gastos Anuales'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            RoundGlassButton(
                              icon: Icons.arrow_back,
                              tooltip: 'Volver a la ficha técnica',
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            _EditPill(
                              editing: _editing,
                              onTap: _toggleEditing,
                            ),
                            const SizedBox(width: 4),
                            RoundGlassButton(
                              icon: Icons.info_outline,
                              tooltip: 'Información de cálculo',
                              size: 40,
                              iconColor: AppColors.onSurfaceVariant,
                              onTap: _showInfo,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          color: AppColors.surfaceContainerLow.withValues(alpha: 0.9),
                          shadow: const [
                            BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 8)),
                          ],
                          child: Row(
                            children: [
                              const IconBadge(icon: Icons.sports_motorsports, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      moto.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.headlineSm,
                                    ),
                                    Text(
                                      '${moto.engineCc} cc · Tarifas 2026',
                                      style: AppText.bodySm,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const CapsLabel('Proyección'),
                                  Text(
                                    '${formatThousands(expenses.kmAnual)} km',
                                    style: AppText.labelMd.copyWith(
                                      color: AppColors.tertiary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ExpenseRow(
                          icon: Icons.verified_user,
                          iconColor: AppColors.primaryContainer,
                          label: 'SOAT',
                          subtitle: 'Seguro obligatorio · ${_soatLabelShort(moto.engineCc)}',
                          value: expenses.soat,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(soat: v)),
                        ),
                        const SizedBox(height: 8),
                        ExpenseRow(
                          icon: Icons.speed,
                          iconColor: AppColors.tertiary,
                          label: 'Tecnomecánica',
                          subtitle: 'Revisión técnico-mecánica anual',
                          value: expenses.tecnomecanica,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(tecnomecanica: v)),
                        ),
                        const SizedBox(height: 8),
                        ExpenseRow(
                          icon: Icons.percent,
                          iconColor: AppColors.primary,
                          label: 'Impuesto Vehicular',
                          subtitle: impuestoSubtitle,
                          value: expenses.impuesto,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(impuesto: v)),
                        ),
                        const SizedBox(height: 8),
                        _GasolinaBlock(
                          expenses: expenses,
                          editing: _editing,
                          onKm: (v) => _update(appState, (e) => e.copyWith(kmAnual: v)),
                          onRendimiento: (v) => _update(appState, (e) => e.copyWith(rendimientoKmPorGalon: v)),
                          onPrecio: (v) => _update(appState, (e) => e.copyWith(precioGalon: v)),
                        ),
                        const SizedBox(height: 8),
                        ExpenseRow(
                          icon: Icons.build,
                          iconColor: AppColors.secondaryFixed,
                          label: 'Mantenimiento',
                          subtitle: 'Aceite, frenos, llantas, ajustes',
                          value: expenses.mantenimiento,
                          editing: _editing,
                          onChanged: (v) => _update(appState, (e) => e.copyWith(mantenimiento: v)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(Icons.policy_outlined, size: 16, color: AppColors.outline),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Tarifas calculadas con proyección legal 2026, ajustadas al '
                                'IPC/UVT estimado y al precio promedio nacional de la gasolina '
                                'corriente. No reemplaza una cotización oficial.',
                                style: AppText.bodySm.copyWith(color: AppColors.outline, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SummaryCard(
                          expenses: expenses,
                          onScanAnother: () async {
                            if (_editing) await _save();
                            if (!context.mounted) return;
                            appState.reset();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                              (route) => false,
                            );
                          },
                          onCopyReport: () => _copyReport(moto, expenses),
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

class _EditPill extends StatelessWidget {
  final bool editing;
  final VoidCallback onTap;

  const _EditPill({required this.editing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: editing
          ? AppColors.primaryContainer
          : AppColors.surfaceContainerHigh.withValues(alpha: 0.9),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                editing ? Icons.check : Icons.tune,
                size: 16,
                color: editing ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                editing ? 'LISTO' : 'EDITAR VALORES',
                style: AppText.labelCaps.copyWith(
                  color: editing ? Colors.white : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final ExpenseInputs expenses;
  final VoidCallback onScanAnother;
  final VoidCallback onCopyReport;

  const _SummaryCard({
    required this.expenses,
    required this.onScanAnother,
    required this.onCopyReport,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
      shadow: const [
        BoxShadow(color: Color(0xB3000000), blurRadius: 40, offset: Offset(0, 16)),
      ],
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Resplandor carmesí en la esquina.
          Positioned(
            top: -72,
            right: -72,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withValues(alpha: 0.12),
                    blurRadius: 64,
                    spreadRadius: 16,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CapsLabel('Costo total anual'),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(formatCop(expenses.total), style: AppText.telemetryLg),
                              const SizedBox(width: 6),
                              Text('COP', style: AppText.labelCaps),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const CapsLabel('Cuota mensual'),
                      Text(
                        formatCop(expenses.mensual),
                        style: AppText.headlineSm.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Escanear otra',
                      onTap: onScanAnother,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryButton(
                      icon: Icons.receipt_long,
                      label: 'Copiar informe',
                      primary: true,
                      onTap: onCopyReport,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SummaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = primary ? Colors.white : AppColors.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: primary ? AppColors.racingGlow() : AppColors.cardShadow,
      ),
      child: Material(
        color: primary ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.labelMd.copyWith(
                      color: fg,
                      fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(icon: Icons.local_gas_station, color: AppColors.primaryContainer),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gasolina Corriente', style: AppText.headlineSm),
                    const SizedBox(height: 2),
                    Text(
                      editing
                          ? 'Según kilometraje y rendimiento'
                          : '${formatThousands(expenses.kmAnual)} km/año · '
                              '${expenses.rendimientoKmPorGalon} km/gal · '
                              '${formatCop(expenses.precioGalon)}/gal',
                      style: AppText.bodySm,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  formatCop(expenses.gasolina),
                  style: AppText.telemetry.copyWith(fontSize: 22),
                ),
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
