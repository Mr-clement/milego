import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Carte hero « Solde restant ce mois » — fond sombre, barre de progression bleue.
class BalanceHeroCard extends StatelessWidget {
  const BalanceHeroCard({
    super.key,
    required this.remaining,
    required this.budget,
    required this.usedRatio,
    this.onTap,
  });

  final double remaining;
  final double budget;
  final double usedRatio;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (usedRatio * 100).round();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroTop, AppColors.heroBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroBottom.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.hero),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Solde restant ce mois',
                      style: TextStyle(color: Color(0xFFAAB1C4), fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '$percent%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Money.full(remaining),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: LinearProgressIndicator(
                    value: usedRatio,
                    minHeight: 7,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Budget mensuel : ${Money.full(budget)}',
                  style:
                      const TextStyle(color: Color(0xFF8B92A6), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
