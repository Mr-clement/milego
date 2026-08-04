import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../core/services/auth/auth_service.dart';
import '../../core/services/isar/fast_hash.dart';
import '../../core/services/isar/goal_entity.dart';
import '../../core/services/isar/goal_palette.dart';
import '../../core/services/isar/transaction_entity.dart';
import '../data/mock_data.dart';
import '../models/models.dart';

/// Instance Isar ouverte, injectée via `overrideWithValue` dans `main()`
/// (et dans les tests) — voir `core/services/isar/isar_service.dart`.
final isarProvider = Provider<Isar>(
  (ref) => throw UnimplementedError('isarProvider doit être surchargé (voir main.dart)'),
);

/// Authentification locale, injectée via `overrideWithValue` dans `main()`
/// (et dans les tests) — voir `core/services/auth/auth_service.dart`.
final authServiceProvider = Provider<AuthService>(
  (ref) => throw UnimplementedError('authServiceProvider doit être surchargé (voir main.dart)'),
);

/// Catégories persistées (lecture seule pour l'instant, pas d'UI de
/// création/édition — voir spec Isar, section « Hors scope »). Chargées et
/// injectées via `overrideWithValue` dans `main()`.
final categoriesProvider = Provider<List<Category>>(
  (ref) => throw UnimplementedError('categoriesProvider doit être surchargé (voir main.dart)'),
);

/// Thème clair / sombre (toggle via l'icône soleil de l'en-tête).
final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Nom affiché dans la salutation.
final userNameProvider = StateProvider<String>((ref) => 'Clément');

/// Source des transactions, persistée dans Isar. L'état local est mis à
/// jour immédiatement (UI réactive), l'écriture Isar se fait en tâche de
/// fond (pas de retry/rollback — hors scope MVP, écriture locale fiable).
class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._isar, List<Transaction> initial) : super(initial);

  final Isar _isar;

  void add(Transaction tx) {
    state = [tx, ...state];
    unawaited(_isar.writeTxn(
        () => _isar.transactionEntitys.put(TransactionEntity.fromDomain(tx))));
  }

  void update(Transaction tx) {
    state = [for (final t in state) t.id == tx.id ? tx : t];
    unawaited(_isar.writeTxn(
        () => _isar.transactionEntitys.put(TransactionEntity.fromDomain(tx))));
  }

  void remove(String id) {
    state = state.where((t) => t.id != id).toList();
    unawaited(_isar
        .writeTxn(() => _isar.transactionEntitys.delete(fastHash(id))));
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => throw UnimplementedError('transactionsProvider doit être surchargé (voir main.dart)'),
);

/// Source des objectifs d'épargne, persistée dans Isar (même principe que
/// [TransactionsNotifier]).
class GoalsNotifier extends StateNotifier<List<SavingGoal>> {
  GoalsNotifier(this._isar, List<SavingGoal> initial) : super(initial);

  final Isar _isar;

  void add({
    required String name,
    required double targetAmount,
    required double currentAmount,
    required DateTime deadline,
  }) {
    final paletteIndex = state.length % GoalPalette.entries.length;
    final (icon, color) = GoalPalette.entries[paletteIndex];
    final id = 'g${DateTime.now().microsecondsSinceEpoch}';
    state = [
      ...state,
      SavingGoal(
        id: id,
        name: name,
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: deadline,
        icon: icon,
        color: color,
      ),
    ];
    final entity = GoalEntity()
      ..goalId = id
      ..name = name
      ..targetAmount = targetAmount
      ..currentAmount = currentAmount
      ..deadline = deadline
      ..paletteIndex = paletteIndex;
    unawaited(_isar.writeTxn(() => _isar.goalEntitys.put(entity)));
  }

  void remove(String id) {
    state = state.where((g) => g.id != id).toList();
    unawaited(_isar.writeTxn(() => _isar.goalEntitys.delete(fastHash(id))));
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<SavingGoal>>(
  (ref) => throw UnimplementedError('goalsProvider doit être surchargé (voir main.dart)'),
);

final insightProvider = Provider<AiInsight>((ref) => MockData.insight);

/// Solde cumulé (tous les revenus moins toutes les dépenses, tout
/// l'historique) — distinct de `monthSummaryProvider` qui reste borné au
/// mois courant (budget). Voir l'écran Rapports.
final globalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider);
  return txs.fold(0.0, (sum, t) => sum + t.signedAmount);
});

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
