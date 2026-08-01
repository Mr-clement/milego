# Design : Persistance locale Isar (Transactions, Objectifs, Catégories)

Date : 2026-08-01
Statut : Approuvé (amélioré plus tard — cf. Hors scope)

## Contexte

Le MVP front garde toutes ses données en mémoire (`MockData` + `StateNotifier`
Riverpod), perdues à chaque redémarrage. Ce document couvre le passage à une
persistance locale réelle via **Isar** (Phase 2 de la roadmap README), pour
les transactions, les objectifs d'épargne et les catégories.

Décisions actées avec l'utilisateur :
- Périmètre : transactions + objectifs + catégories (les réglages —
  thème, nom — restent en mémoire pour l'instant).
- Architecture : notifiers Riverpod branchés directement sur Isar, pas de
  couches Repository/UseCase séparées (trop pour un MVP).
- Amorçage : au premier lancement (base vide), on seed avec les données de
  démo actuelles de `MockData`.
- Pas d'écran de gestion des catégories dans cette passe — amélioration
  future explicitement acceptée par l'utilisateur.

## 1. Dépendances

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1

dev_dependencies:
  isar_generator: ^3.1.0+1
  build_runner: ^2.4.0 # ou version compatible déjà résolue
```

Compatibilité vérifiée par `flutter pub add --dry-run` avec le Flutter/Dart
actuel du projet. Isar 3.1 liste Web (IndexedDB/WASM) parmi ses plateformes
supportées en plus de Windows/Android/iOS/macOS/Linux — donc le test de
l'app dans Chrome (`flutter run -d chrome`) continue de fonctionner. Point
d'attention : le tout premier lancement sur Web peut nécessiter une
connexion internet pour télécharger le moteur Isar (mis en cache par le
navigateur ensuite) — non bloquant pour l'usage normal mais à savoir si un
test est fait hors ligne.

## 2. Schéma Isar

Nouveau dossier `lib/core/services/isar/` :

```
lib/core/services/isar/
  isar_service.dart       (ouverture, seed, provider)
  category_entity.dart
  transaction_entity.dart
  goal_entity.dart
  icon_registry.dart
```

Les modèles UI existants (`Transaction`, `SavingGoal`, `Category` dans
`shared/models/models.dart`) ne changent pas. Chaque entité Isar a un mapper
`toDomain()` / `fromDomain()`.

### Id

Isar exige un `Id` (int). Les modèles métier gardent leur `id` `String`
existant (stable, déjà utilisé comme clé de référence — ex.
`Transaction.categoryId`). On dérive l'id Isar via l'idiome standard :

```dart
@Id()
int get isarId => fastHash(stringId);
```

`put()` fait donc un upsert naturel sur le même id métier — pas de double
système d'id à gérer côté appelant.

### Icônes — piège du tree-shaking

Flutter élague les glyphes de police d'icônes non référencés littéralement
au build release (`--tree-shake-icons`, actif par défaut). Reconstruire un
`IconData` depuis un `codePoint` entier stocké en base casserait donc
l'affichage en release. Solution :

- `IconRegistry` : `Map<String, IconData>` codé en dur avec toutes les
  icônes actuellement utilisées (`'home': Icons.home_rounded`, etc.).
- `CategoryEntity` stocke une **clé** (`String iconKey`), jamais l'icône
  brute. La couleur reste un simple `int` (`Color.value` / `Color(value)`),
  aucun problème de tree-shaking sur les couleurs.
- `GoalEntity` réutilise la palette déjà en place dans
  `app_providers.dart` (`_goalPalette`, icône+couleur par rotation) : on
  stocke seulement `paletteIndex` (int), résolu en icône/couleur à la
  lecture via la même constante compile-time.

### Collections

```dart
@collection
class CategoryEntity {
  @Id()
  int get isarId => fastHash(categoryId);
  late String categoryId;
  late String name;
  late String iconKey;   // clé IconRegistry
  late int colorValue;
}

@collection
class TransactionEntity {
  @Id()
  int get isarId => fastHash(txId);
  late String txId;
  late String title;
  late double amount;
  @enumerated
  late TxType type;
  late String categoryId;
  late DateTime date;
  String? note;
}

@collection
class GoalEntity {
  @Id()
  int get isarId => fastHash(goalId);
  late String goalId;
  late String name;
  late double targetAmount;
  late double currentAmount;
  late DateTime deadline;
  late int paletteIndex;
}
```

## 3. Initialisation & seed

Dans `main.dart`, avant `runApp` :

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final isar = await IsarService.open();
  final categories = await IsarService.loadCategories(isar); // seed si vide
  final transactions = await IsarService.loadTransactions(isar); // seed si vide
  final goals = await IsarService.loadGoals(isar); // seed si vide

  runApp(ProviderScope(
    overrides: [
      isarProvider.overrideWithValue(isar),
      categoriesProvider.overrideWithValue(categories),
      transactionsProvider.overrideWith((ref) => TransactionsNotifier(isar, transactions)),
      goalsProvider.overrideWith((ref) => GoalsNotifier(isar, goals)),
    ],
    child: const MilegoApp(),
  ));
}
```

Toutes les lectures initiales sont donc faites une seule fois, de façon
asynchrone, **avant** `runApp`. Conséquence importante : **aucun écran n'a
besoin de gérer un état de chargement (`AsyncValue`/spinner)** — les
providers restent synchrones du point de vue de l'UI, exactement comme
aujourd'hui avec `MockData`.

Le seed (première ouverture, collections vides) copie les listes actuelles
de `MockData` dans Isar puis les relit — même rendu qu'aujourd'hui au
premier lancement, mais désormais réellement persistant et modifiable.

## 4. Écriture (notifiers)

`TransactionsNotifier` et `GoalsNotifier` gardent leur API actuelle
(`add`/`update`/`remove`), toujours synchrones du point de vue de
l'appelant (les écrans/sheets ne changent pas) :

```dart
class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._isar, List<Transaction> initial) : super(initial);
  final Isar _isar;

  void add(Transaction tx) {
    state = [tx, ...state];
    unawaited(_isar.writeTxn(() => _isar.transactionEntitys.put(tx.toEntity())));
  }
  // update / remove suivent le même principe : état local mis à jour
  // immédiatement (écran réactif), écriture Isar en arrière-plan.
}
```

Pas de gestion d'erreur/retry sur l'écriture asynchrone (hors scope MVP —
écriture locale fiable). `categoriesProvider` reste un simple
`Provider<List<Category>>` en lecture seule (pas de notifier, puisqu'il n'y
a pas encore d'UI pour créer/éditer une catégorie — cf. Hors scope).

## 5. Sites d'appel à mettre à jour

Remplacer les usages directs de `MockData.categories` /
`MockData.categoryById` par `ref.watch(categoriesProvider)` :

- `lib/features/transactions/add_transaction_sheet.dart` (déjà
  `ConsumerStatefulWidget`, a `ref`)
- `lib/features/transactions/transactions_screen.dart` (`_TxTile` déjà
  `ConsumerWidget`, a `ref`)
- `lib/features/bilan/widgets/expense_breakdown_card.dart` : widget
  `StatelessWidget` sans `ref` → ajout d'un paramètre `categories:
  List<Category>` passé par `bilan_screen.dart` (qui, lui, est
  `ConsumerWidget`)
- `lib/features/ai_assistant/lea_responder.dart` : `LeaResponder.reply(...)`
  gagne un paramètre `categories: List<Category>`, fourni par
  `chat_screen.dart` via `ref.read(categoriesProvider)`

`MockData` (dans `shared/data/mock_data.dart`) n'est plus utilisé à
l'exécution normale — il devient uniquement les données de seed, appelées
depuis `IsarService` au premier lancement.

## 6. Tests

`test/widget_test.dart` ouvre actuellement l'app via `ProviderScope`
directement, sans Isar. À adapter : ouvrir une instance Isar dans un
répertoire temporaire (`Directory.systemTemp`, valide en environnement de
test VM) avant de construire le `ProviderScope` avec les mêmes overrides
que `main()`, pour que le test reste représentatif du bootstrap réel.

## Hors scope (amélioration future actée)

- Écran de gestion des catégories (créer/éditer/supprimer une catégorie,
  choisir icône/couleur) — la persistance est prête à l'accueillir plus
  tard (il suffira d'ajouter un `CategoriesNotifier` avec `add`/`update`/
  `remove`, même pattern que les deux autres entités).
- Gestion d'erreur/retry sur les écritures Isar.
- Synchronisation cloud (Firebase/Firestore — Phase 4 du cahier des
  charges), réglages (thème, devise, langue) persistés.
