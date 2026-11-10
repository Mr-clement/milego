import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/services/auth/auth_service.dart';
import 'core/services/isar/isar_service.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  final prefs = await SharedPreferences.getInstance();
  final authService = AuthService(prefs);

  final isar = await IsarService.open();
  final categories = await IsarService.loadCategories(isar);
  final transactions = await IsarService.loadTransactions(isar);
  final goals = await IsarService.loadGoals(isar);

  final router = buildAppRouter(initialLocation: _initialLocation(authService));

  runApp(ProviderScope(
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
}

String _initialLocation(AuthService auth) {
  if (!auth.hasSeenOnboarding) return '/onboarding';
  if (!auth.isLoggedIn) return '/login';
  return '/bilan';
}

class MilegoApp extends ConsumerWidget {
  const MilegoApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Milego Budget',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
