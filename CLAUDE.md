# Instructions de travail — Inventaire associatif

Ce fichier guide tout agent ou contributeur qui modifie ce dépôt.

## Contexte produit

Application d’inventaire trimestriel pour une association (stock alimentaire / un peu d’hygiène, restitution type Banque Alimentaire). Voir `SPEC.md` et `docs/` pour le détail métier.

## Stack validée

- **Frontend** : Next.js 15 (App Router), TypeScript **strict**
- **UI** : Tailwind CSS + shadcn/ui
- **Mobile** : PWA (`@ducanh2912/next-pwa`), scan via `BarcodeDetector` + fallback `@zxing/browser` (hors socle initial si non encore câblé)
- **Backend** : Supabase (Postgres, région **Frankfurt**), Auth pseudo + PIN (custom, pas d’email)
- **Hébergement** : Vercel Hobby + Supabase Free

## Conventions de code

- TypeScript strict, **jamais** de `any`
- Composants React **fonctionnels** uniquement
- **Server Components** par défaut ; `"use client"` seulement si nécessaire (état, hooks navigateur, événements)
- Styling : **Tailwind** uniquement (pas de CSS modules ni styled-components)
- Fichiers source en **kebab-case** ; composants exportés en **PascalCase**
- Alias d’import **`@/`** (voir `tsconfig.json`)
- Types DB : générés avec `npx supabase gen types typescript` quand le projet Supabase existe
- **Toutes les requêtes BDD** passent par `lib/db/` — **pas de SQL brut dans les composants**
- **Pas** de Redux / Zustand en V1 : état serveur via Supabase + **React Query** ; état local `useState` / `useReducer`
- **shadcn Button (base / Base UI)** : pas de prop `asChild` ; pour un lien avec apparence bouton, utiliser **`buttonVariants` + `Link`** (ex. `app/page.tsx`).

## Base de données

- Schéma et fonctions SQL : `supabase/migrations/` (voir `docs/02-database.md` et README pour application sur le cloud)
- La migration initiale V1 socle = **schéma + fonctions** ; les politiques **RLS** seront ajoutées dans une itération dédiée sécurité, pas dans le socle sans validation explicite

## Périmètre des changements

- Modifier uniquement ce qui est demandé ; pas de refactor gratuit ni fichiers hors sujet
- Ne pas implémenter les sujets listés dans `docs/07-roadmap.md` sans validation explicite

## Documentation

- Vue d’ensemble et règles métier : `SPEC.md`
- Détails techniques : `docs/01-stack.md` … `docs/07-roadmap.md`
