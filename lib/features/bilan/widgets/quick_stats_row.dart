import 'package:flutter/material.dart';

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
  });

  final double income;
  final double expense;
  final double savings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.south_west_rounded,
          label: 'Revenus',
          value: Money.compact(income),
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.north_east_rounded,
          label: 'Dépenses',
          value: Money.compact(expense),
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.savings_rounded,
          label: 'Épargne',
          value: Money.compact(savings),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return Expanded(
      child: MilegoCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.textMuted),
            const SizedBox(height: 14),
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
