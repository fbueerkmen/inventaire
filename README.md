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
# Renseigner NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY (voir .env.local.example)
npm run dev
```

L’application démarre sur [http://localhost:3000](http://localhost:3000). Pages placeholder : **`/mobile`** (groupe `(mobile)`), **`/desktop`** (groupe `(desktop)`).

## PWA (installable)

- **`public/manifest.json`** + **`public/icons/`** (PNG 192 / 512, placeholders téléchargés depuis placehold.co — à remplacer par vos visuels).
- **`@ducanh2912/next-pwa`** dans **`next.config.ts`** : le service worker est **désactivé en `development`**, généré en **`next build`** (`public/sw.js`, `public/workbox-*.js`, ignorés par Git — régénérés au build / sur Vercel).
- Pour tester l’installation : **`npm run build`** puis **`npm run start`**, ouvrir le site en HTTPS (ou localhost), menu du navigateur « Installer l’application » / « Ajouter à l’écran d’accueil ».

## Qualité

- `npm run lint` — ESLint (config **flat** dans `eslint.config.mjs`, compat `next/core-web-vitals` via `@eslint/eslintrc`). Next peut afficher un avertissement de dépréciation de `next lint` (migration possible vers le CLI ESLint en Next 16).
- `npm run build` — compilation production.
- `npm run gen:types` — génère `lib/database.types.ts` via [Supabase CLI](https://supabase.com/docs/guides/cli) (`supabase link` au préalable ; voir aussi la variante avec `--project-id` ci-dessous).

## API santé (keep-alive futur)

- **`GET /api/health`** — renvoie `{ "ok": true, "service": "inventaire" }` (sans cache). Pensé pour un ping périodique (ex. cron-job.org) afin de limiter la pause d’un projet Supabase Free — voir `docs/01-stack.md` et `docs/07-roadmap.md`.

## Variables d’environnement

Voir **`.env.local.example`**. Variables utilisées par le jalon 3 :

- **`NEXT_PUBLIC_SUPABASE_URL`** — URL du projet Supabase.
- **`NEXT_PUBLIC_SUPABASE_ANON_KEY`** — clé publique (anon ou publishable selon le tableau de bord).

Variable **optionnelle** (serveur uniquement, jamais préfixée `NEXT_PUBLIC_`) :

- **`SUPABASE_SERVICE_ROLE_KEY`** — à n’utiliser que dans du code exclusivement serveur (futurs scripts admin), pas dans les Composants Client.

Ne jamais committer `.env.local`.

## Types TypeScript (Supabase)

Après liaison du projet ([Supabase CLI](https://supabase.com/docs/guides/cli) installé) :

```bash
npx supabase login
npx supabase link --project-ref <votre-project-ref>
npm run gen:types
```

Sans CLI, depuis le dashboard : **Settings → API → Project reference**, puis :

```bash
npx supabase gen types typescript --project-id <project-ref> > lib/database.types.ts
```

Ensuite, typer les clients (`createBrowserClient<Database>(...)`, etc.) dans une itération dédiée.

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
