import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../../shared/data/mock_data.dart';
import '../../../shared/models/models.dart';
import 'category_entity.dart';
import 'goal_entity.dart';
import 'transaction_entity.dart';

/// Ouverture Isar + amorçage (seed au premier lancement, base vide) +
/// chargement initial. Tout est fait de façon asynchrone, une seule fois,
/// avant `runApp` — les providers/notifiers restent ensuite synchrones
/// côté UI (voir spec `docs/superpowers/specs/2026-08-01-isar-persistence-design.md`).
class IsarService {
  IsarService._();

  static Future<Isar> open() async {
    final dir = await getApplicationDocumentsDirectory();
    return Isar.open(
      [CategoryEntitySchema, TransactionEntitySchema, GoalEntitySchema],
      directory: dir.path,
    );
  }

  static Future<List<Category>> loadCategories(Isar isar) async {
    var entities = await isar.categoryEntitys.where().findAll();
    if (entities.isEmpty) {
      await isar.writeTxn(() => isar.categoryEntitys.putAll(_seedCategories));
      entities = _seedCategories;
    }
    return entities.map((e) => e.toDomain()).toList();
  }

  static Future<List<Transaction>> loadTransactions(Isar isar) async {
    var entities = await isar.transactionEntitys.where().sortByDate().findAll();
    if (entities.isEmpty) {
      final seed = MockData.transactions().map(TransactionEntity.fromDomain).toList();
      await isar.writeTxn(() => isar.transactionEntitys.putAll(seed));
      entities = seed;
    }
    return entities.map((e) => e.toDomain()).toList();
  }

  static Future<List<SavingGoal>> loadGoals(Isar isar) async {
    var entities = await isar.goalEntitys.where().findAll();
    if (entities.isEmpty) {
      await isar.writeTxn(() => isar.goalEntitys.putAll(_seedGoals));
      entities = _seedGoals;
    }
    return entities.map((e) => e.toDomain()).toList();
  }

  static final List<CategoryEntity> _seedCategories = [
    ('loyer', 'Loyer', 'home', 0xFF2B3A9E),
    ('nourriture', 'Nourriture', 'restaurant', 0xFF3D5AFE),
    ('shopping', 'Shopping', 'shopping_bag', 0xFF6D82FF),
    ('transport', 'Transport', 'directions_bus', 0xFF9DACFF),
    ('loisirs', 'Loisirs', 'sports_esports', 0xFFC9D2FF),
    ('sante', 'Santé', 'favorite', 0xFF16B364),
    ('factures', 'Factures', 'receipt_long', 0xFFF79009),
    ('salaire', 'Salaire', 'payments', 0xFF16B364),
    ('autres', 'Autres', 'category', 0xFF98A2B3),
  ]
      .map((c) => CategoryEntity()
        ..categoryId = c.$1
        ..name = c.$2
        ..iconKey = c.$3
        ..colorValue = c.$4)
      .toList();

  static List<GoalEntity> get _seedGoals {
    final now = DateTime.now();
    final seed = [
      ('g1', 'Fonds d\'urgence', 500000.0, 320000.0, DateTime(now.year, 12, 31)),
      ('g2', 'Nouveau MacBook', 900000.0, 210000.0, DateTime(now.year + 1, 3, 1)),
      ('g3', 'Voyage Zanzibar', 650000.0, 480000.0, DateTime(now.year, 10, 15)),
    ];
    return [
      for (var i = 0; i < seed.length; i++)
        GoalEntity()
          ..goalId = seed[i].$1
          ..name = seed[i].$2
          ..targetAmount = seed[i].$3
          ..currentAmount = seed[i].$4
          ..deadline = seed[i].$5
          ..paletteIndex = i,
    ];
  }
}
