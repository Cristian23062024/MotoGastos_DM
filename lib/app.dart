import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/welcome_screen.dart';
import 'state/account_state.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class MotoGastosApp extends StatelessWidget {
  const MotoGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(
          create: (_) => AccountState(
            client: AccountState.isConfigured ? Supabase.instance.client : null,
          ),
        ),
      ],
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.surface,
        ),
        child: MaterialApp(
          title: 'MotoGastos',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const WelcomeScreen(),
        ),
      ),
    );
  }
}
