# Flux utilisateur

Description des quatre phases du scénario complet. L’implémentation des écrans est hors socle initial ; ce document sert de référence fonctionnelle.

## Phase 1 — Préparation (desktop / admin)

1. Création d’une **nouvelle session** d’inventaire.
2. **Import CSV** des catégories (3 colonnes — voir `docs/06-csv-formats.md`).
3. **Configuration des unités de référence** : cocher les catégories en **L**, le reste en **kg** (ou `piece` si le modèle catégories le prévoit).
4. **Génération** d’un code d’accès opérateurs (PIN 4–6 chiffres, fenêtre de validité).
5. **Distribution** de l’URL de l’app et du code aux bénévoles.

## Phase 2 — Saisie (mobile / opérateurs)

1. **Connexion** : pseudo + code d’accès ; pseudo stocké localement (ex. `localStorage`).
2. **Choix de la session** active parmi les sessions ouvertes.
3. **Boucle de scan** :
   - Ouverture caméra, détection code-barres.
   - **Résolution produit** (cascade) :
     - Cache local IndexedDB (optionnel V1) ;
     - table `products` Supabase ;
     - OpenFoodFacts ;
     - OpenBeautyFacts ;
     - OpenProductsFacts ;
     - si échec : **formulaire saisie manuelle** (libellé, marque, taille, unité).
   - Si produit **sans catégorie mappée** : écran **choix de catégorie** (liste filtrable) — enregistrement persistant dans `product_category_mapping`.
   - Si **conditionnement manquant** : saisie taille + unité (parsing automatique depuis le libellé si possible).
   - **Saisie quantité** : nombre de conditionnements (composant type stepper `[ - ] n [ + ]` + validation « scanner suivant »).
   - Insertion dans `inventory_entries` avec `operator_pseudo`.
4. **Saisie sans scan** : recherche full-text sur `products.label`, sélection du produit.
5. **Historique personnel** : liste des scans de l’opérateur courant avec édition / suppression.

## Phase 3 — Contrôle (desktop / admin)

1. **Tableau de bord temps réel** : totaux par catégorie (Supabase Realtime).
2. **Vue détaillée** par catégorie : produits et contributions.
3. **Anomalies** via `session_warnings` : listes corrigeables (sans catégorie, sans conditionnement, unité incompatible).
4. **Édition / suppression** des entrées de scan (filtres pseudo, catégorie, période).
5. **Catalogue produits** : CRUD, fusion de doublons, produits internes (EAN-13 préfixe `2`), impression d’étiquettes (hors périmètre détaillé V1 si non priorisé).

## Phase 4 — Restitution (desktop / admin)

1. Vérification finale (anomalies à zéro, cohérence des totaux).
2. **Clôture** de session (`status = 'closed'`).
3. **Export CSV** : format 3 colonnes standard + option export **détaillé** pour audit interne.

## Documents associés

- Formats fichiers : `docs/06-csv-formats.md`
- Écrans mobile : `docs/04-mobile-ui.md`
- Écrans desktop : `docs/05-desktop-ui.md`
