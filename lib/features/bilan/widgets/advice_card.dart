import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/milego_card.dart';

/// Carte « Conseil de Léa » — conseil proactif généré par l'assistant.
class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.insight, required this.onOpenChat});

  final AiInsight insight;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final c = context.milego;
    return MilegoCard(
      color: c.surfaceAlt,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.content,
            style: TextStyle(
                color: c.textMuted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onOpenChat,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: const Text('Discuter avec Léa  →',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
