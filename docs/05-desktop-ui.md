# Interface desktop (admin)

L’**admin** prépare l’inventaire, suit l’activité, corrige les données et exporte les résultats depuis un **ordinateur**.

## Écrans prévus

| Écran | Rôle |
|-------|------|
| **Sessions** | Liste, création, clôture des `inventory_sessions` |
| **Import catégories** | Upload CSV 3 colonnes + réglage des unités de référence (ex. cases à cocher L vs kg) |
| **Code d’accès** | Génération / régénération de PIN, dates de validité |
| **Dashboard session** | Totaux par catégorie en temps réel + compteur d’anomalies |
| **Détail catégorie** | Produits et contributions au total de la catégorie |
| **Anomalies** | Trois listes (sans catégorie, sans conditionnement, unité incompatible) avec actions de correction |
| **Détail scans** | Filtres (pseudo, catégorie, période) + édition / suppression des `inventory_entries` |
| **Catalogue produits** | CRUD, mapping catégorie, produits internes, fusion de doublons, étiquettes (selon priorisation V1) |
| **Export** | Choix du format (CSV standard symétrique import, CSV détaillé) + téléchargement |

## Conventions front

Alignées avec `CLAUDE.md` : Server Components par défaut, shadcn/ui + Tailwind, pas de SQL dans les composants — appels via `lib/db/` et routes/API si nécessaire.
