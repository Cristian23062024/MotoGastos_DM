import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:motogastos/models/expense_inputs.dart';
import 'package:motogastos/models/motorcycle.dart';
import 'package:motogastos/models/saved_scan.dart';
import 'package:motogastos/state/account_state.dart';

const _moto = Motorcycle(
  brand: 'Yamaha',
  model: 'NMAX',
  category: 'Scooter',
  engineCc: 155,
  confidence: 0.9,
  fuelEfficiencyKmL: 40,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('SavedScan sobrevive el viaje a JSON', () {
    final scan = SavedScan(
      id: 'abc',
      motorcycle: _moto,
      expenses: ExpenseInputs.sugeridoPara(_moto).copyWith(mantenimiento: 123),
      createdAt: DateTime.utc(2026, 10, 27),
    );
    final back = SavedScan.fromJson(scan.toJson());
    expect(back.id, 'abc');
    expect(back.motorcycle.displayName, 'Yamaha NMAX');
    expect(back.expenses.mantenimiento, 123);
    expect(back.expenses.total, scan.expenses.total);
    expect(back.createdAt, scan.createdAt);
  });

  test('sin cuenta solo se conserva el último escaneo', () async {
    final account = AccountState();
    expect(account.loginAvailable, isFalse);

    final first = ExpenseInputs.sugeridoPara(_moto);
    expect(await account.saveScan(_moto, first), SavedScan.localId);
    await account.saveScan(
        _moto.copyWith(model: 'XMAX', engineCc: 300), first);

    expect(account.scans, hasLength(1));
    expect(account.scans.single.motorcycle.model, 'XMAX');

    // Persiste: otra instancia (p. ej. tras reiniciar la app) lo lee.
    final reopened = AccountState();
    await reopened.loadScans();
    expect(reopened.scans.single.motorcycle.engineCc, 300);
  });
}
