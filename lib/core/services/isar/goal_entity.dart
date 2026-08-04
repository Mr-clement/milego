import 'package:isar_community/isar.dart';

import '../../../shared/models/models.dart';
import 'fast_hash.dart';
import 'goal_palette.dart';

part 'goal_entity.g.dart';

@collection
class GoalEntity {
  Id get isarId => fastHash(goalId);

  late String goalId;
  late String name;
  late double targetAmount;
  late double currentAmount;
  late DateTime deadline;
  late int paletteIndex;

  SavingGoal toDomain() {
    final (icon, color) =
        GoalPalette.entries[paletteIndex % GoalPalette.entries.length];
    return SavingGoal(
      id: goalId,
      name: name,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline: deadline,
      icon: icon,
      color: color,
    );
  }
}
