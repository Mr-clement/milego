import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';

/// Inscription — crée le compte local (voir AuthService).
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (name.isEmpty) {
      setState(() => _error = 'Entrez votre nom.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Entrez un email valide.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Le mot de passe doit faire au moins 6 caractères.');
      return;
    }
    if (password != _confirm.text) {
      setState(() => _error = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _error = null);
    await ref
        .read(authServiceProvider)
        .signUp(name: name, email: email, password: password);
    ref.read(userNameProvider.notifier).state = name;
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
              Text('Créer un compte',
                  style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Vos données restent sur cet appareil.',
                  style: TextStyle(color: c.textMuted, fontSize: 14)),
              const SizedBox(height: 28),
              _AuthField(controller: _name, hint: 'Nom'),
              const SizedBox(height: 12),
              _AuthField(
                controller: _email,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _AuthField(
                  controller: _password, hint: 'Mot de passe', obscure: true),
              const SizedBox(height: 12),
              _AuthField(
                  controller: _confirm,
                  hint: 'Confirmer le mot de passe',
                  obscure: true),
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
                child: const Text('Créer mon compte',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Déjà un compte ? Se connecter'),
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
