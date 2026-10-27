import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'state/account_state.dart';

Future<void> main() async {
  if (AccountState.isConfigured) {
    WidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  }
  runApp(const MotoGastosApp());
}
