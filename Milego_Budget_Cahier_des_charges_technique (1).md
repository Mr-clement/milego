# Cahier des charges technique
## Projet : Milego Budget

---

## 1. Présentation

### 1.1 Objectif

Développer une application mobile Flutter permettant à un utilisateur de gérer ses finances personnelles, avec un **assistant IA conversationnel** qui joue le rôle de comptable / conseiller financier personnel.

L'application doit permettre de :

- suivre les revenus et dépenses
- créer et suivre un budget mensuel
- analyser automatiquement ses habitudes financières
- suivre son épargne et ses objectifs
- **recevoir des conseils personnalisés générés par une IA**, comme le ferait un conseiller humain
- visualiser l'ensemble de sa situation financière sur **un seul écran principal**

### 1.2 Principe directeur : un écran, une vision complète

Contrairement à une app financière classique qui éclate l'information sur 5-6 écrans (Dashboard, Analytics, Reports, Goals...), Milego Budget centralise l'essentiel sur **un écran "Bilan"** unique :

- Solde restant du mois (carte hero)
- Revenus / Dépenses / Épargne (stats rapides)
- Conseil du jour généré par l'IA (carte proactive)
- Répartition des dépenses (donut chart)
- Accès direct au chat avec l'assistant

Les écrans secondaires (budgets détaillés, objectifs, transactions) restent accessibles en navigation profonde, mais ne sont plus la porte d'entrée de l'app.

Le design s'inspire d'un dashboard de suivi carbone fourni en référence : grandes cartes aux coins très arrondis, palette douce, hiérarchie visuelle claire, carte de conseil proactif type "Tip of the Day".

### 1.3 Positionnement produit

L'assistant IA n'est pas une fonctionnalité annexe : c'est le **différenciateur principal** de l'app. Il doit être capable de :

- expliquer les variations de dépenses en langage naturel
- répondre à des questions libres ("combien puis-je épargner d'ici juin ?")
- proposer des actions concrètes et chiffrées
- alerter de façon proactive (dépassement de budget, anomalie de dépense)

---

## 2. Objectifs techniques

L'application doit être :

- rapide (démarrage < 2s, 60 FPS)
- responsive
- offline first pour toutes les fonctions de saisie/consultation
- l'assistant IA nécessite une connexion (dégradation gracieuse hors ligne : conseils mis en cache affichés, chat désactivé)
- facilement maintenable et extensible
- sécurisée (données financières sensibles)

---

## 3. Stack technique

### 3.1 Application mobile (Flutter)

| Domaine | Choix |
|---|---|
| Framework | Flutter 3.x, Material 3 personnalisé |
| Langage | Dart |
| Architecture | Clean Architecture + MVVM |
| Gestion d'état | Riverpod |
| Navigation | GoRouter |
| Base locale | Isar |
| Synchronisation | Firebase (Firestore) |
| Notifications | Firebase Cloud Messaging |
| Authentification | Firebase Auth |
| Stockage sécurisé | flutter_secure_storage |
| Graphiques | fl_chart |
| Animations | flutter_animate |
| Calendrier | Table Calendar |

### 3.2 Service IA (nouveau — hors périmètre Flutter)

C'est le changement principal par rapport à une approche "tout Firebase" : l'intelligence de l'app est isolée dans un **microservice Python indépendant**, plus facile à faire évoluer, à tester, et directement réutilisable avec le projet AskDoc.

| Domaine | Choix |
|---|---|
| Langage | Python |
| Framework API | FastAPI |
| Orchestration IA | LangChain |
| Modèle | OpenAI API (GPT) |
| Base de contexte | Lecture Firestore (transactions, budgets, objectifs) |
| Déploiement | Conteneur Docker, hébergé (Render / AWS Lambda / ECS selon budget) |
| Communication | REST (requêtes ponctuelles) + WebSocket (chat temps réel) |
| Auth service ↔ app | JWT Firebase vérifié côté service Python |

**Pourquoi séparer ce service :**
- Flutter reste une couche de présentation simple, sans logique IA en Dart.
- Le service est réutilisable pour d'autres projets (AskDoc, futurs projets IA).
- Permet d'itérer sur les prompts et la logique métier IA sans redéployer l'app mobile.
- Aligné avec un profil de développeur généraliste Python/Node plutôt que "Flutter only".

---

## 4. Architecture applicative (Flutter)

```
lib/
  core/
    config/
    constants/
    extensions/
    services/
      ai_advisor_service.dart   (client HTTP/WebSocket vers le microservice)
    theme/
    utils/
  features/
    authentication/
    bilan/                      (écran principal fusionné — remplace dashboard/analytics)
    transactions/
    budgets/
    ai_assistant/                (chat, historique de conversation)
    saving/
    goals/
    settings/
  shared/
    widgets/
    models/
    repositories/
```

### 4.1 Flux Clean Architecture (par feature)

```
Presentation (UI)
      ↓
  ViewModel (Riverpod)
      ↓
   UseCases
      ↓
  Repository
      ↓
 Datasource (Isar local / Firestore remote / API Python pour l'IA)
```

### 4.2 Architecture globale du système

```
┌─────────────────┐        REST / WebSocket        ┌──────────────────────┐
│   App Flutter     │ ─────────────────────────────▶ │  Service Python (FastAPI) │
│  (Isar + Riverpod) │ ◀───────────────────────────── │  LangChain + OpenAI API  │
└─────────┬─────────┘                                 └───────────┬──────────┘
          │  sync                                                 │  lecture
          ▼                                                       ▼
   ┌─────────────┐                                        ┌──────────────┐
   │   Firebase    │◀──────────────────────────────────────│   Firestore    │
   │ (Auth, FCM)   │                                        │  (source de   │
   └─────────────┘                                        │  vérité data) │
                                                            └──────────────┘
```

---

## 5. Fonctionnalités

### 5.1 Authentification

- Connexion / Inscription (email, Google, Apple)
- Déconnexion / Suppression de compte
- Réinitialisation mot de passe

### 5.2 Écran Bilan (écran principal — remplace Dashboard + Analytics + Reports)

Composants de l'écran, du haut vers le bas :

1. **En-tête** : salutation personnalisée + accès rapide aux paramètres
2. **Carte solde** (hero) : montant restant du mois, barre de progression du budget, pourcentage utilisé
3. **Rangée de statistiques** : Revenus / Dépenses / Épargne du mois
4. **Carte Conseil IA** : message généré automatiquement par le service Python (ex : anomalie de dépense, suggestion d'économie chiffrée), avec bouton pour ouvrir la conversation complète
5. **Répartition des dépenses** : donut chart par catégorie + légende avec montants et pourcentages
6. **Bouton flottant chat** : accès permanent à l'assistant conversationnel

### 5.3 Assistant IA (feature transverse)

- Chat conversationnel en langage naturel (français)
- Contexte automatique : le service lit les transactions/budgets/objectifs de l'utilisateur avant de répondre
- Types de conseils générés :
  - explication des variations de dépenses
  - alertes proactives (dépassement de budget, dépense inhabituelle)
  - projections ("à ce rythme, vous atteindrez votre objectif le [date]")
  - réponses à des questions libres sur les finances de l'utilisateur
- Historique de conversation persistant (Firestore)
- Dégradation hors-ligne : derniers conseils mis en cache visibles, chat désactivé avec message explicite

### 5.4 Transactions

- Créer / modifier / supprimer
- Recherche et filtres (catégorie, montant, date, note)
- Champs : titre, montant, devise, type (revenu / dépense / transfert), catégorie, date, heure, note, photo de reçu

### 5.5 Catégories

Catégories par défaut : Alimentation, Transport, Santé, Maison, Loisirs, Shopping, Salaire, Investissement, Factures, Autres.

L'utilisateur peut créer, modifier, supprimer, choisir couleur et icône.

### 5.6 Budgets

- Budget mensuel / hebdomadaire / annuel / par catégorie
- Alertes de dépassement
- Progression et montant restant

### 5.7 Objectifs d'épargne

Chaque objectif : nom, description, montant cible, montant actuel, date cible, pourcentage. L'IA peut recalculer et communiquer la date d'atteinte prévisionnelle en fonction du rythme d'épargne réel.

### 5.8 Épargne

Compte épargne, historique, progression, simulation.

### 5.9 Rapports détaillés (écran secondaire)

Accessible en drill-down depuis le Bilan pour l'utilisateur qui veut aller plus loin : vues journalière/hebdomadaire/mensuelle/annuelle, bar chart, pie chart, line chart, heatmap.

### 5.10 Recherche globale

Par montant, catégorie, note, date.

### 5.11 Paramètres

Langue, devise, mode sombre, export/import, suppression des données, sauvegarde cloud.

---

## 6. Modèle de données

### User
`id, nom, email, photo, devise, langue, createdAt, updatedAt`

### Category
`id, name, icon, color, type, createdAt`

### Transaction
`id, title, amount, type, categoryId, accountId, date, note, receipt, createdAt, updatedAt`

### Budget
`id, categoryId, amount, period, startDate, endDate`

### SavingGoal
`id, name, targetAmount, currentAmount, deadline, icon, color`

### Account
`id, name, type, balance, currency`

### AIConversation (nouveau)
`id, userId, messages[{role, content, timestamp}], createdAt, updatedAt`

### AIInsight (nouveau)
`id, userId, type (alerte|conseil|projection), content, relatedCategoryId, createdAt, seen`

---

## 7. Navigation

```
Splash
  ↓
Login
  ↓
Home (Bottom Navigation)
  ├── Bilan            (écran principal)
  ├── Transactions
  ├── Objectifs
  ├── Paramètres
  └── [Bouton flottant] Assistant IA (accessible depuis n'importe quel écran)
```

---

## 8. UI Design

Principes repris du design de référence fourni :

- grandes cartes aux coins très arrondis (20–28 px)
- palette douce (verts/gris pour la référence — à décliner en palette finance : ex. vert = positif/épargne, corail = dépenses/alertes)
- fond blanc cassé
- espace généreux entre les éléments
- ombres discrètes
- icônes simples et cohérentes
- graphiques intégrés directement dans les cartes
- typographie moderne (Inter ou SF Pro)
- animations fluides (250–350 ms)
- bouton d'action flottant circulaire pour l'accès au chat IA
- carte "conseil proactif" toujours visible en haut de l'écran principal (équivalent du "Tip of the Day")

Écrans principaux :

1. Bilan (écran d'accueil unique)
2. Chat avec l'assistant IA
3. Liste des transactions
4. Ajout / détail d'une transaction
5. Gestion des budgets
6. Objectifs d'épargne
7. Rapports détaillés
8. Paramètres

---

## 9. Base de données

### Locale (Isar)
Collections : Users, Accounts, Transactions, Categories, Budgets, Goals, Settings.

### Cloud (Firestore)
Source de vérité, synchronisée automatiquement dès que l'appareil est connecté. Collections supplémentaires : AIConversations, AIInsights.

Le service Python lit directement Firestore (lecture seule) pour construire le contexte des réponses IA — il n'a pas besoin d'accès à la base Isar locale.

---

## 10. Sécurité

- Authentification Firebase + JWT
- JWT vérifié côté service Python avant tout accès aux données utilisateur
- Stockage sécurisé (flutter_secure_storage)
- Biométrie / PIN
- Chiffrement des données sensibles
- Le service Python n'a accès qu'aux données de l'utilisateur authentifié (isolation stricte par userId)
- Aucune donnée financière brute n'est envoyée à l'API OpenAI sans anonymisation minimale du contexte (pas de nom complet, pas d'identifiants bancaires)

---

## 11. Notifications

- Budget dépassé
- Objectif atteint
- Paiement récurrent
- Nouveau conseil IA disponible
- Rappel quotidien / fin de mois

---

## 12. Performances

- Démarrage < 2 secondes
- 60 FPS
- Mode hors ligne pour la saisie et la consultation
- Synchronisation différée
- Pagination des transactions
- Chargement paresseux des graphiques
- Timeout et fallback si le service IA ne répond pas (message d'erreur clair, pas de blocage de l'UI)

---

## 13. Roadmap de développement (MVP révisé)

| Phase | Contenu |
|---|---|
| 1 | Authentification + écran Bilan (statique, sans IA) |
| 2 | CRUD transactions, catégories, comptes, synchronisation Firestore |
| 3 | Microservice Python (FastAPI) déployé, endpoint conseil basé sur règles simples |
| 4 | Intégration LangChain / OpenAI pour le chat conversationnel réel et les conseils dynamiques |
| 5 | Budgets détaillés, objectifs d'épargne, notifications |
| 6 | OCR des reçus, IA de catégorisation automatique, fonctionnalités premium |

---

## 14. Évolutions futures

- Connexion bancaire (Open Banking selon les pays)
- OCR pour scanner les reçus
- Catégorisation automatique des dépenses par IA
- Prévisions de trésorerie
- Partage d'un budget familial
- Version Web / Desktop
- Widgets Android/iOS
- Synchronisation multi-appareils
- Export PDF/Excel
- Abonnements Premium

---

## 15. Synthèse de la stack recommandée

- **Flutter 3.x** avec Material 3 personnalisé pour l'application mobile
- **Clean Architecture + MVVM** pour séparer interface, logique métier et données
- **Riverpod** pour la gestion d'état
- **Isar** en base locale pour la performance offline
- **Firebase** (Auth, Firestore, Cloud Messaging) pour les fonctionnalités cloud
- **Service Python (FastAPI + LangChain + OpenAI API)**, séparé de l'app mobile, pour l'ensemble de la logique d'assistant financier — réutilisable avec le projet AskDoc et cohérent avec un profil de développeur Python/Node plutôt que Flutter uniquement
- Conception **Offline First** pour la saisie et la consultation, avec dégradation gracieuse des fonctionnalités IA hors connexion
