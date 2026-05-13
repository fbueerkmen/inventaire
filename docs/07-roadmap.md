# Roadmap et hors périmètre V1

Les éléments ci-dessous sont **documentés** pour mémoire et planification. **Ne pas implémenter** sans validation explicite du porteur du projet.

## Hors périmètre V1 (liste de référence)

- **DLC / dates de péremption** sur les produits ou les lignes d’inventaire.
- **Origine du stock** (don, ramasse FEAD, achat, etc.).
- **Multi-sites / multi-entrepôts**.
- **Comptes opérateurs individuels** avec mot de passe (le modèle V1 reste pseudo + PIN partagé).
- **Mode offline** complet avec file d’attente de synchronisation IndexedDB (un cache local optionnel au scan peut être mentionné en V1 mais pas une sync offline robuste).
- **Notifications push**.
- **Export Excel** — rester sur **CSV** en V1.
- **Multi-langue** — **français uniquement** en V1.

## Sécurité et prod (à planifier après le socle)

- Politiques **Row Level Security (RLS)** Supabase alignées sur les rôles admin / opérateur et sur l’usage des clés (anon vs service côté serveur uniquement).
- **Keep-alive** : brancher un cron externe gratuit sur **`GET /api/health`** (route déjà présente) pour limiter la pause du projet Supabase Free entre inventaires trimestriels.

## Améliorations possibles (backlog non commité)

- IndexedDB comme cache produit agressif côté mobile.
- Fusion assistée de doublons catalogue avec historique.
- Nom de domaine personnalisé (~coût annuel faible).
- Tableaux de bord statistiques multi-sessions (évolution des stocks catégorie par catégorie sur plusieurs trimestres).

Toute extension de ce document doit rester cohérente avec `SPEC.md` et les contraintes free tier / RGPD décrites dans `docs/01-stack.md`.
