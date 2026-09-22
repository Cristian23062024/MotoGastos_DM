import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/welcome_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class MotoGastosApp extends StatelessWidget {
  const MotoGastosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'MotoGastos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const WelcomeScreen(),
      ),
    );
  }
}
