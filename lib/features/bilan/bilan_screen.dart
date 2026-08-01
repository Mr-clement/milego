import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';
import 'widgets/advice_card.dart';
import 'widgets/balance_hero_card.dart';
import 'widgets/expense_breakdown_card.dart';
import 'widgets/quick_stats_row.dart';

/// Écran principal : vision complète de la situation financière (cahier §5.2).
class BilanScreen extends ConsumerWidget {
  const BilanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.milego;
    final name = ref.watch(userNameProvider);
    final summary = ref.watch(monthSummaryProvider);
    final insight = ref.watch(insightProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          // En-tête
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bonjour',
                      style: TextStyle(color: c.textMuted, fontSize: 15)),
                  Text(
                    name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _CircleIconButton(
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                onTap: () => ref.read(themeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark,
              ),
            ],
          ),
          const SizedBox(height: 18),

          BalanceHeroCard(
            remaining: summary.remaining,
            budget: summary.budget,
            usedRatio: summary.budgetUsedRatio,
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08),
          const SizedBox(height: 14),

          QuickStatsRow(
            income: summary.income,
            expense: summary.expense,
            savings: summary.savings,
          ).animate().fadeIn(delay: 80.ms, duration: 350.ms),
          const SizedBox(height: 14),

          AdviceCard(
            insight: insight,
            onOpenChat: () => context.push('/chat'),
          ).animate().fadeIn(delay: 140.ms, duration: 350.ms),
          const SizedBox(height: 14),

          ExpenseBreakdownCard(
            byCategory: summary.byCategory,
            total: summary.expense,
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Material(
      color: c.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: c.textPrimary),
        ),
      ),
    );
  }
}
