# Reprise du projet Milego Budget

Dernière mise à jour : 10/11/2026 · Branche : `optimisations`, issue de `dev`

## 1. Où en est le projet

### Déjà fait sur cette branche
- **Performance et taille :**
  - images d'onboarding converties en WebP (9,5 Mo → 1 Mo) et décodées à la taille de l'écran (`cacheHeight`) ;
  - recherche de catégorie en O(1) (`byId`, mis en cache par liste) ;
  - animation de la liste des transactions jouée uniquement au premier affichage ;
  - `toLowerCase()` sorti de la boucle de recherche.
- **Bugs corrigés :**
  - transactions triées de la plus récente à la plus ancienne après un redémarrage ;
  - repli explicite sur la catégorie « Autres » pour un id inconnu ;
  - ligne « Autres » en double dans la légende du graphique ;
  - double envoi possible dans le chat ;
  - titre de carte « dépenses » affiché aussi pour les revenus dans Rapports.
- **Robustesse :** les erreurs d'écriture Isar sont signalées (`_persist`) au lieu d'être perdues.
- **Sécurité :**
  - la clé Gemini passe dans un en-tête HTTP au lieu de l'URL, et l'historique envoyé est limité à 10 messages ;
  - mots de passe hachés en PBKDF2 avec sel, et anciens comptes convertis à la connexion ;
  - l'inscription ne peut plus écraser le compte existant.
- **Préférences :** le thème est persisté, et le prénom n'est plus codé en dur.
- **Maintenabilité :**
  - `InputDecorationTheme` commun pour tous les champs ;
  - widgets partagés `MilegoTextField` et `TypePill` ;
  - `isar.dll` et `android/build/` retirés du suivi git ;
  - maquettes déplacées dans `docs/design/`.
- **Tests :** `test/period_utils_test.dart`, `test/domain_test.dart`, `test/auth_service_test.dart`.
- **Documentation :** cahier des charges de publication sur les stores, version 1.1 → [Milego_Budget_CdC_Publication_Stores.md](Milego_Budget_CdC_Publication_Stores.md).

### ⚠️ Rien n'a été compilé ni testé
Le SDK Flutter n'était pas installé sur la machine. Seule la logique PBKDF2 a été vérifiée, sur un portage Python comparé à `hashlib`.

## 2. À lancer en premier à la reprise
```bash
git switch optimisations && git pull
cp lib/core/config/env.example.dart lib/core/config/env.dart   # obligatoire : sans ce fichier (ignoré par git), le projet ne compile pas
flutter pub get
flutter analyze
flutter test
```
Corriger les éventuelles erreurs avant d'aller plus loin. Ensuite, fusionner `optimisations` dans `dev` via une PR.

## 3. Décisions d'architecture

| # | Sujet | Statut | Choix |
|---|---|---|---|
| D1 | Comptes | ✅ Validée | Firebase Auth (compte anonyme au premier lancement, puis liaison à un compte email, Google ou Apple) et synchronisation Firestore. Le compte local actuel (`AuthService`) sera abandonné. |
| D2 | IA (Léa) | ✅ Validée | Cloud Function Firebase servant d'intermédiaire vers Gemini (clé côté serveur, App Check, quota par utilisateur). Nécessite le plan Blaze. |
| D3 | Base locale | ✅ Validée | Firestore seul, avec son cache hors ligne. Isar sera retiré. |
| D4 | Marchés | ✅ Validée | Zone FCFA et international : français et anglais, devise au choix, RGPD et lois locales, données Firestore en région UE. |
| D5 | Identifiant de l'app | ❓ Ouverte | Il doit être identique sur Android et iOS, par exemple `com.milego.budget`. Il est **définitif** une fois publié. |
| D6 | Compte développeur Play | ❓ Ouverte | Compte « Organisation » (numéro D-U-N-S) recommandé, pour éviter le test fermé de 12 testeurs pendant 14 jours. |

## 4. Prérequis avant le lot 1
- [ ] Installer le SDK Flutter.
- [ ] Trancher D5 et D6.
- [ ] Créer les projets Firebase `milego-dev` et `milego-prod` (Firestore en région UE, par exemple `eur3`).
- [ ] Lancer `flutterfire configure` pour chaque variante (nécessite votre compte Google).
- [ ] Passer le projet prod au plan Blaze et y mettre une alerte de budget.

## 5. Prochaine étape : lot 1 « Socle Firebase »
Voir le [cahier des charges, §9](Milego_Budget_CdC_Publication_Stores.md). Exigences concernées : TEC-01 (remplacer Isar par Firestore), TEC-08 (règles de sécurité Firestore et leurs tests), TEC-03 et TEC-04 (variantes et configuration), QUA-01 et QUA-04 (CI et lints), PUB-02 (permission INTERNET), PUB-03 (identifiant de l'app).

**Correction en une ligne, à faire en premier (PUB-02) :** ajouter `<uses-permission android:name="android.permission.INTERNET"/>` dans `android/app/src/main/AndroidManifest.xml`. Sans elle, Léa ne fonctionne pas en release.
