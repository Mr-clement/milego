import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:milego_budget/core/router/app_router.dart';
import 'package:milego_budget/core/services/auth/auth_service.dart';
import 'package:milego_budget/core/services/isar/category_entity.dart';
import 'package:milego_budget/core/services/isar/goal_entity.dart';
import 'package:milego_budget/core/services/isar/isar_service.dart';
import 'package:milego_budget/core/services/isar/transaction_entity.dart';
import 'package:milego_budget/main.dart';
import 'package:milego_budget/shared/models/models.dart';
import 'package:milego_budget/shared/providers/app_providers.dart';

void main() {
  // `flutter test` s'exécute sur une VM hôte sans les vrais platform
  // channels : le plugin isar_flutter_libs ne peut pas y charger la lib
  // native automatiquement (Isar.open() reste bloqué indéfiniment). Il faut
  // l'initialiser explicitement — voir la doc Isar sur les tests Flutter.
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  testWidgets('Le Bilan affiche la salutation et le solde',
      (WidgetTester tester) async {
    await initializeDateFormatting('fr_FR', null);

    final dir = await Directory.systemTemp.createTemp('milego_test_isar');
    addTearDown(() => dir.delete(recursive: true));

    // Isar utilise de vraies opérations async natives (FFI) : elles doivent
    // s'exécuter hors de la fausse horloge de testWidgets (`runAsync`),
    // sinon `Isar.open` ne se résout jamais et le test expire.
    late Isar isar;
    late List<dynamic> loaded;
    await tester.runAsync(() async {
      isar = await Isar.open(
        [CategoryEntitySchema, TransactionEntitySchema, GoalEntitySchema],
        directory: dir.path,
        // L'Isar Inspector (actif par défaut en debug) ouvre un
        // ReceivePort qui reste bloqué indéfiniment sous le test harness.
        inspector: false,
      );
      loaded = [
        await IsarService.loadCategories(isar),
        await IsarService.loadTransactions(isar),
        await IsarService.loadGoals(isar),
      ];
    });
    addTearDown(isar.close);
    final categories = loaded[0] as List<Category>;
    final transactions = loaded[1] as List<Transaction>;
    final goals = loaded[2] as List<SavingGoal>;

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs);
    final router = buildAppRouter(initialLocation: '/bilan');

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authServiceProvider.overrideWithValue(authService),
        isarProvider.overrideWithValue(isar),
        categoriesProvider.overrideWithValue(categories),
        transactionsProvider
            .overrideWith((ref) => TransactionsNotifier(isar, transactions)),
        goalsProvider.overrideWith((ref) => GoalsNotifier(isar, goals)),
      ],
      child: MilegoApp(router: router),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Solde restant ce mois'), findsOneWidget);
  });
}
