# Design : Onboarding + Authentification locale

Date : 2026-08-03
Statut : Approuvé

## Contexte

L'app n'a ni écran d'accueil (onboarding) ni écran de connexion — elle démarre
directement sur le Bilan avec un nom d'utilisateur codé en dur
(`userNameProvider` = `'Clément'`). Ce document couvre l'ajout des deux, en
amont du Bilan.

Décisions actées avec l'utilisateur :
- Pas de Firebase pour l'instant (gros chantier séparé, bloqué sur la
  création d'un projet Firebase côté utilisateur) — **authentification
  locale simple** : compte stocké sur l'appareil, non sécurisé/non
  synchronisé, en attendant une vraie intégration future.
- Reste connecté entre les lancements (pas de re-login à chaque ouverture).
- Pas de réinitialisation de mot de passe (pas de service d'email en local
  — si oublié, aucune récupération possible). Non affiché dans l'UI.
- Onboarding : 3 écrans, images photographiques (fournies par l'utilisateur,
  6 au total) avec un dégradé bleu de la marque appliqué par-dessus pour la
  cohérence visuelle et la lisibilité du texte. **3 images tirées au hasard
  parmi les 6 à chaque affichage** de l'onboarding.

## 1. Assets

```
assets/onboarding/onboarding_pool_1.jpg … onboarding_pool_6.jpg
```

Déjà copiées dans le projet. `pubspec.yaml` : ajout d'une section
`assets: - assets/onboarding/`.

## 2. Nouvelles dépendances

```yaml
dependencies:
  shared_preferences: ^2.3.2   # flags légers : onboarding vu, session, compte local
  crypto: ^3.0.3                # hachage du mot de passe (SHA-256)
```

Isar reste dédié aux données financières (transactions/objectifs/
catégories) ; les flags de session sont trop simples pour justifier une
collection Isar dédiée — `shared_preferences` est l'outil standard pour ce
cas.

## 3. `AuthService` (`lib/core/services/auth/auth_service.dart`)

Wrapper simple autour de `SharedPreferences`, un seul compte local possible
(app mono-utilisateur) :

```dart
class AuthService {
  AuthService(this._prefs);
  final SharedPreferences _prefs;

  bool get hasSeenOnboarding => _prefs.getBool('onboarding_seen') ?? false;
  Future<void> markOnboardingSeen() => _prefs.setBool('onboarding_seen', true);

  bool get isLoggedIn => _prefs.getBool('is_logged_in') ?? false;
  String? get userName => _prefs.getString('user_name');

  Future<void> signUp({required String name, required String email, required String password});
  // stocke nom/email/hash(password), passe is_logged_in à true

  Future<bool> logIn({required String email, required String password});
  // compare au hash stocké ; retourne false si aucun compte ou si ça ne correspond pas

  Future<void> logOut(); // passe is_logged_in à false (le compte reste stocké)
}
```

Mot de passe haché via `crypto` (SHA-256) avant stockage — jamais en clair,
même localement.

`authServiceProvider` (Riverpod `Provider<AuthService>`), surchargé dans
`main()` comme `isarProvider`/`categoriesProvider` (même pattern déjà en
place).

## 4. Routing

`app_router.dart` : `appRouter` (constante statique) devient une fonction
`buildAppRouter({required String initialLocation})`, car la route de départ
dépend maintenant de l'état d'auth déterminé au runtime dans `main()`.

Nouvelles routes plein écran (même pattern que `/chat` et `/rapports`,
`parentNavigatorKey: _rootKey`) :

```
/onboarding  → OnboardingScreen
/login       → LoginScreen
/signup      → SignupScreen
```

`main()` calcule la route de départ avant `runApp` :

```dart
String initialLocation() {
  if (!authService.hasSeenOnboarding) return '/onboarding';
  if (!authService.isLoggedIn) return '/login';
  return '/bilan';
}
```

`MilegoApp` reçoit le `GoRouter` déjà construit (`required this.router`) au
lieu d'utiliser une constante globale — nécessaire pour le tester avec un
`initialLocation` fixe (voir section Tests).

`userNameProvider` est surchargé au démarrage avec `authService.userName`
(au lieu de `'Clément'` en dur) une fois connecté.

## 5. Écran Onboarding (`lib/features/onboarding/onboarding_screen.dart`)

`PageView` de 3 pages. Au `initState`, tirage aléatoire de 3 images parmi
les 6 du pool (`List.of(pool)..shuffle()`, puis `take(3)`) — fixé une fois
pour la durée de vie de l'écran, pas à chaque swipe.

Par page : image plein écran (`Image.asset`, `BoxFit.cover`) + dégradé
(`LinearGradient`, transparent en haut → `AppColors.primary` opaque en bas)
pour la lisibilité et la cohérence de marque quelle que soit la photo
tirée. Contenu texte (titre + description courte) positionné en bas via
`Align`. Contenu (fixe, associé par position 0/1/2, pas par image) :

1. « Suivez vos finances en un coup d'œil » — dépenses, revenus, budget du
   mois sur un seul écran.
2. « Léa, votre conseillère IA » — des conseils personnalisés basés sur vos
   vraies dépenses.
3. « Fixez vos objectifs d'épargne » — et suivez votre progression en temps
   réel.

Contrôles : « Passer » (haut droite, saute directement à la fin), points de
pagination (bas, centré), « Suivant » / « Commencer » (bas droite, dernier
écran). En fin de parcours (« Commencer » ou « Passer ») :
`authService.markOnboardingSeen()` puis `context.go('/signup')`.

## 6. Écrans Connexion / Inscription (`lib/features/auth/`)

Deux `Scaffold` pleine page (pas des bottom sheets, ce sont des routes
principales), style cohérent avec les champs déjà utilisés
(`AddTransactionSheet`/`AddGoalSheet` : `TextField` arrondi, fond
`c.surface`, bordure `c.border`).

**SignupScreen** : Nom, Email, Mot de passe, Confirmation. Validation :
nom non vide, email contient `@` et `.`, mot de passe ≥ 6 caractères,
confirmation identique. Bouton « Créer mon compte » →
`authService.signUp(...)`, met à jour `userNameProvider`,
`context.go('/bilan')`. Lien texte « Déjà un compte ? Se connecter » →
`context.go('/login')`.

**LoginScreen** : Email, Mot de passe. Bouton « Se connecter » →
`authService.logIn(...)` ; en cas d'échec, message inline « Email ou mot de
passe incorrect » (pas de distinction précise entre les deux, pour ne pas
révéler si un email est enregistré). En cas de succès : met à jour
`userNameProvider`, `context.go('/bilan')`. Lien texte « Pas de compte ?
S'inscrire » → `context.go('/signup')`.

## 7. Réglages — Déconnexion

Nouvelle entrée dans `SettingsScreen` (remplace/complète les tuiles
existantes) : « Déconnexion », avec confirmation (réutilise
`confirm_delete_dialog.dart`-style ou une simple `AlertDialog`), puis
`authService.logOut()` et `context.go('/login')`. Les données financières
(transactions/objectifs/catégories dans Isar) ne sont pas supprimées — se
déconnecter ne réinitialise pas l'app, juste la session.

## 8. Tests

`test/widget_test.dart` doit :
- Construire un `AuthService` de test avec
  `SharedPreferences.setMockInitialValues({})` (mock standard du package).
- Construire `MilegoApp` avec un routeur dont `initialLocation: '/bilan'`
  explicite, pour continuer à tester le Bilan directement sans passer par
  onboarding/login à chaque run de test.

## Hors scope (rappel)

- Firebase Auth (chantier séparé, bloqué sur la création du projet côté
  utilisateur).
- Réinitialisation de mot de passe.
- Comptes multiples / changement de compte.
- Compression des images d'onboarding (certaines >2 Mo — acceptable pour
  un MVP, à optimiser plus tard si la taille de l'app pose problème).
