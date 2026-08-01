import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Dialog de confirmation partagé pour les suppressions (swipe-to-delete).
Future<bool> confirmDelete(
  BuildContext context, {
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmer la suppression'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.expense),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  return result ?? false;
}
