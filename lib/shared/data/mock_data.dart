import 'package:intl/intl.dart';

import '../models/models.dart';

/// Jeu de données de démo, utilisé uniquement pour amorcer Isar au tout
/// premier lancement (base vide) — voir `core/services/isar/isar_service.dart`.
/// Les catégories et objectifs de démo sont définis directement dans
/// IsarService (ils ont besoin d'une clé d'icône / d'un index de palette,
/// pas d'un IconData/Color bruts — voir IconRegistry / GoalPalette).
class MockData {
  MockData._();

  static const double monthlyBudget = 270000;

  static List<Transaction> transactions() {
    final now = DateTime.now();
    // Les dates de démo restent bornées au mois courant (1er du mois au
    // jour actuel), sinon un lancement en tout début de mois ferait
    // basculer les transactions "il y a N jours" dans le mois précédent
    // et le Bilan afficherait des totaux à zéro.
    DateTime d(int daysAgo) =>
        now.subtract(Duration(days: daysAgo.clamp(0, now.day - 1)));
    final monthLabel = DateFormat('MMMM', 'fr_FR').format(now);
    return [
      Transaction(id: 't1', title: 'Salaire $monthLabel', amount: 340000, type: TxType.income, categoryId: 'salaire', date: d(12)),
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

  static const AiInsight insight = AiInsight(
    type: InsightType.conseil,
    content:
        'Vos dépenses shopping ont augmenté de 20% ce mois-ci. Réduire de 15 000 FCFA vous permettrait d\'atteindre votre objectif épargne 3 semaines plus tôt.',
  );
}
