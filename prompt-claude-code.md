# Initialisation du projet — Application d'inventaire associatif

Tu vas démarrer un nouveau projet from scratch. Ne commence à coder QU'APRÈS m'avoir présenté ton plan d'action et obtenu ma validation.

## Ce que je veux que tu fasses dans cette première session

1. **Lire intégralement** la spec ci-dessous
2. **Me proposer un plan** structuré pour : (a) générer la documentation projet, (b) initialiser le squelette Next.js, (c) écrire les migrations SQL initiales
3. **Attendre ma validation** avant toute action
4. Une fois validé, **exécuter étape par étape** en me demandant confirmation à chaque jalon important

Aucune feature applicative ne doit être codée dans cette première session. Juste le socle : doc, init, schéma BDD.

---

## CONTEXTE DU PROJET

### Objectif

Application d'inventaire pour une **association** qui gère un stock de marchandises (alimentaire majoritairement + un peu d'hygiène) destiné à la **Banque Alimentaire**. L'inventaire se fait **chaque trimestre** (4 fois/an).

### Personas

- **Opérateurs** : bénévoles qui scannent les produits dans l'entrepôt. Utilisent leur smartphone Android perso. Identifiés par un **pseudo** (RGPD allégé). Peuvent être plusieurs en parallèle.
- **Admin** : référent de l'association qui prépare l'inventaire, surveille, corrige, exporte. Utilise un ordinateur (desktop).

### Volumétrie

Très modeste : quelques centaines à quelques milliers de produits au catalogue, ~1000 à 2000 scans par session d'inventaire, 4 sessions/an, quelques opérateurs simultanés max.

---

## STACK TECHNIQUE VALIDÉE

| Composant | Choix |
|---|---|
| Frontend | Next.js 15 (App Router) + TypeScript strict |
| Styling | Tailwind CSS + shadcn/ui |
| Mobile | PWA installable (pas de natif). Scan via `BarcodeDetector` API native + fallback `@zxing/browser` |
| Backend | Supabase (Postgres + Auth custom + Realtime + Storage) |
| Hébergement app | Vercel Hobby (gratuit, usage non-commercial OK) |
| Hébergement BDD | Supabase Free, **région Frankfurt** (UE) |
| APIs externes | OpenFoodFacts + OpenBeautyFacts + OpenProductsFacts (gratuits, sans clé) |
| Auth | Pseudo opérateur + code d'accès partagé (PIN), pas d'email |
| Coût annuel | 0 € (ou ~10 €/an avec nom de domaine) |

**Contrainte importante** : la BDD est en région Frankfurt (UE) pour rester dans le RGPD propre, même si les opérateurs sont anonymisés par pseudo.

**Contrainte free-tier** : Supabase Free met le projet en pause après 7 jours d'inactivité → un cron de keep-alive externe (`cron-job.org` ou équivalent) sera mis en place plus tard pour pinger l'API quotidiennement, vu que les inventaires sont espacés de 90 jours.

---

## MODÈLE MÉTIER

### Règles essentielles

1. Un produit est identifié par son **code-barres** (EAN/UPC) ou un code **interne** (préfixe EAN-13 "2" pour les produits sans barcode physique, imprimables comme étiquettes).
2. Chaque produit a un **conditionnement** : taille numérique + unité (`g`, `kg`, `ml`, `cl`, `l`, `L`, `piece`).
3. Une **catégorie** a une **unité de référence unique** : soit `kg`, soit `L`, soit `piece`. Les liquides sont en L, le reste en kg.
4. Un **mapping** produit ↔ catégorie est persistant entre inventaires (créé lors du premier scan, réutilisé ensuite).
5. **L'objectif final de l'inventaire** : un total agrégé **par catégorie** dans son unité de référence (ex : "Légumineuses : 11,3 kg", "Huiles : 4,25 L").
6. Lors du scan, l'opérateur saisit le **nombre de conditionnements** (ex : "10 boîtes"). Le calcul `10 × 480g = 4,8 kg` se fait à l'export via SQL.

### Schéma de base de données

```sql
-- Extensions
create extension if not exists pg_trgm;

-- Catégories (importées par CSV en début d'inventaire)
create table categories (
  code text primary key,
  label text not null,
  reference_unit text not null default 'kg' check (reference_unit in ('kg', 'L', 'piece')),
  updated_at timestamptz default now()
);

-- Produits (catalogue auto-construit au fil des inventaires)
create table products (
  barcode text primary key,
  label text not null,
  brand text,
  image_url text,
  package_size numeric,
  package_unit text check (package_unit in ('g', 'kg', 'ml', 'cl', 'l', 'L', 'piece')),
  package_label text,                  -- libellé texte d'origine ex : "480 g"
  unit_type text,                       -- 'weight' | 'volume' | 'count', calculé via trigger
  source text default 'manual',         -- 'openfoodfacts' | 'openbeautyfacts' | 'openproductsfacts' | 'manual' | 'internal'
  is_internal boolean default false,
  internal_sku text unique,
  fetched_at timestamptz,
  created_at timestamptz default now()
);

create index on products using gin (label gin_trgm_ops);
create index on products(is_internal) where is_internal = true;

-- Trigger pour déduire unit_type depuis package_unit
create or replace function set_unit_type() returns trigger as $$
begin
  new.unit_type := case
    when new.package_unit in ('g', 'kg') then 'weight'
    when new.package_unit in ('ml', 'cl', 'l', 'L') then 'volume'
    when new.package_unit = 'piece' then 'count'
    else null
  end;
  return new;
end;
$$ language plpgsql;

create trigger products_set_unit_type
  before insert or update of package_unit on products
  for each row execute function set_unit_type();

-- Mapping produit ↔ catégorie (PERSISTANT entre inventaires, c'est la valeur ajoutée du système)
create table product_category_mapping (
  barcode text references products(barcode) on delete cascade,
  category_code text references categories(code) on delete cascade,
  created_at timestamptz default now(),
  primary key (barcode, category_code)
);
-- Contrainte : un produit = une seule catégorie pour la V1
create unique index on product_category_mapping(barcode);
create index on product_category_mapping(category_code);

-- Sessions d'inventaire
create table inventory_sessions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  started_at timestamptz default now(),
  closed_at timestamptz,
  status text default 'open' check (status in ('open', 'closed')),
  created_by_pseudo text
);

-- Entrées d'inventaire (chaque scan = une ligne)
create table inventory_entries (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references inventory_sessions(id) on delete cascade,
  barcode text references products(barcode),
  quantity numeric not null,
  scanned_at timestamptz default now(),
  operator_pseudo text
);

create index on inventory_entries(session_id);
create index on inventory_entries(barcode);

-- Codes d'accès opérateurs (pseudo + PIN partagé)
create table access_codes (
  code text primary key,
  label text,
  valid_from timestamptz default now(),
  valid_until timestamptz,
  created_at timestamptz default now()
);

-- Fonction : conversion vers unité de référence
create or replace function to_reference_unit(
  amount numeric,
  from_unit text,
  to_unit text
) returns numeric language plpgsql immutable as $$
begin
  if amount is null or from_unit is null or to_unit is null then return null; end if;
  if from_unit = to_unit then return amount; end if;

  if to_unit = 'kg' then
    return case from_unit
      when 'g'  then amount / 1000.0
      when 'kg' then amount
      else null
    end;
  end if;

  if to_unit = 'L' then
    return case from_unit
      when 'ml' then amount / 1000.0
      when 'cl' then amount / 100.0
      when 'l'  then amount
      when 'L'  then amount
      else null
    end;
  end if;

  if to_unit = 'piece' and from_unit = 'piece' then return amount; end if;

  return null;
end;
$$;

-- Fonction : export agrégé par catégorie (= CSV final exporté)
create or replace function export_session(p_session_id uuid)
returns table (
  code_categorie text,
  libelle_categorie text,
  quantite numeric
) language sql as $$
  with totaux as (
    select
      c.code,
      c.label,
      round(sum(
        ie.quantity * to_reference_unit(p.package_size, p.package_unit, c.reference_unit)
      )::numeric, 3) as quantite
    from inventory_entries ie
    join products p on p.barcode = ie.barcode
    join product_category_mapping pcm on pcm.barcode = p.barcode
    join categories c on c.code = pcm.category_code
    where ie.session_id = p_session_id
      and to_reference_unit(p.package_size, p.package_unit, c.reference_unit) is not null
    group by c.code, c.label
  )
  select c.code, c.label, coalesce(t.quantite, 0)
  from categories c
  left join totaux t on t.code = c.code
  order by c.code;
$$;

-- Fonction : détail (audit avant export)
create or replace function export_session_detail(p_session_id uuid)
returns table (
  code_categorie text,
  libelle_categorie text,
  barcode text,
  libelle_produit text,
  conditionnement text,
  nb_unites numeric,
  quantite_contribuee numeric,
  unite text
) language sql as $$
  select
    c.code,
    c.label,
    p.barcode,
    p.label,
    p.package_label,
    sum(ie.quantity),
    round(sum(ie.quantity * to_reference_unit(p.package_size, p.package_unit, c.reference_unit))::numeric, 3),
    c.reference_unit
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  left join product_category_mapping pcm on pcm.barcode = p.barcode
  left join categories c on c.code = pcm.category_code
  where ie.session_id = p_session_id
  group by c.code, c.label, p.barcode, p.label, p.package_label, p.package_size, p.package_unit, c.reference_unit
  order by c.code nulls last, p.label;
$$;

-- Fonction : anomalies d'une session
create or replace function session_warnings(p_session_id uuid)
returns table (
  type_anomalie text,
  barcode text,
  libelle text,
  nb_entrees int
) language sql as $$
  select 'sans_categorie', p.barcode, p.label, count(*)::int
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  left join product_category_mapping pcm on pcm.barcode = p.barcode
  where ie.session_id = p_session_id and pcm.barcode is null
  group by p.barcode, p.label

  union all

  select 'sans_conditionnement', p.barcode, p.label, count(*)::int
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  where ie.session_id = p_session_id
    and (p.package_size is null or p.package_unit is null)
  group by p.barcode, p.label

  union all

  select 'unite_incompatible', p.barcode,
         p.label || ' (' || p.package_unit || ' → ' || c.reference_unit || ')',
         count(*)::int
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  join product_category_mapping pcm on pcm.barcode = p.barcode
  join categories c on c.code = pcm.category_code
  where ie.session_id = p_session_id
    and to_reference_unit(p.package_size, p.package_unit, c.reference_unit) is null
  group by p.barcode, p.label, p.package_unit, c.reference_unit;
$$;
```

---

## FORMATS CSV

### Import (3 colonnes — uploadé par l'admin en début d'inventaire)

```csv
code_categorie,libelle_categorie,quantite
LEG,Légumineuses,
PAT,Pâtes,
HUI,Huiles,
LAIT,Lait et boissons lactées,
...
```

La colonne `quantite` est ignorée à l'import (vide ou avec valeurs T-1 indicatives).

### Export (3 colonnes — téléchargé par l'admin en fin d'inventaire)

Format **strictement symétrique** à l'import, pour permettre comparaison et rejeu d'inventaire.

```csv
code_categorie,libelle_categorie,quantite
LEG,Légumineuses,11.300
PAT,Pâtes,23.500
HUI,Huiles,4.250
LAIT,Lait et boissons lactées,12.000
...
```

L'unité (kg ou L) n'apparaît pas dans le CSV : elle est implicite par catégorie côté Banque Alimentaire.

### Export détaillé (format secondaire, audit interne)

```csv
code_categorie,libelle_categorie,barcode,libelle_produit,conditionnement,nb_unites,contribution,unite
LEG,Légumineuses,3083680000123,Lentilles vertes Cassegrain,480 g,10,4.800,kg
LEG,Légumineuses,3083680000456,Lentilles vertes Cassegrain,900 g,5,4.500,kg
...
```

---

## LES 4 PHASES DU SCÉNARIO COMPLET

### Phase 1 — Préparation (Desktop / Admin)

1. Création d'une nouvelle session d'inventaire
2. Import du CSV catégories (3 colonnes)
3. Configuration des unités de référence (cocher les catégories en L, le reste reste en kg)
4. Génération d'un code d'accès opérateurs (PIN 4-6 chiffres avec validité)
5. Distribution URL + code aux opérateurs

### Phase 2 — Saisie (Mobile / Opérateurs)

1. **Login** : pseudo + code d'accès. Stockage du pseudo en localStorage.
2. **Sélection de la session active**
3. **Boucle de scan** :
   - Caméra ouvre, code-barres détecté
   - **Cascade de résolution produit** :
     a. Cache local IndexedDB (optionnel V1)
     b. `products` Supabase
     c. OpenFoodFacts (`https://world.openfoodfacts.org/api/v2/product/{barcode}.json`)
     d. OpenBeautyFacts (`https://world.openbeautyfacts.org/...`)
     e. OpenProductsFacts (`https://world.openproductsfacts.org/...`)
     f. Si aucun résultat : **formulaire saisie manuelle** (libellé + marque + taille + unité)
   - Si produit pas mappé à une catégorie : **écran choix catégorie** (recherche filtrable, persistant pour futurs inventaires)
   - Si conditionnement manquant : **saisie taille + unité** (avec tentative de parsing automatique depuis le libellé)
   - **Saisie quantité** : composant `[ - ] n [ + ]` + bouton "Valider et scanner suivant"
   - Insert dans `inventory_entries` avec `operator_pseudo`
4. **Saisie sans scan** (pour produits non étiquetables) : recherche full-text sur `products.label`
5. **Historique personnel** : liste des scans de l'opérateur courant avec édit/suppression

### Phase 3 — Contrôle (Desktop / Admin)

1. **Tableau de bord realtime** : totaux par catégorie qui se mettent à jour pendant les scans (Supabase Realtime)
2. **Vue détaillée par catégorie** : composition (quels produits, quelles contributions)
3. **Gestion des anomalies** (fonction `session_warnings`) :
   - Produits sans catégorie → bouton "Associer à une catégorie"
   - Produits sans conditionnement → saisie taille + unité
   - Unités incompatibles → remapper ou créer nouvelle catégorie
4. **Édition / suppression de scans** (filtres pseudo, catégorie, période)
5. **Gestion du catalogue produits** : édition, fusion de doublons, création produits internes avec impression d'étiquettes EAN-13 (préfixe "2")

### Phase 4 — Restitution (Desktop / Admin)

1. Vérification finale (anomalies à 0, totaux cohérents)
2. **Clôture de session** (`status = 'closed'`)
3. **Export CSV** (format 3 colonnes standard + format détaillé en option)

---

## ÉCRANS MOBILE (résumé)

| Écran | Contenu |
|---|---|
| Login | Pseudo + code PIN |
| Choix session | Liste sessions ouvertes |
| Scan principal | Caméra + bouton "Saisie sans scan" + lien "Mes scans" |
| Saisie manuelle | Libellé + marque + taille + unité (quand API renvoie rien) |
| Choix catégorie | Liste filtrable des catégories avec unité affichée |
| Saisie conditionnement | Taille + unité (quand manquant) |
| Saisie quantité | Affichage produit + stepper `[ - ] n [ + ]` |
| Saisie sans scan | Recherche libellé + sélection |
| Historique | Liste des scans personnels avec édit/suppression |

**Contraintes UX mobile** :
- Viewport min 380px
- Cibles tactiles min 44x44px
- Pas de modales bloquantes (préférer écrans pleins)
- Feedback immédiat (toast/loader)

---

## ÉCRANS DESKTOP (résumé)

| Écran | Contenu |
|---|---|
| Sessions | Liste + création + clôture |
| Import catégories | Upload CSV + configuration unités kg/L par checkbox |
| Code d'accès | Génération + régénération + validité |
| Dashboard session | Totaux par catégorie en realtime + compteur anomalies |
| Détail catégorie | Composition (produits qui contribuent au total) |
| Anomalies | 3 listes (sans cat / sans cond / unité incompat) avec correction inline |
| Détail scans | Filtres + édit/suppression |
| Catalogue produits | CRUD + mapping + création interne + impression étiquettes |
| Export | Choix format + téléchargement CSV |

---

## CONVENTIONS DE CODE À RESPECTER

- TypeScript **strict**, jamais de `any`
- Composants React **fonctionnels** uniquement
- **Server Components** par défaut, `"use client"` uniquement quand nécessaire
- **Tailwind** pour le styling, pas de CSS modules ni styled-components
- **shadcn/ui** pour les composants de base
- Fichiers en `kebab-case`, composants `PascalCase` à l'export
- Alias `@/` configurés dans `tsconfig.json`
- Types Supabase **générés** via `npx supabase gen types typescript`
- Toutes les requêtes BDD encapsulées dans `lib/db/`, pas de SQL brut dans les composants
- Pas de librairie d'état global (Redux/Zustand) pour la V1
- Server state via Supabase + React Query (`@tanstack/react-query`)
- Local state via `useState`/`useReducer`

---

## CE QUI EST HORS PÉRIMÈTRE V1

À documenter dans `docs/07-roadmap.md` et **ne pas implémenter** sans validation explicite :

- DLC / dates de péremption
- Origine du stock (don, ramasse FEAD, achat)
- Multi-sites / multi-entrepôts
- Comptes opérateurs individuels avec mot de passe
- Mode offline avec queue de synchronisation IndexedDB
- Notifications push
- Export Excel (rester sur CSV en V1)
- Multi-langue (français uniquement V1)

---

## STRUCTURE DE PROJET ATTENDUE

```
mon-projet-inventaire/
├── CLAUDE.md                  ← Tes instructions de travail
├── SPEC.md                    ← Vue d'ensemble + règles métier
├── README.md                  ← Pour démarrer en local
├── docs/
│   ├── 01-stack.md
│   ├── 02-database.md
│   ├── 03-flows.md
│   ├── 04-mobile-ui.md
│   ├── 05-desktop-ui.md
│   ├── 06-csv-formats.md
│   └── 07-roadmap.md
├── supabase/
│   ├── migrations/
│   │   └── 0001_initial_schema.sql
│   └── config.toml
├── app/
│   ├── (mobile)/
│   ├── (desktop)/
│   ├── api/
│   ├── layout.tsx
│   └── page.tsx
├── components/
│   └── ui/                    ← shadcn
├── lib/
│   ├── supabase/
│   ├── db/
│   ├── scanner/
│   └── products/
├── public/
│   ├── manifest.json          ← PWA
│   └── icons/
├── .env.local.example
├── .gitignore
├── next.config.ts
├── package.json
├── tailwind.config.ts
└── tsconfig.json
```

---

## TON PLAN D'ACTION ATTENDU

Présente-moi un plan structuré pour cette session d'init, par exemple :

1. **Génération de la documentation** (CLAUDE.md, SPEC.md, README.md, docs/01 à docs/07)
2. **Initialisation du projet Next.js** avec configuration TypeScript strict, Tailwind, shadcn/ui
3. **Installation des dépendances** (Supabase JS, React Query, @zxing/browser, Papaparse, jsbarcode, lucide-react…)
4. **Configuration PWA** (manifest.json, icons placeholders, service worker basique)
5. **Création de la première migration SQL** dans `supabase/migrations/0001_initial_schema.sql`
6. **Mise en place des variables d'environnement** (`.env.local.example`)
7. **Setup du client Supabase** côté serveur et client
8. **Vérification que `npm run dev` démarre sans erreur**

Détaille les commandes que tu vas lancer et les fichiers que tu vas créer. **Attends ma validation avant d'exécuter quoi que ce soit.**

Si certains points te paraissent ambigus ou si tu identifies des décisions à prendre que je n'ai pas explicitées, **liste-les en début de réponse** pour qu'on clarifie avant de démarrer.
