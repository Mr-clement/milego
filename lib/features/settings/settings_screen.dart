import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/milego_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.milego;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Text('Réglages',
              style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          MilegoCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: isDark,
                  onChanged: (v) =>
                      ref.read(themeModeProvider.notifier).set(
                          v ? ThemeMode.dark : ThemeMode.light),
                  title: Text('Mode sombre',
                      style: TextStyle(color: c.textPrimary)),
                  secondary:
                      Icon(Icons.dark_mode_rounded, color: c.textMuted),
                ),
                _tile(c, Icons.attach_money_rounded, 'Devise', 'FCFA'),
                _tile(c, Icons.language_rounded, 'Langue', 'Français'),
                _tile(c, Icons.download_rounded, 'Export / Import', null),
                _tile(c, Icons.cloud_sync_rounded,
                    'Sauvegarde cloud', 'Bientôt'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MilegoCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.expense),
              title: const Text('Déconnexion',
                  style: TextStyle(
                      color: AppColors.expense, fontWeight: FontWeight.w600)),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('Milego Budget · v1.0.0 (MVP)',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vos données restent sur cet appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authServiceProvider).logOut();
    if (context.mounted) context.go('/login');
  }

  Widget _tile(MilegoColors c, IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: c.textMuted),
      title: Text(title, style: TextStyle(color: c.textPrimary)),
      trailing: value == null
          ? Icon(Icons.chevron_right_rounded, color: c.textMuted)
          : Text(value, style: TextStyle(color: c.textMuted)),
    );
  }
}
