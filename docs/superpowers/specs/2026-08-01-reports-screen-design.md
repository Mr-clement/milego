# Design : Écran « Rapports » (solde Total/Mensuel + répartition par période)

Date : 2026-08-01
Statut : Approuvé

## Contexte

Signalé par l'utilisateur : la carte « Solde restant ce mois » du Bilan ne
reflète que le budget mensuel (`budget − dépenses`), les revenus n'y entrent
jamais — ce n'est pas un bug, mais l'absence d'un **solde global** cumulé
dans le temps (le modèle `Account` du cahier des charges §6 n'a jamais été
implémenté). L'utilisateur a fourni une capture d'écran d'une autre app
comme référence de style (sélecteur « Total ▾ » en en-tête, onglets
DÉPENSES/REVENUS, période Jour/Semaine/Mois/Année avec donut par catégorie).

Décisions actées avec l'utilisateur :
- Solde total = somme de tous les revenus moins toutes les dépenses jamais
  enregistrés (pas de solde de départ configurable).
- Toute cette fonctionnalité (sélecteur + onglets + périodes) vit dans un
  **nouvel écran « Rapports »**, accessible depuis le Bilan — le Bilan et sa
  carte hero actuelle ne changent pas.
- Périodes : Jour / Semaine / Mois / Année uniquement pour cette passe (pas
  de plage de dates personnalisée — amélioration future).
- Réutilisation du style Milego (pas une copie de la capture de référence).

## 1. Nouveaux fichiers

```
lib/features/reports/
  reports_screen.dart   (écran, état local : période, ancre de date, vue,
                          type dépense/revenu)
  period_utils.dart     (PeriodType, PeriodRange, périodRangeFor,
                          shiftAnchor, PeriodSummary, summarizeForPeriod)
```

### `period_utils.dart`

```dart
enum PeriodType { day, week, month, year }

class PeriodRange {
  final DateTime start;  // inclus
  final DateTime end;    // exclu (début de la période suivante)
  final String label;    // ex: "Aujourd'hui, 1 août", "Août 2026", "2026"
}

PeriodRange periodRangeFor(PeriodType type, DateTime anchor);
DateTime shiftAnchor(PeriodType type, DateTime anchor, int direction); // -1/+1

class PeriodSummary {
  final double total;
  final List<MapEntry<String, double>> byCategory; // trié décroissant
}

PeriodSummary summarizeForPeriod(
  List<Transaction> txs,
  PeriodRange range,
  TxType type, // expense ou income
);
```

Semaine = lundi à dimanche. Le formatage des libellés (jour/mois/année)
utilise `package:intl` directement dans ce fichier (pas d'ajout à la classe
`Dates` partagée, ces formats sont spécifiques à cet écran).

## 2. Provider

Dans `app_providers.dart`, un seul ajout :

```dart
/// Solde cumulé (tous les revenus moins toutes les dépenses, tout
/// l'historique). Réutilise `Transaction.signedAmount`.
final globalBalanceProvider = Provider<double>((ref) {
  final txs = ref.watch(transactionsProvider);
  return txs.fold(0.0, (sum, t) => sum + t.signedAmount);
});
```

`monthSummaryProvider` existant ne change pas (toujours utilisé tel quel par
le Bilan).

## 3. Écran `ReportsScreen`

`ConsumerStatefulWidget`, état local (pas de provider global — préférences
d'affichage propres à cet écran, pas partagées ailleurs) :

```dart
BalanceView _view = BalanceView.monthly; // enum { monthly, total }
PeriodType _periodType = PeriodType.day;
DateTime _anchor = DateTime.now();
TxType _txType = TxType.expense; // ou income
```

**En-tête** : `PopupMenuButton<BalanceView>` — libellé cliquable
(« Ce mois ▾ » / « Total ▾ ») ouvrant un petit menu à 2 items, suivi du
montant correspondant en gros (`monthSummaryProvider.remaining` ou
`globalBalanceProvider`, selon `_view`).

**Onglets DÉPENSES / REVENUS** : deux boutons pilules (même style que
`_TypePill` de `AddTransactionSheet`, dupliqué localement — petit widget, pas
besoin de le partager entre fichiers) contrôlant `_txType`.

**Sélecteur de période** : 4 onglets texte (Jour/Semaine/Mois/Année) pour
`_periodType`, puis une ligne avec flèches précédent/suivant encadrant le
libellé de la période courante (`PeriodRange.label`), qui appellent
`shiftAnchor`.

**Corps** : `summarizeForPeriod(txs, range, _txType)` puis réutilisation
directe du widget existant `ExpenseBreakdownCard` (déjà générique :
`byCategory`/`total`/`categories`, aucune modification nécessaire) pour le
donut + légende. Si `byCategory` est vide, affichage d'un message à la place
de la carte (« Aucune dépense sur cette période » / « Aucun revenu sur
cette période » selon `_txType`), inspiré du « Il n'y a eu aucune dépense
aujourd'hui » de la référence.

## 4. Navigation

- `app_router.dart` : nouvelle route `/rapports`, `parentNavigatorKey:
  _rootKey` (route plein écran par-dessus le shell, comme `/chat`).
- `expense_breakdown_card.dart` : ajout d'un paramètre optionnel `onTap`
  (le widget `MilegoCard` interne le supporte déjà).
- `bilan_screen.dart` : passe `onTap: () => context.push('/rapports')` — le
  reste de l'écran Bilan est inchangé.

## Hors scope (rappel)

- Période personnalisée (plage de dates libre) — amélioration future.
- Solde de départ configurable.
- Comptes multiples nommés (le solde « Total » reste unique/global).
