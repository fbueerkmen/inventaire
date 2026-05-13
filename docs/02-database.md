# Base de données

Le schéma relationnel et les fonctions PostgreSQL sont versionnés dans **`supabase/migrations/`**. La migration initiale V1 **socle** contient le **schéma et les fonctions** ; les politiques **Row Level Security (RLS)** ne font pas partie de ce socle et devront être définies avant une exposition large d’Internet.

## Application sur le projet cloud

Voir la section correspondante dans **`README.md`** (éditeur SQL du dashboard Supabase ou `supabase db push` avec CLI).

## Extensions

- **`pg_trgm`** : indexation et recherche approximative sur les libellés produits (GIN sur `products.label`).

## Tables principales

### `categories`

- Clé primaire : `code` (texte).
- `label`, `reference_unit` (`kg` | `L` | `piece`), `updated_at`.
- Les catégories sont typiquement **importées par CSV** en début d’inventaire ; l’admin ajuste les unités de référence (surtout **L** pour les liquides, **kg** sinon).

### `products`

- Clé primaire : `barcode` (texte).
- Libellé, marque, image, conditionnement (`package_size`, `package_unit`, `package_label`).
- `unit_type` : dérivé par **trigger** à partir de `package_unit` (`weight` | `volume` | `count`).
- `source` : origine des données (`openfoodfacts`, `openbeautyfacts`, `openproductsfacts`, `manual`, `internal`, etc.).
- Produits **internes** : `is_internal`, `internal_sku` (unique si renseigné).
- Index GIN trigram sur `label` ; index partiel sur `is_internal` où vrai.

**Unités de conditionnement** : `g`, `kg`, `ml`, `cl`, `l`, `L`, `piece`. Les variantes `l` et `L` sont toutes deux des volumes ; le trigger les traite de la même façon pour `unit_type`.

### `product_category_mapping`

- Association **persistante** `barcode` ↔ `category_code`.
- Clé primaire composite `(barcode, category_code)`.
- **Contrainte V1** : un produit ne doit avoir qu’**une** catégorie — index **unique** sur `barcode` seul.

### `inventory_sessions`

- `id` (UUID), `name`, `started_at`, `closed_at`, `status` (`open` | `closed`), `created_by_pseudo`.

### `inventory_entries`

- Une ligne par saisie (scan) : `session_id`, `barcode`, `quantity` (nombre de conditionnements), `scanned_at`, `operator_pseudo`.

### `access_codes`

- Codes d’accès opérateurs (PIN partagé) : `code`, `label`, `valid_from`, `valid_until`.

## Fonctions SQL

### `set_unit_type()` (trigger)

Avant insert/update sur `package_unit` : remplit `unit_type` selon l’unité (poids / volume / pièce).

### `to_reference_unit(amount, from_unit, to_unit)`

Conversion immutable vers l’unité de référence de la catégorie (g→kg, ml/cl/l/L→L, piece→piece). Retourne `NULL` si la conversion n’est pas définie.

### `export_session(p_session_id)`

Retour tabulaire : pour **chaque catégorie** du référentiel, `quantite` agrégée (0 si aucune contribution), arrondie (ex. 3 décimales selon migration). Sert de base au **CSV principal** symétrique à l’import.

### `export_session_detail(p_session_id)`

Détail par produit / catégorie pour **audit** avant export (contributions, unité de référence).

### `session_warnings(p_session_id)`

Anomalies typées :

- `sans_categorie` — produits scannés sans mapping.
- `sans_conditionnement` — `package_size` ou `package_unit` manquant.
- `unite_incompatible` — conversion impossible vers l’unité de référence de la catégorie mappée.

## Règles métier liées au schéma

- L’**objectif agrégé** par catégorie repose sur : entrées × conditionnement converti via `to_reference_unit` vers `categories.reference_unit`.
- Le mapping produit–catégorie est **réutilisé** d’un inventaire à l’autre : c’est la valeur ajoutée métier du système.

## Évolutions prévues (hors socle SQL initial)

- **RLS** par rôle (admin vs opérateur), politiques sur `inventory_entries`, `products`, etc.
- Génération des **types TypeScript** à partir du schéma Supabase une fois le projet créé.
