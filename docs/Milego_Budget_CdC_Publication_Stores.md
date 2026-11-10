# Cahier des charges technique
## Projet : Milego Budget : publication Play Store et App Store (v1.0 publique)

Version 1.1 · 10/11/2026 (décisions D1 à D4 validées) · Complète `Milego_Budget_Cahier_des_charges_technique.md`, appelé ci-dessous **CdC initial**.

---

## 1. Présentation

### 1.1 Objectif
Faire passer Milego Budget du MVP mono-appareil actuel (branche `optimisations`) à une **v1.0 publiable sur Google Play et l'App Store** et utilisable par un public large : plusieurs pays, plusieurs langues, utilisateurs non techniques.

### 1.2 Point de départ (état constaté du code)
- Application Flutter : Riverpod, GoRouter, base locale Isar (fork `isar_community` 3.3.2).
- Compte **local** : email et mot de passe haché avec PBKDF2, stockés dans SharedPreferences.
- Assistante Léa : appel **direct** à Gemini depuis le téléphone, avec la clé embarquée dans l'app (`env.dart`).
- Aucun backend, aucune synchronisation, aucune sauvegarde. Cible retenue : Firebase (Auth, Firestore, Cloud Functions), voir §2.
- Français et FCFA uniquement. Budget mensuel fixé dans le code (270 000).
- Configuration de publication : celle générée par défaut à la création du projet Flutter (clé de debug, icônes Flutter, nom technique `milego_budget`).

### 1.3 Périmètre
| Inclus | Exclu (voir CdC initial §14) |
|---|---|
| Conformité aux règles des stores, sécurité, données personnelles | Open Banking, OCR des reçus |
| Comptes et synchronisation cloud, backend IA | Budget familial partagé, version web |
| Plusieurs langues et devises, fonctions de base manquantes | Abonnements Premium (prévoir seulement les points d'extension) |
| Qualité, intégration continue, fiches des stores, publication | |

### 1.4 Conventions
- **ID** : `PUB` = publication, `SEC` = sécurité et données personnelles, `FON` = fonctionnel, `I18N` = langues et devises, `TEC` = socle technique, `QUA` = qualité.
- **Priorité** : **P0** = bloquant pour la soumission, **P1** = requis pour la v1.0, **P2** = souhaitable.
- Chaque exigence a un critère d'acceptation (CA) vérifiable.

---

## 2. Décisions d'architecture

| # | Décision | Statut | Choix retenu | Conséquences |
|---|---|---|---|---|
| D1 | Modèle de compte | **Validée** | **Firebase Auth** (anonyme au premier lancement, puis email, Google et Apple) avec synchronisation **Firestore** | Le compte local (`AuthService`, SharedPreferences) est abandonné. L'utilisateur peut commencer sans s'inscrire (compte anonyme), puis lier un vrai compte pour ne pas perdre ses données. |
| D2 | Accès à l'IA | **Validée** | **Cloud Function Firebase** (2e génération) servant d'intermédiaire vers Gemini, protégée par l'authentification et App Check | Il faut passer au plan Firebase **Blaze** (paiement à l'usage) avec une alerte de budget. Le microservice Python du CdC initial §3.2 est reporté. |
| D3 | Base locale | **Validée** | **Firestore seul** : son cache hors ligne sert de base locale ; Isar est retiré | Plus de migration Isar ni de drift. L'exigence 16 Ko ne porte plus que sur les autres plugins natifs. Il n'y a pas de chiffrement applicatif du cache (voir SEC-06). |
| D4 | Marchés visés pour la v1.0 | **Validée** | **Zone FCFA** (UEMOA et CEMAC) et **international** | Français et anglais obligatoires, devise au choix de l'utilisateur. Cadre légal : lois locales (ARTCI, CDP…) **et** RGPD, puisque l'international inclut l'UE. |
| D5 | Identité de l'app | À valider | Un identifiant unique sur les deux plateformes, par exemple `com.milego.budget` | Il ne peut plus être changé après la première publication. |
| D6 | Compte développeur Play | À valider | Compte **Organisation** (nécessite un numéro D-U-N-S) | Évite le test fermé obligatoire (12 testeurs pendant 14 jours) imposé aux nouveaux comptes personnels. |

---

## 3. Exigences de publication (PUB)

| ID | P | Exigence | Fichiers concernés | Critère d'acceptation |
|---|---|---|---|---|
| PUB-01 | P0 | Signer la release avec une vraie clé : clé d'upload, `key.properties` ignoré par git, Play App Signing ; côté iOS : Team, certificats et profils | `android/app/build.gradle.kts`, `project.pbxproj` | `flutter build appbundle` produit un AAB **non** signé avec la clé de debug, et la Play Console l'accepte. |
| PUB-02 | P0 | Ajouter la permission `INTERNET` dans le manifeste **principal** (elle n'existe aujourd'hui qu'en debug et en profile) | `android/app/src/main/AndroidManifest.xml` | En build release sur un vrai appareil, Léa répond via le réseau et non avec les réponses locales de secours. |
| PUB-03 | P0 | Identifiant d'application commun sur Android et iOS (D5) | `build.gradle.kts`, `project.pbxproj` | Le même identifiant apparaît sur les deux plateformes. |
| PUB-04 | P0 | Nom affiché « Milego Budget », icône définitive et écran de démarrage (`flutter_launcher_icons`, `flutter_native_splash`) | `AndroidManifest` (`android:label`), `Info.plist`, `pubspec.yaml` | Plus aucune icône Flutter par défaut, plus de libellé `milego_budget`. |
| PUB-05 | P0 | iPhone uniquement et portrait uniquement en v1.0 (`TARGETED_DEVICE_FAMILY = 1`) | `project.pbxproj`, `Info.plist`, `main.dart` | Pas d'exigence de captures iPad, et pas de rotation de l'écran. |
| PUB-06 | P0 | Ajouter le manifeste de confidentialité iOS `PrivacyInfo.xcprivacy` (motifs d'usage de UserDefaults et des autres API concernées) | `ios/Runner/` | La validation par Xcode et App Store Connect ne signale aucun avertissement. |
| PUB-07 | P0 | Bibliothèques natives alignées sur des pages de 16 Ko, targetSdk au niveau exigé par Play, SDK Xcode au niveau exigé par Apple | dépendances, version de Flutter | `zipalign -c -P 16` passe sur tous les fichiers `.so` de l'AAB, et le rapport de pré-lancement Play ne signale rien. |
| PUB-08 | P1 | Version lue dynamiquement (`package_info_plus`) au lieu de « v1.0.0 (MVP) » en dur | `settings_screen.dart` | Les Réglages affichent la version et le numéro de build de `pubspec.yaml`. |
| PUB-09 | P1 | Fiches des stores : captures d'écran du téléphone, bannière Play 1024×500, descriptions FR et EN, classification du contenu, public cible adulte | Play Console, App Store Connect | Les deux fiches sont complètes et validées. |
| PUB-10 | P1 | Phase de test : piste de test fermé Play (12 testeurs pendant 14 jours si compte personnel) et TestFlight | — | Les tests ont eu lieu sans plantage bloquant. |

---

## 4. Sécurité et données personnelles (SEC)

| ID | P | Exigence | Critère d'acceptation |
|---|---|---|---|
| SEC-01 | P0 | **Retirer la clé Gemini de l'app** : Léa appelle une Cloud Function (`callable`, D2) qui vérifie le jeton Firebase et App Check, détient la clé (stockée dans Secret Manager), limite les appels (par exemple 30 par utilisateur et par jour, compteur Firestore) et utilise l'offre payante de Gemini. | Aucune clé `AIza…` dans l'AAB ou l'IPA (vérifié avec `strings`), et un appel sans jeton valide ou sans App Check est refusé. |
| SEC-02 | P0 | **Consentement avant tout envoi à l'IA**, demandé au premier usage de Léa : quelles données partent, vers qui, dans quel but. Possibilité de refuser (réponses locales `LeaResponder` seulement) et de retirer son accord dans les Réglages. | Aucune requête vers l'IA tant que l'utilisateur n'a pas accepté (vérifié dans les journaux réseau). |
| SEC-03 | P0 | **Limiter les données envoyées à l'IA** (CdC initial §10) : chiffres agrégés seulement, sans nom, email ni libellés libres de transactions. | Le contexte envoyé (`_systemPrompt`) ne contient aucune donnée identifiante. |
| SEC-04 | P0 | **Politique de confidentialité** hébergée, liée depuis l'app et les fiches des stores. Remplir la section « Sécurité des données » de Play et les étiquettes de confidentialité Apple, en déclarant les données financières, l'identité, la transmission au fournisseur d'IA et le suivi des plantages. | L'URL est accessible publiquement, et les déclarations correspondent à ce que l'app fait réellement. |
| SEC-05 | P0 | **Suppression du compte** depuis l'app (Réglages) : suppression du compte Firebase et de toutes les données `users/{uid}` (via Cloud Function, pour supprimer aussi les sous-collections), vidage du cache local, puis retour à l'onboarding. Fournir aussi une page web de demande de suppression (exigée par Play). | Après suppression, une reconnexion avec le même compte ne trouve plus aucune donnée. |
| SEC-06 | P1 | Protection locale : verrouillage optionnel par code ou biométrie (`local_auth`). Le cache Firestore n'est pas chiffré par l'app (D3) : on s'appuie sur le bac à sable et le chiffrement de l'OS, ce que la politique de confidentialité indique. | Le verrouillage s'active au retour dans l'app quand l'option est choisie. |
| SEC-07 | P1 | Sauvegardes du système maîtrisées : `dataExtractionRules` et `allowBackup` sur Android, exclusion de la sauvegarde iCloud sur iOS. Les données de l'utilisateur sont sauvegardées par Firestore, pas par l'OS. | La base locale n'apparaît pas dans une sauvegarde `adb backup` ou iCloud. |
| SEC-08 | P1 | Avertissement « information générale, pas un conseil financier professionnel », affiché dans le chat et dans les CGU | La mention est visible dès la première ouverture de Léa. |
| SEC-09 | P1 | CGU et mentions légales. Conformité **RGPD** (registre des traitements, base légale, droits d'accès et d'effacement, sous-traitants : Google Firebase et Gemini) et lois de la zone FCFA (ARTCI en Côte d'Ivoire, CDP au Sénégal…). Données Firestore hébergées dans une région européenne (par exemple `eur3`). | Documents publiés et acceptés à l'inscription, région Firestore en UE. |
| SEC-10 | P1 | Hygiène du dépôt : retirer `LIVE_IN_BLACK_*.pdf`, passer le dépôt en privé ou vérifier qu'il ne contient rien de sensible, garder les secrets hors du code (SEC-01, TEC-04) | Un scan de secrets (`gitleaks`) sur tout l'historique ne trouve rien. |

---

## 5. Exigences fonctionnelles (FON)

| ID | P | Exigence | Critère d'acceptation |
|---|---|---|---|
| FON-01 | P0 | **Supprimer les données de démonstration** : base vide au premier lancement, écrans vides accueillants avec une incitation à agir. Conseil de Léa calculé à partir des vraies données (remplace `insightProvider` et `MockData`). | Un compte neuf n'affiche aucune transaction ni aucun objectif fictif. |
| FON-02 | P0 | **Pas de fonction factice** : Devise, Langue, Export/Import et Sauvegarde cloud sont implémentées (I18N, FON-05, D1) ou retirées. | Chaque entrée des Réglages a un effet réel. |
| FON-03 | P1 | Authentification Firebase (D1) : compte **anonyme** au premier lancement, puis liaison à un compte email, Google ou **Sign in with Apple** (obligatoire sur iOS dès qu'un autre fournisseur de connexion tiers est proposé), avec mot de passe oublié. Inviter l'utilisateur à lier son compte après quelques saisies. | L'app fonctionne sans inscription, et après liaison les données se retrouvent sur un deuxième appareil. |
| FON-04 | P1 | Hors ligne d'abord avec le cache natif de Firestore (D3) : les écritures sont locales et immédiates, la synchronisation se fait au retour du réseau. L'interface ne dépend pas de la réponse du serveur. | Une saisie faite en mode avion apparaît sur l'autre appareil après reconnexion. |
| FON-05 | P1 | Export CSV et JSON des transactions et objectifs (feuille de partage du système) | Le fichier exporté peut être réimporté sans perte. |
| FON-06 | P1 | Budget mensuel modifiable par l'utilisateur (remplace `MockData.monthlyBudget`) | Le Bilan reflète le budget saisi. |
| FON-07 | P1 | Date de la transaction modifiable (aujourd'hui elle vaut toujours `DateTime.now()`) | Une dépense saisie avec la date de la veille apparaît à la bonne date dans les Rapports. |
| FON-08 | P1 | Objectifs : modifier un objectif et lui ajouter un versement | Le pourcentage de progression se met à jour. |
| FON-09 | P2 | Catégories personnalisées (créer, renommer, choisir icône et couleur parmi `IconRegistry` et `GoalPalette`) | Une catégorie créée est utilisable dans une transaction. |
| FON-10 | P2 | Notifications locales (CdC initial §11) : budget dépassé, objectif atteint, rappel de fin de mois. Permission demandée au moment où elle sert. | La notification arrive quand le seuil est franchi. |

---

## 6. Langues et devises (I18N)

| ID | P | Exigence | Critère d'acceptation |
|---|---|---|---|
| I18N-01 | P0 | Configurer `flutter_localizations` (`localizationsDelegates` et `supportedLocales` dans `MaterialApp`). Aujourd'hui le sélecteur de date s'affiche en anglais. | Le sélecteur de date et les boîtes de dialogue système suivent la langue de l'app. |
| I18N-02 | P1 | Sortir tous les textes du code vers des fichiers ARB, en français et en anglais | `grep` ne trouve plus aucun texte affiché en dur dans `lib/features`. |
| I18N-03 | P1 | Devise choisie par l'utilisateur (XOF et XAF par défaut selon le pays, plus la liste ISO 4217), stockée sur son profil. `Money` paramétré par devise et pays (décimales, symbole, position). Les montants sont stockés en **unités mineures entières** (`int`). | Le passage du XOF à l'EUR change l'affichage partout, sans erreur d'arrondi. |
| I18N-04 | P2 | Le prompt de Léa et les réponses locales de `LeaResponder` suivent la langue de l'utilisateur | Une question posée en anglais reçoit une réponse en anglais. |

---

## 7. Socle technique (TEC)

| ID | P | Exigence | Critère d'acceptation |
|---|---|---|---|
| TEC-01 | P0 | **Remplacer Isar par Firestore** (D3) : modèle `users/{uid}/transactions`, `goals`, `categories` et `settings` ; couche d'accès aux données (repositories) entre Firestore et les providers ; suppression de `isar_community`, de `IsarService` et des fichiers `*.g.dart`. | `isar_community` est retiré de `pubspec.yaml`, et toutes les fonctions marchent en mode avion. |
| TEC-08 | P0 | **Règles de sécurité Firestore** : chaque utilisateur ne lit et n'écrit que dans `users/{uid}`, avec validation des types et des montants. Les règles sont testées avec l'émulateur Firebase en CI. | Les tests d'émulateur prouvent qu'un utilisateur A ne peut ni lire ni écrire chez un utilisateur B. |
| TEC-02 | P1 | Riverpod : passer de `StateNotifier`/`StateProvider` à `Notifier`/`AsyncNotifier`. Le chargement initial se fait dans les providers, avec un écran de démarrage, au lieu d'être fait dans `main()` puis injecté. | Aucune API historique de Riverpod n'est utilisée, et le démarrage dure moins de 2 s (CdC initial §12). |
| TEC-03 | P1 | Variantes `dev` et `prod` : identifiant, nom affiché et **projet Firebase** distincts (`flutterfire configure` par variante) | Les deux variantes peuvent être installées côte à côte sur un même appareil, sans données partagées. |
| TEC-04 | P1 | Configuration via `--dart-define-from-file` au lieu de `env.dart` (le projet ne compile pas sur un clone neuf sans ce fichier) | `flutter build` fonctionne sur un clone neuf, avec seulement le fichier de configuration de l'environnement. |
| TEC-05 | P1 | Suivi des plantages (Crashlytics ou Sentry) et éventuellement des statistiques d'usage, désactivables, déclarés dans SEC-04 | Un plantage provoqué volontairement remonte dans la console. |
| TEC-06 | P2 | Pagination et chargement progressif de la liste des transactions (CdC initial §12) | Pas de saccade (jank) avec 5 000 transactions. |
| TEC-07 | P2 | Police Inter embarquée (plus de téléchargement au premier lancement) | Le premier lancement hors ligne affiche bien Inter. |

---

## 8. Qualité (QUA)

| ID | P | Exigence | Critère d'acceptation |
|---|---|---|---|
| QUA-01 | P0 | Intégration continue (GitHub Actions) : `flutter analyze --fatal-infos`, `flutter test` et builds Android et iOS à chaque PR | La CI est au vert, et une PR qui casse le build ne peut pas être fusionnée. |
| QUA-02 | P1 | Tests : couverture d'au moins 70 % de la logique métier (providers, utilitaires, repositories), tests de widgets des écrans clés, un test d'intégration du parcours inscription → saisie → Bilan | Rapport de couverture publié par la CI. |
| QUA-03 | P1 | Accessibilité : libellés pour les lecteurs d'écran (boutons ronds, onglets de période), zones cliquables d'au moins 48 dp, contrastes conformes au niveau AA, mise en page correcte avec des polices agrandies à 200 % | Contrôle avec TalkBack et VoiceOver sans élément muet ou inaccessible. |
| QUA-04 | P1 | Lints renforcés dans `analysis_options.yaml` (`unawaited_futures`, `prefer_const_constructors`, `avoid_dynamic_calls`, `directives_ordering`) | Zéro avertissement. |
| QUA-05 | P1 | Build et envoi automatisés (fastlane ou Codemagic) vers la piste de test interne Play et TestFlight | Un tag Git `v*` publie une version de test sans aucune intervention manuelle. |

---

## 9. Découpage en lots

| Lot | Contenu | Exigences | Sortie |
|---|---|---|---|
| 0 | Décisions et comptes | D1 à D6, comptes Play, Apple et Firebase, choix du nom | Décisions validées |
| 1 | Socle Firebase | TEC-01, TEC-08, TEC-03, TEC-04, QUA-01, QUA-04, PUB-02, PUB-03 | Projets Firebase dev et prod, données dans Firestore, règles testées, CI au vert |
| 2 | Comptes | FON-03, FON-04, SEC-05, SEC-06, SEC-07 | Compte anonyme puis liaison, mode hors ligne, suppression de compte |
| 3 | IA (Cloud Function) | SEC-01, SEC-02, SEC-03, SEC-08, I18N-04 | Léa passe par la Cloud Function, avec consentement et quota |
| 4 | Produit | FON-01, FON-02, FON-05 à FON-08, I18N-01 à I18N-03 | Produit complet en FR et EN, plusieurs devises |
| 5 | Publication | PUB-01, PUB-04 à PUB-10, SEC-04, SEC-09, SEC-10, TEC-05, QUA-02, QUA-03, QUA-05 | Test fermé, puis production |
| Après la v1.0 | Améliorations | FON-09, FON-10, TEC-02, TEC-06, TEC-07 | — |

---

## 10. Recette finale (avant soumission en production)
1. Installer depuis la piste de test Play et TestFlight sur un appareil neuf, sans données.
2. Parcours complet : onboarding → inscription → consentement IA → saisie hors ligne → synchronisation → export → suppression du compte.
3. Vérifier qu'aucun secret n'est présent dans les binaires (`strings`, `gitleaks`) et que le contrôle 16 Ko passe.
4. Rapport de pré-lancement Play et validation App Store Connect sans aucun signalement.
5. Comparer, ligne par ligne, les déclarations de confidentialité (Play et App Store) avec les flux réseau observés.

## 11. Points de vigilance
Les règles des stores (niveaux de SDK, 16 Ko, manifestes de confidentialité, test fermé, IA tierce) et les conditions du fournisseur d'IA changent régulièrement. Il faut les revérifier au début du lot 5. Ce document s'appuie sur ce qu'elles exigeaient au 10/11/2026.
