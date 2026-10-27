import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_scan.dart';
import '../state/account_state.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/glass.dart';
import 'expenses_screen.dart';
import 'login_screen.dart';

/// Historial de escaneos: todos los de la cuenta, o solo el último si el
/// usuario no ha iniciado sesión. Tocar uno lo reabre en "Gastos Anuales".
class ScansScreen extends StatelessWidget {
  const ScansScreen({super.key});

  void _open(BuildContext context, SavedScan scan) {
    context.read<AppState>().openSavedScan(scan);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExpensesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountState>();
    final scans = account.scans;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MgHeader(
              title: 'Mis escaneos',
              leading: RoundGlassButton(
                icon: Icons.arrow_back,
                tooltip: 'Volver',
                size: 40,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: account.loadScans,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    if (!account.isLoggedIn) ...[
                      _GuestNotice(
                        loginAvailable: account.loginAvailable,
                        onLogin: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (account.scansError != null)
                      Text(
                        account.scansError!,
                        style: AppText.bodySm.copyWith(color: AppColors.error),
                      )
                    else if (scans.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Text(
                          'Todavía no has guardado ningún escaneo.',
                          textAlign: TextAlign.center,
                          style: AppText.bodyMd,
                        ),
                      ),
                    for (final scan in scans) ...[
                      _ScanTile(scan: scan, onTap: () => _open(context, scan)),
                      const SizedBox(height: 12),
                    ],
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

class _GuestNotice extends StatelessWidget {
  final bool loginAvailable;
  final VoidCallback onLogin;

  const _GuestNotice({required this.loginAvailable, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      color: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sin cuenta solo se guarda tu último escaneo en este teléfono.',
              style: AppText.bodySm,
            ),
          ),
          if (loginAvailable)
            TextButton(onPressed: onLogin, child: const Text('Iniciar sesión')),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final SavedScan scan;
  final VoidCallback onTap;

  const _ScanTile({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final moto = scan.motorcycle;
    final date = scan.createdAt.toLocal();
    final fecha =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: GlassCard(
          radius: 16,
          color: AppColors.surfaceContainer.withValues(alpha: 0.6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moto.displayName, style: AppText.headlineSm),
                    const SizedBox(height: 2),
                    Text('${moto.engineCc} cc · $fecha', style: AppText.bodySm),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const CapsLabel('Anual', color: AppColors.onSurfaceVariant),
                  Text(
                    formatCop(scan.expenses.total),
                    style: AppText.headlineSm.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}
