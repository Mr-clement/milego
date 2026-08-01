import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../models/models.dart';

/// Catégories par défaut (cahier des charges §5.5) + jeu de données de démo.
class MockData {
  MockData._();

  static const categories = <Category>[
    Category(id: 'loyer', name: 'Loyer', icon: Icons.home_rounded, color: AppColors.donutColor0),
    Category(id: 'nourriture', name: 'Nourriture', icon: Icons.restaurant_rounded, color: AppColors.donutColor1),
    Category(id: 'shopping', name: 'Shopping', icon: Icons.shopping_bag_rounded, color: AppColors.donutColor2),
    Category(id: 'transport', name: 'Transport', icon: Icons.directions_bus_rounded, color: AppColors.donutColor3),
    Category(id: 'loisirs', name: 'Loisirs', icon: Icons.sports_esports_rounded, color: AppColors.donutColor4),
    Category(id: 'sante', name: 'Santé', icon: Icons.favorite_rounded, color: Color(0xFF16B364)),
    Category(id: 'factures', name: 'Factures', icon: Icons.receipt_long_rounded, color: Color(0xFFF79009)),
    Category(id: 'salaire', name: 'Salaire', icon: Icons.payments_rounded, color: Color(0xFF16B364)),
    Category(id: 'autres', name: 'Autres', icon: Icons.category_rounded, color: Color(0xFF98A2B3)),
  ];

  static Category categoryById(String id) =>
      categories.firstWhere((c) => c.id == id, orElse: () => categories.last);

  static const double monthlyBudget = 270000;

  static List<Transaction> transactions() {
    final now = DateTime.now();
    DateTime d(int daysAgo) => now.subtract(Duration(days: daysAgo));
    return [
      Transaction(id: 't1', title: 'Salaire juillet', amount: 340000, type: TxType.income, categoryId: 'salaire', date: d(12)),
      Transaction(id: 't2', title: 'Loyer appartement', amount: 46200, type: TxType.expense, categoryId: 'loyer', date: d(11)),
      Transaction(id: 't3', title: 'Courses Auchan', amount: 24500, type: TxType.expense, categoryId: 'nourriture', date: d(9)),
      Transaction(id: 't4', title: 'Sneakers', amount: 30800, type: TxType.expense, categoryId: 'shopping', date: d(7)),
      Transaction(id: 't5', title: 'Carburant', amount: 15000, type: TxType.expense, categoryId: 'transport', date: d(6)),
      Transaction(id: 't6', title: 'Cinéma & sortie', amount: 12000, type: TxType.expense, categoryId: 'loisirs', date: d(5)),
      Transaction(id: 't7', title: 'Restaurant', amount: 8500, type: TxType.expense, categoryId: 'nourriture', date: d(4)),
      Transaction(id: 't8', title: 'Facture électricité', amount: 9800, type: TxType.expense, categoryId: 'factures', date: d(3)),
      Transaction(id: 't9', title: 'Pharmacie', amount: 6200, type: TxType.expense, categoryId: 'sante', date: d(2)),
      Transaction(id: 't10', title: 'Taxi', amount: 3500, type: TxType.expense, categoryId: 'transport', date: d(1)),
    ];
  }

  static List<SavingGoal> goals() {
    final now = DateTime.now();
    return [
      SavingGoal(id: 'g1', name: 'Fonds d\'urgence', targetAmount: 500000, currentAmount: 320000, deadline: DateTime(now.year, 12, 31), icon: Icons.shield_rounded, color: AppColors.primary),
      SavingGoal(id: 'g2', name: 'Nouveau MacBook', targetAmount: 900000, currentAmount: 210000, deadline: DateTime(now.year + 1, 3, 1), icon: Icons.laptop_mac_rounded, color: Color(0xFF6D82FF)),
      SavingGoal(id: 'g3', name: 'Voyage Zanzibar', targetAmount: 650000, currentAmount: 480000, deadline: DateTime(now.year, 10, 15), icon: Icons.flight_takeoff_rounded, color: Color(0xFF16B364)),
    ];
  }

  static const AiInsight insight = AiInsight(
    type: InsightType.conseil,
    content:
        'Vos dépenses shopping ont augmenté de 20% ce mois-ci. Réduire de 15 000 FCFA vous permettrait d\'atteindre votre objectif épargne 3 semaines plus tôt.',
  );
}
