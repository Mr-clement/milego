import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/ai_assistant/chat_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/bilan/bilan_screen.dart';
import '../../features/goals/goals_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/reports/reports_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/transactions/transactions_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

/// Navigation GoRouter : bottom nav à 4 branches + routes plein écran
/// (onboarding, auth, chat, rapports). `initialLocation` dépend de l'état
/// d'auth déterminé au runtime dans `main()` (onboarding vu ? connecté ?).
GoRouter buildAppRouter({required String initialLocation}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bilan',
              builder: (context, state) => const BilanScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/transactions',
              builder: (context, state) => const TransactionsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/objectifs',
              builder: (context, state) => const GoalsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/reglages',
              builder: (context, state) => const SettingsScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/rapports',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ReportsScreen(),
      ),
    ],
  );
}
