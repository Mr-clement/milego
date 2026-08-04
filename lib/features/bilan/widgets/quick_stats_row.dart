import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/milego_card.dart';

/// Rangée Revenus / Dépenses / Épargne.
class QuickStatsRow extends StatelessWidget {
  const QuickStatsRow({
    super.key,
    required this.income,
    required this.expense,
    required this.savings,
    this.onTapIncome,
    this.onTapExpense,
    this.onTapSavings,
  });

  final double income;
  final double expense;
  final double savings;
  final VoidCallback? onTapIncome;
  final VoidCallback? onTapExpense;
  final VoidCallback? onTapSavings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.south_west_rounded,
          label: 'Revenus',
          value: Money.compact(income),
          onTap: onTapIncome,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.north_east_rounded,
          label: 'Dépenses',
          value: Money.compact(expense),
          onTap: onTapExpense,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.savings_rounded,
          label: 'Épargne',
          value: Money.compact(savings),
          onTap: onTapSavings,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Expanded(
      child: MilegoCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        radius: 18,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(color: c.textMuted, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
