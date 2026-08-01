import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

/// Thème clair / sombre (toggle via l'icône soleil de l'en-tête).
final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Nom affiché dans la salutation.
final userNameProvider = StateProvider<String>((ref) => 'Clément');

/// Source des transactions (MVP : en mémoire, mutable).
class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier() : super(MockData.transactions());

  void add(Transaction tx) => state = [tx, ...state];

  void update(Transaction tx) =>
      state = [for (final t in state) t.id == tx.id ? tx : t];

  void remove(String id) =>
      state = state.where((t) => t.id != id).toList();
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
        (ref) => TransactionsNotifier());

/// Petite palette pour assigner icône/couleur aux nouveaux objectifs (pas de
/// sélecteur en v1 — cf. spec).
const _goalPalette = <(IconData, Color)>[
  (Icons.savings_rounded, AppColors.primary),
  (Icons.flag_rounded, Color(0xFF6D82FF)),
  (Icons.emoji_events_rounded, Color(0xFF16B364)),
  (Icons.star_rounded, AppColors.donutColor2),
];

class GoalsNotifier extends StateNotifier<List<SavingGoal>> {
  GoalsNotifier() : super(MockData.goals());

  void add({
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
  }) {
    final (icon, color) = _goalPalette[state.length % _goalPalette.length];
    state = [
      ...state,
      SavingGoal(
        id: 'g${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        icon: icon,
        color: color,
      ),
    ];
  }

  void remove(String id) =>
      state = state.where((g) => g.id != id).toList();
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<SavingGoal>>(
        (ref) => GoalsNotifier());

final insightProvider = Provider<AiInsight>((ref) => MockData.insight);

/// Agrégats du mois courant dérivés des transactions.
class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.expense,
    required this.savings,
    required this.budget,
    required this.byCategory,
  });

  final double income;
  final double expense;
  final double savings;
  final double budget;

  /// categoryId -> montant dépensé (trié décroissant).
  final List<MapEntry<String, double>> byCategory;

  double get remaining => budget - expense;
  double get budgetUsedRatio =>
      budget == 0 ? 0 : (expense / budget).clamp(0, 1);
}

final monthSummaryProvider = Provider<MonthSummary>((ref) {
  final txs = ref.watch(transactionsProvider);
  final now = DateTime.now();
  double income = 0, expense = 0;
  final byCat = <String, double>{};

  for (final t in txs) {
    if (t.date.year != now.year || t.date.month != now.month) continue;
    if (t.type == TxType.income) {
      income += t.amount;
    } else if (t.type == TxType.expense) {
      expense += t.amount;
      byCat.update(t.categoryId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
  }

  final sorted = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return MonthSummary(
    income: income,
    expense: expense,
    savings: (income - expense).clamp(0, double.infinity),
    budget: MockData.monthlyBudget,
    byCategory: sorted,
  );
});
