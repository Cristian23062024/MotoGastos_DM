import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/expense_inputs.dart';
import '../models/motorcycle.dart';
import '../models/saved_scan.dart';

/// Se leen de env.json igual que las API keys de reconocimiento. Sirve la
/// "anon key" o la "publishable key" del proyecto:
///   flutter run --dart-define-from-file=env.json
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

/// Cuenta opcional y escaneos guardados. Con sesión iniciada los escaneos
/// van a la tabla `scans` de Supabase (ver `supabase/schema.sql`); sin
/// sesión solo se conserva el último, en SharedPreferences.
class AccountState extends ChangeNotifier {
  AccountState({SupabaseClient? client}) : _client = client {
    _authSub = _client?.auth.onAuthStateChange.listen(_onAuthChange);
    loadScans();
  }

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String _localKey = 'last_scan';

  final SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSub;

  /// false si no hay Supabase configurado: la app funciona solo como invitado.
  bool get loginAvailable => _client != null;
  User? get user => _client?.auth.currentUser;
  bool get isLoggedIn => user != null;

  List<SavedScan> scans = const [];
  String? scansError;

  Future<void> _onAuthChange(AuthState state) async {
    if (state.event == AuthChangeEvent.signedIn) await _uploadLocalScan();
    if (state.event == AuthChangeEvent.signedIn ||
        state.event == AuthChangeEvent.signedOut) {
      await loadScans();
    }
  }

  Future<void> signIn(String email, String password) =>
      _client!.auth.signInWithPassword(email: email, password: password);

  /// Devuelve true si Supabase pide confirmar el correo antes de entrar.
  Future<bool> signUp(String email, String password) async {
    final response =
        await _client!.auth.signUp(email: email, password: password);
    return response.session == null;
  }

  Future<void> signOut() => _client!.auth.signOut();

  Future<void> loadScans() async {
    final client = _client;
    try {
      if (client != null && isLoggedIn) {
        final rows = await client
            .from('scans')
            .select()
            .order('created_at', ascending: false);
        scans = rows.map(SavedScan.fromJson).toList();
      } else {
        final raw = (await SharedPreferences.getInstance()).getString(_localKey);
        scans = raw == null
            ? const []
            : [SavedScan.fromJson(jsonDecode(raw) as Map<String, dynamic>)];
      }
      scansError = null;
    } catch (e) {
      debugPrint('Error cargando escaneos: $e');
      scansError = 'No se pudieron cargar tus escaneos.';
    }
    notifyListeners();
  }

  /// Guarda (o actualiza, si ya tiene [id]) un escaneo y devuelve su id.
  /// Sin sesión, reemplaza el único escaneo local.
  Future<String> saveScan(Motorcycle moto, ExpenseInputs expenses,
      {String? id}) async {
    final client = _client;
    final data = {'motorcycle': moto.toJson(), 'expenses': expenses.toJson()};
    String savedId;
    if (client != null && isLoggedIn) {
      if (id != null && id != SavedScan.localId) {
        await client.from('scans').update(data).eq('id', id);
        savedId = id;
      } else {
        final row =
            await client.from('scans').insert(data).select('id').single();
        savedId = row['id'] as String;
      }
    } else {
      final scan = SavedScan(
        id: SavedScan.localId,
        motorcycle: moto,
        expenses: expenses,
        createdAt: DateTime.now(),
      );
      await (await SharedPreferences.getInstance())
          .setString(_localKey, jsonEncode(scan.toJson()));
      savedId = SavedScan.localId;
    }
    await loadScans();
    return savedId;
  }

  /// Al iniciar sesión, el escaneo hecho como invitado pasa a la cuenta.
  /// Solo se borra del dispositivo si la subida funcionó.
  Future<void> _uploadLocalScan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return;
    try {
      final scan = SavedScan.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      await _client!.from('scans').insert({
        'motorcycle': scan.motorcycle.toJson(),
        'expenses': scan.expenses.toJson(),
        'created_at': scan.createdAt.toUtc().toIso8601String(),
      });
      await prefs.remove(_localKey);
    } catch (e) {
      debugPrint('No se pudo subir el escaneo local: $e');
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
