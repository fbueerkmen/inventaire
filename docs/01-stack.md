# Stack technique

Vue d’ensemble des choix validés pour le projet.

## Tableau récapitulatif

| Composant | Choix |
|-----------|--------|
| Frontend | **Next.js 15** (App Router, dernière release 15.x patchée — ex. **15.5.x**) + **TypeScript strict** |
| Styling | **Tailwind CSS** + **shadcn/ui** |
| Mobile | **PWA** installable — **`@ducanh2912/next-pwa`** (SW actif après `next build` / prod, désactivé en dev) ; scan : **BarcodeDetector** + **`@zxing/browser`** |
| Backend | **Supabase** (PostgreSQL + Realtime + Storage ; auth métier pseudo + PIN, pas Supabase Auth email) |
| Hébergement app | **Vercel** (Hobby, usage non commercial) |
| Hébergement BDD | **Supabase Free**, région **Frankfurt (UE)** |
| APIs produits | **OpenFoodFacts**, **OpenBeautyFacts**, **OpenProductsFacts** (sans clé) |
| Auth opérateurs | Pseudo + **code d’accès partagé (PIN)** — pas d’email |
| Paquets | **npm** |

## Conformité et localisation des données

- La base Supabase est créée en **Europe (Frankfurt)** pour limiter les transferts hors UE et documenter une démarche RGPD cohérente, y compris avec des opérateurs identifiés uniquement par **pseudo**.

## Free tier et disponibilité

- **Supabase Free** : le projet peut être **mis en pause** après une période d’inactivité (ordre de grandeur : ~7 jours sans requête selon les conditions du fournisseur).
- Les inventaires sont **trimestriels** ; un **ping périodique** via un service externe gratuit (ex. **cron-job.org**) vers **`GET /api/health`** pourra être configuré **plus tard** — la route existe déjà dans le socle.

## Librairies d’état et données

- **Pas** de Redux / Zustand en V1.
- Données serveur : client Supabase + **TanStack React Query** (`@tanstack/react-query`).
- État local : `useState` / `useReducer`.

## Organisation du code (cible)

- Types générés : `npx supabase gen types typescript` (après liaison au projet Supabase).
- Accès BDD encapsulé dans **`lib/db/`** — pas de SQL ad hoc dans les composants UI.
- Clients Supabase : **`lib/supabase/`** (`client.ts`, `server.ts`, `env.ts`) + **`middleware.ts`** pour le rafraîchissement des cookies Auth.
- **TanStack React Query** (`@tanstack/react-query`) — enveloppe **`app/providers.tsx`** dans le layout racine.
- **Scan / données** (installés, usage métier plus tard) : `@zxing/browser`, `papaparse`, `jsbarcode`.

## Arborescence App Router (socle)

- **`/`** : page d’accueil minimale (liens vers les zones).
- **`/mobile`** : fichier `app/(mobile)/mobile/page.tsx` — le segment `(mobile)` est un **groupe de routes** (invisible dans l’URL) pour regrouper layout + futures pages opérateur.
- **`/desktop`** : fichier `app/(desktop)/desktop/page.tsx` — idem pour l’admin.

## shadcn/ui (init)

- Style **base-nova**, **Tailwind v4**, variables CSS **oklch**.
- Le composant **Button** repose sur **Base UI** (`@base-ui/react`) : pas de prop `asChild` ; pour un lien visuellement bouton, utiliser **`buttonVariants` + `Link`** (voir `app/page.tsx`).
