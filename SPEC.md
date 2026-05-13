# Spécification — Application d’inventaire associatif

## Objectif

Permettre à une **association** de réaliser un **inventaire trimestriel** (4 fois par an) d’un stock de marchandises (majoritairement alimentaire, un peu d’hygiène) en vue d’une restitution cohérente avec les attentes type **Banque Alimentaire** : totaux **agrégés par catégorie** dans une **unité de référence** (kg, L ou pièce selon la catégorie).

## Personas

| Persona | Rôle | Appareil | Identification |
|--------|------|----------|----------------|
| **Opérateur** | Scan et saisie des quantités en entrepôt | Smartphone Android (PWA) | **Pseudo** (RGPD allégé), plusieurs opérateurs en parallèle possible |
| **Admin** | Prépare l’inventaire, surveille, corrige, exporte | Ordinateur desktop | Référent association |

## Volumétrie (ordre de grandeur)

- Catalogue : quelques centaines à quelques milliers de produits
- ~1 000 à 2 000 scans par **session** d’inventaire
- 4 sessions / an
- Peu d’opérateurs simultanés

## Règles métier essentielles

1. **Identifiant produit** : code-barres (EAN/UPC) ou code **interne** (EAN-13 préfixe `2` pour produits sans code physique, étiquettable).
2. **Conditionnement** : taille numérique + unité (`g`, `kg`, `ml`, `cl`, `l`, `L`, `piece`).
3. Chaque **catégorie** a une **unité de référence unique** : `kg`, `L` ou `piece` (liquides en L, le reste en kg sauf cas « pièce »).
4. Le **mapping produit ↔ catégorie** est **persistant** entre inventaires (créé au premier besoin, réutilisé ensuite).
5. **Résultat attendu** : total par catégorie dans l’unité de référence (ex. « Légumineuses : 11,3 kg », « Huiles : 4,25 L »).
6. Lors du scan, l’opérateur saisit le **nombre de conditionnements** ; la conversion (ex. `10 × 480 g → 4,8 kg`) est faite côté **SQL** à l’export / agrégation.

## Phases du scénario (résumé)

1. **Préparation (admin)** : session, import CSV catégories, configuration unités kg/L, code d’accès opérateurs, diffusion URL + code.
2. **Saisie (opérateurs)** : login pseudo + PIN, choix session, boucle scan (résolution produit : cache optionnel, Supabase, Open*Facts, saisie manuelle), mapping catégorie si besoin, conditionnement si manquant, quantité avec stepper, historique personnel.
3. **Contrôle (admin)** : dashboard temps réel, détail par catégorie, anomalies, édition scans, catalogue.
4. **Restitution (admin)** : contrôle final, clôture session, export CSV (format standard + détail optionnel).

Le détail des écrans et des flux est dans `docs/03-flows.md`, `docs/04-mobile-ui.md`, `docs/05-desktop-ui.md`.

## Formats CSV

- **Import** et **export principal** : même en-tête 3 colonnes (`code_categorie`, `libelle_categorie`, `quantite`) — la colonne `quantite` est ignorée à l’import. L’unité (kg/L/piece) est **implicite** par catégorie côté destinataire.
- **Export détaillé** : format audit interne (voir `docs/06-csv-formats.md`).

## APIs externes produits

- OpenFoodFacts, OpenBeautyFacts, OpenProductsFacts — gratuits, sans clé.

## Contraintes notables

- Données hébergées **UE (Frankfurt)** pour le volet RGPD, même avec pseudonymisation des opérateurs.
- Free tier Supabase : projet susceptible de pause après inactivité — un **keep-alive** externe (ex. cron-job.org) pourra être ajouté plus tard.

## Hors périmètre V1

Liste maintenue dans `docs/07-roadmap.md` (DLC, multi-sites, offline complet, etc.).
