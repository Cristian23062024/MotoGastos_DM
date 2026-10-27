import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/account_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/primary_button.dart';

/// Inicio de sesión o registro con correo y contraseña (Supabase Auth).
/// Es opcional: sin cuenta la app funciona igual, pero solo guarda el
/// último escaneo en el dispositivo.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final account = context.read<AccountState>();
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      if (_registering) {
        final needsConfirmation = await account.signUp(email, password);
        if (needsConfirmation) {
          setState(() {
            _registering = false;
            _info = 'Te enviamos un correo a $email. Confírmalo y luego '
                'inicia sesión.';
          });
          return;
        }
      } else {
        await account.signIn(email, password);
      }
      if (mounted) Navigator.of(context).pop();
    } on AuthException catch (e) {
      setState(() => _error = _authMessage(e));
    } catch (e) {
      debugPrint('Error de autenticación: $e');
      setState(() => _error = 'No se pudo conectar. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _authMessage(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('already registered')) {
      return 'Ese correo ya tiene una cuenta. Inicia sesión.';
    }
    if (message.contains('email not confirmed')) {
      return 'Primero confirma tu correo con el enlace que te enviamos.';
    }
    return e.message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            MgHeader(
              title: 'Cuenta',
              leading: RoundGlassButton(
                icon: Icons.arrow_back,
                tooltip: 'Volver',
                size: 40,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: GlassCard(
                  radius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: false, label: Text('Iniciar sesión')),
                            ButtonSegment(value: true, label: Text('Registrarse')),
                          ],
                          selected: {_registering},
                          showSelectedIcon: false,
                          onSelectionChanged: _busy
                              ? null
                              : (s) => setState(() {
                                    _registering = s.first;
                                    _error = null;
                                  }),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Con una cuenta se guardan todos tus escaneos. Sin '
                          'cuenta solo se conserva el último en este teléfono.',
                          style: AppText.bodySm,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _email,
                          enabled: !_busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Correo'),
                          validator: (v) => v == null || !v.trim().contains('@')
                              ? 'Escribe un correo válido.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: true,
                          autofillHints: [
                            _registering
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          validator: (v) => v == null || v.length < 6
                              ? 'Mínimo 6 caracteres.'
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: AppText.bodySm.copyWith(color: AppColors.error),
                          ),
                        ],
                        if (_info != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _info!,
                            style: AppText.bodySm.copyWith(color: AppColors.secondary),
                          ),
                        ],
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: _busy
                              ? 'Un momento…'
                              : _registering
                                  ? 'Crear cuenta'
                                  : 'Iniciar sesión',
                          icon: _registering ? Icons.person_add_alt : Icons.login,
                          onPressed: _busy ? null : _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
