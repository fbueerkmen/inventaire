# Inventaire associatif

Socle applicatif pour l’inventaire trimestriel d’une association (stock alimentaire / hygiène). Documentation métier et technique : **`SPEC.md`** et le dossier **`docs/`**.

## Prérequis

- [Node.js](https://nodejs.org/) **LTS** (≥ 20 recommandé)
- Compte [Supabase](https://supabase.com/) — projet en région **Europe (Frankfurt)** pour les données
- [npm](https://docs.npmjs.com/cli/)

## Installation

```bash
npm install
cp .env.local.example .env.local
# Renseigner NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY (jalon 3)
npm run dev
```

L’application démarre sur [http://localhost:3000](http://localhost:3000). Pages placeholder : **`/mobile`** (groupe `(mobile)`), **`/desktop`** (groupe `(desktop)`).

## Qualité

- `npm run lint` — ESLint (config **flat** dans `eslint.config.mjs`, compat `next/core-web-vitals` via `@eslint/eslintrc`). Next peut afficher un avertissement de dépréciation de `next lint` (migration possible vers le CLI ESLint en Next 16).
- `npm run build` — compilation production.

## Variables d’environnement

Voir **`.env.local.example`** (ajouté avec le squelette). Ne jamais committer `.env.local`.

## Base de données — appliquer les migrations sur Supabase (cloud)

Ce dépôt contient des fichiers SQL versionnés dans **`supabase/migrations/`**. Pour un socle sans CLI local obligatoire :

### Option A — Éditeur SQL Supabase (recommandé pour démarrer)

1. Ouvrir le [dashboard Supabase](https://supabase.com/dashboard) du projet (région Frankfurt).
2. Menu **SQL** → **New query**.
3. Copier-coller le contenu de `supabase/migrations/0001_initial_schema.sql` (ou le fichier de migration concerné).
4. Exécuter la requête. Vérifier l’absence d’erreurs.

### Option B — Supabase CLI (`db push`)

Si le [Supabase CLI](https://supabase.com/docs/guides/cli) est installé et le projet lié :

```bash
supabase link --project-ref <votre-project-ref>
supabase db push
```

Adapter selon votre flux (branches, review des migrations).

> **Note** : la migration initiale V1 socle définit le **schéma et les fonctions** PostgreSQL. Les politiques **Row Level Security (RLS)** seront ajoutées dans une itération dédiée avant mise en production exposée.

## Documentation

| Fichier | Contenu |
|---------|---------|
| [SPEC.md](./SPEC.md) | Vision produit, règles métier, phases |
| [CLAUDE.md](./CLAUDE.md) | Conventions de code et périmètre pour les agents |
| [docs/01-stack.md](./docs/01-stack.md) | Stack technique |
| [docs/02-database.md](./docs/02-database.md) | Modèle de données et fonctions SQL |
| [docs/03-flows.md](./docs/03-flows.md) | Flux utilisateur |
| [docs/04-mobile-ui.md](./docs/04-mobile-ui.md) | UI mobile (PWA) |
| [docs/05-desktop-ui.md](./docs/05-desktop-ui.md) | UI desktop (admin) |
| [docs/06-csv-formats.md](./docs/06-csv-formats.md) | Formats CSV import / export |
| [docs/07-roadmap.md](./docs/07-roadmap.md) | Hors périmètre V1 et évolutions |

## Licence / usage

Usage associatif non commercial aligné avec les contraintes des tiers (Vercel Hobby, Supabase Free, Open*Facts).
