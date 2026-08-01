# Milego Budget — App mobile Flutter

Application de gestion de finances personnelles avec assistante IA (« Léa »), basée sur le
cahier des charges `Milego_Budget_Cahier_des_charges_technique.md`.

**État actuel : MVP front (Phase 1 de la roadmap).** Thème bleu (carte solde sombre),
données mockées en mémoire. Pas encore de Firebase ni de microservice Python — l'assistante
Léa répond en local via des règles lisant le contexte financier (doublure du service IA).

## Stack

- Flutter 3.x · Material 3 personnalisé
- **Riverpod** (état) · **GoRouter** (navigation) · **fl_chart** (donut)
- **google_fonts** (Inter) · **flutter_animate** · **intl** (FCFA / dates fr)

## Écrans

| Écran | Fichier |
|---|---|
| Bilan (accueil) | `lib/features/bilan/bilan_screen.dart` |
| Transactions + ajout | `lib/features/transactions/` |
| Objectifs d'épargne | `lib/features/goals/goals_screen.dart` |
| Réglages (mode sombre, devise…) | `lib/features/settings/settings_screen.dart` |
| Chat assistante Léa | `lib/features/ai_assistant/chat_screen.dart` |

## Architecture

```
lib/
  core/        theme (couleurs, Material 3), router (GoRouter), utils (formatters FCFA)
  shared/      models, data (mock), providers (Riverpod), widgets (MilegoCard)
  features/    bilan · transactions · goals · settings · ai_assistant · shell
```

Le design system est dans `lib/core/theme/` : `AppColors` (palette bleue + hero sombre) et
`AppTheme` (thèmes clair/sombre + extension `context.milego`).

## Lancer

```bash
flutter pub get
flutter run                       # appareil / émulateur
flutter run -d chrome             # web
flutter test                      # tests
```

## Prochaines étapes (roadmap cahier des charges)

- Phase 2 : base locale **Isar** (persistance offline) + CRUD complet catégories/comptes.
- Phase 3 : **microservice Python (FastAPI)** — remplacer `lea_responder.dart` par un appel
  REST/WebSocket. Le contrat (`question + contexte → réponse`) est déjà isolé.
- Phase 4+ : **Firebase** (Auth, Firestore, FCM), LangChain/OpenAI, budgets détaillés, OCR.
