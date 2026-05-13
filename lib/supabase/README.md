# Clients Supabase

| Fichier | Usage |
|---------|--------|
| `env.ts` | Lecture contrôlée de `NEXT_PUBLIC_SUPABASE_*` (erreur explicite si manquant). |
| `client.ts` | `createClient()` — **Composants Client** (`"use client"`) et hooks navigateur. |
| `server.ts` | `createClient()` — **Server Components**, Server Actions, Route Handlers (`await`). |

Le fichier racine **`middleware.ts`** rafraîchit la session Auth (cookies). Sans variables d’environnement, il ne fait rien (pratique pour un build sans `.env.local`).

## Types générés

Après création du projet Supabase :

```bash
npx supabase gen types typescript --project-id <project-ref> > lib/database.types.ts
```

Puis typer les clients (`createBrowserClient<Database>(...)`, etc.) dans une itération ultérieure.
