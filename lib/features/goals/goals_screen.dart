import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/milego_card.dart';
import 'add_goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.milego;
    final goals = ref.watch(goalsProvider);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          Row(
            children: [
              Text(
                'Objectifs d\'épargne',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _openAddSheet(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (goals.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'Aucun objectif pour l\'instant',
                  style: TextStyle(color: c.textMuted),
                ),
              ),
            )
          else
            for (final (i, g) in goals.indexed) ...[
              _GoalCard(goal: g)
                  .animate()
                  .fadeIn(
                    duration: 220.ms,
                    delay: (i * 25).clamp(0, 200).ms,
                  )
                  .slideY(begin: 0.06, curve: Curves.easeOut),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddGoalSheet(),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});
  final SavingGoal goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.milego;
    final percent = (goal.progress * 100).round();
    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) =>
          confirmDelete(context, message: 'Supprimer « ${goal.name} » ?'),
      onDismissed: (_) => ref.read(goalsProvider.notifier).remove(goal.id),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: MilegoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: goal.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(goal.icon, color: goal.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Échéance : ${Dates.dayMonth(goal.deadline)}',
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    color: goal.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: c.surfaceAlt,
                valueColor: AlwaysStoppedAnimation(goal.color),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Money.full(goal.currentAmount),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '/ ${Money.full(goal.targetAmount)}',
                  style: TextStyle(color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
