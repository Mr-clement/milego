import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';

/// Connexion — vérifie le compte local (voir AuthService). Pas de
/// réinitialisation de mot de passe (pas de service d'email en local).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AuthService auth = ref.read(authServiceProvider);
    final ok = await auth.logIn(
      email: _email.text.trim(),
      password: _password.text,
    );
    if (!ok) {
      setState(() => _error = 'Email ou mot de passe incorrect.');
      return;
    }
    setState(() => _error = null);
    ref.read(userNameProvider.notifier).state = auth.userName ?? '';
    if (!mounted) return;
    context.go('/bilan');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(height: 20),
              Text('Bon retour',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Connectez-vous à votre compte Milego.',
                  style: TextStyle(color: c.textMuted, fontSize: 14)),
              const SizedBox(height: 28),
              _AuthField(
                controller: _email,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _AuthField(
                  controller: _password, hint: 'Mot de passe', obscure: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: const TextStyle(color: AppColors.expense, fontSize: 13)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: const Text('Se connecter',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  child: const Text('Pas de compte ? S\'inscrire'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: c.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.border),
        ),
      ),
    );
  }
}
