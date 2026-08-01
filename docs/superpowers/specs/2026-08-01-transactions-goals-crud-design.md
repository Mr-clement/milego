# Design : CRUD Transactions & Objectifs (polish MVP front)

Date : 2026-08-01
Statut : Approuvé

## Contexte

Le MVP front (Phase 1 de la roadmap, données mockées en mémoire) manque de
CRUD complet sur deux écrans :

- **Transactions** : création OK, mais aucune suppression ni modification
  possible depuis l'UI (`TransactionsNotifier.remove` existe déjà côté
  provider mais n'est appelé nulle part ; le tap sur une carte ne fait rien).
- **Objectifs** : écran strictement en lecture seule (`goalsProvider` est un
  `Provider` statique sur `MockData.goals()`), aucun ajout/suppression
  possible.

Ce document couvre uniquement ce polish. Restent hors périmètre (décision
utilisateur) : réglages fonctionnels (devise/langue/export), modification
d'un objectif existant, écran de détail séparé pour les transactions.

## 1. Transactions

### Provider

`TransactionsNotifier` (`lib/shared/providers/app_providers.dart`) gagne :

```dart
void update(Transaction tx) =>
    state = [for (final t in state) t.id == tx.id ? tx : t];
```

`remove(String id)` existe déjà et sera câblé à l'UI.

### UI — `AddTransactionSheet`

Devient réutilisable pour ajout et édition via un paramètre optionnel :

```dart
const AddTransactionSheet({super.key, this.existing});
final Transaction? existing;
```

- Si `existing != null` : les champs (`_title`, `_amount`, `_type`,
  `_categoryId`) sont initialisés depuis la transaction dans `initState`.
- Titre de la feuille : "Modifier la transaction" au lieu de "Nouvelle
  transaction".
- `_save()` : si `existing != null`, construit une nouvelle `Transaction`
  avec le même `id`/`date` d'origine et appelle
  `ref.read(transactionsProvider.notifier).update(...)` ; sinon comportement
  actuel (`add`).
- Un bouton texte "Supprimer" (rouge, `TextButton`) apparaît sous le bouton
  "Enregistrer" uniquement en mode édition ; il ferme la feuille et supprime
  via `transactionsProvider.notifier.remove(existing.id)`.

### UI — `TransactionsScreen`

- `_TxTile.onTap` (actuellement `() {}`) ouvre
  `showModalBottomSheet(... AddTransactionSheet(existing: tx))`.
- Chaque `_TxTile` est enveloppé dans un `Dismissible` :
  - `key: ValueKey(tx.id)`
  - `direction: DismissDirection.endToStart`
  - fond rouge avec icône poubelle affiché pendant le swipe
  - `confirmDismiss` : ouvre un `AlertDialog` ("Supprimer cette
    transaction ?" / Annuler / Supprimer) et retourne le choix utilisateur
  - `onDismissed` : `ref.read(transactionsProvider.notifier).remove(tx.id)`

## 2. Objectifs

### Provider

`goalsProvider` passe de :

```dart
final goalsProvider = Provider<List<SavingGoal>>((ref) => MockData.goals());
```

à un `StateNotifierProvider` avec un nouveau `GoalsNotifier` :

```dart
class GoalsNotifier extends StateNotifier<List<SavingGoal>> {
  GoalsNotifier() : super(MockData.goals());

  void add(SavingGoal goal) => state = [...state, goal];
  void remove(String id) => state = state.where((g) => g.id != id).toList();
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<SavingGoal>>(
        (ref) => GoalsNotifier());
```

Tous les usages existants (`ref.watch(goalsProvider)` en lecture) restent
compatibles sans changement d'appel.

### Icône / couleur automatiques

Pas de sélecteur en v1 (YAGNI). Une petite palette fixe (réutilisant les
couleurs déjà présentes dans `MockData.goals()` : `AppColors.primary`,
`Color(0xFF6D82FF)`, `Color(0xFF16B364)`, plus 1-2 teintes du donut existant)
et une icône générique (`Icons.savings_rounded`) sont assignées par rotation
sur `state.length % palette.length` au moment de la création.

### UI — nouvel écran `AddGoalSheet` (`lib/features/goals/add_goal_sheet.dart`)

Même structure visuelle que `AddTransactionSheet` (bottom sheet, poignée,
champs stylés `c.surface`/`c.border`) :

- Champ texte : nom de l'objectif
- Champ numérique : montant cible (FCFA)
- Champ numérique optionnel : montant actuel (défaut 0 si vide)
- Sélecteur de date : `showDatePicker` pour l'échéance (`deadline`),
  bouton affichant la date choisie (format `Dates.dayMonth` ou équivalent)
- Bouton "Enregistrer" : valide (nom non vide, montant cible > 0,
  échéance renseignée), construit un `SavingGoal` avec id généré
  (`'g${DateTime.now().microsecondsSinceEpoch}'`), icône/couleur par
  rotation, puis `ref.read(goalsProvider.notifier).add(...)` et ferme la
  feuille.

### UI — `GoalsScreen`

- Ajout d'un en-tête avec bouton "Ajouter" (`FilledButton.icon`, même style
  que celui de `TransactionsScreen`) qui ouvre `AddGoalSheet` en modal.
- Chaque `_GoalCard` enveloppée dans un `Dismissible` (même pattern que les
  transactions : swipe `endToStart`, fond rouge, `confirmDismiss` avec
  `AlertDialog` de confirmation, `onDismissed` appelle
  `goalsProvider.notifier.remove(goal.id)`).
- Si `goals.isEmpty` après suppression : afficher un état vide simple
  ("Aucun objectif pour l'instant" + éventuellement le bouton d'ajout mis en
  avant), cohérent avec le pattern déjà utilisé sur l'écran Transactions.

## Tests

- Étendre/adapter `test/widget_test.dart` si besoin (le test existant ne
  touche pas ces écrans, donc pas de régression attendue) ; pas de nouveaux
  tests automatisés obligatoires pour ce polish MVP front — validation
  manuelle via `flutter run` suffisante vu le périmètre.

## Hors scope (rappel)

- Réglages fonctionnels (devise, langue, export/import)
- Modification d'un objectif existant
- Écran de détail séparé pour une transaction
