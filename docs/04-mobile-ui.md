# Interface mobile (PWA)

L’application est utilisée par les **opérateurs** sur smartphone Android personnel, en **PWA** installable (pas d’application native). Le scan s’appuie sur l’API **`BarcodeDetector`** lorsqu’elle est disponible, avec repli **`@zxing/browser`**.

## Écrans prévus

| Écran | Rôle |
|-------|------|
| **Login** | Pseudo + code PIN partagé |
| **Choix de session** | Liste des sessions `open` |
| **Scan principal** | Caméra, accès « saisie sans scan », lien vers « Mes scans » |
| **Saisie manuelle** | Libellé, marque, taille, unité (API externes sans résultat) |
| **Choix catégorie** | Liste filtrable des catégories avec unité de référence affichée |
| **Saisie conditionnement** | Taille + unité si manquants sur le produit |
| **Saisie quantité** | Récap produit + stepper `[ - ] n [ + ]` + validation |
| **Saisie sans scan** | Recherche sur libellé + sélection produit |
| **Historique** | Scans de l’opérateur courant, édition / suppression |

## Contraintes UX

- **Viewport** minimum environ **380px** de large utile.
- **Cibles tactiles** minimum **44×44 px**.
- **Pas de modales bloquantes** : préférer des **écrans pleins** ou des panneaux non bloquants.
- **Feedback** immédiat : indicateurs de chargement, confirmations type toast.

## Technique (socle)

- **`public/manifest.json`** et **`public/icons/icon-192.png`**, **`icon-512.png`** (placeholders ; à remplacer par la charte de l’association).
- **`@ducanh2912/next-pwa`** dans **`next.config.ts`** : pas de SW en dev (`disable: development`), SW + Workbox générés au **`next build`**.
- Métadonnées PWA : **`app/layout.tsx`** — `metadata.manifest`, `appleWebApp`, `viewport.themeColor`.
