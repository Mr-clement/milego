import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Champ texte standard Milego (formulaires auth, transaction, objectif).
/// Le style (fond, bordures arrondies) vient de l'`InputDecorationTheme`
/// défini dans [AppTheme].
class MilegoTextField extends StatelessWidget {
  const MilegoTextField({
    super.key,
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
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(color: context.milego.textPrimary),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
