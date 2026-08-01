import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                      ref.read(themeModeProvider.notifier).state =
                          v ? ThemeMode.dark : ThemeMode.light,
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
          const SizedBox(height: 20),
          Center(
            child: Text('Milego Budget · v1.0.0 (MVP)',
                style: TextStyle(color: c.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
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
