# Formats CSV

Les formats d’**import** et d’**export principal** sont **strictement symétriques** pour permettre comparaison entre inventaires et éventuel rejeu / contrôle.

## Encodage et séparateur

- **UTF-8** recommandé.
- Séparateur : **virgule** (`,`) — aligné avec les exemples métier ; si l’outil tableur exporte en `;`, prévoir une normalisation côté app plus tard.

## Import catégories (admin, début d’inventaire)

**Colonnes** (3) :

```csv
code_categorie,libelle_categorie,quantite
LEG,Légumineuses,
PAT,Pâtes,
HUI,Huiles,
LAIT,Lait et boissons lactées,
```

- **`quantite`** : **ignorée** à l’import (vide ou valeurs indicatives T−1 / hors système).
- Les **unités de référence** (`kg` / `L` / `piece`) ne sont pas dans le fichier : elles sont configurées dans l’app après import (ex. cases « catégorie en litres »).

## Export principal (admin, fin d’inventaire)

Même en-tête et mêmes colonnes logiques :

```csv
code_categorie,libelle_categorie,quantite
LEG,Légumineuses,11.300
PAT,Pâtes,23.500
HUI,Huiles,4.250
LAIT,Lait et boissons lactées,12.000
```

- **`quantite`** : total agrégé dans l’**unité de référence** de la catégorie ; cette unité **n’apparaît pas** dans le CSV (implicite côté Banque Alimentaire / référentiel catégories).
- Les valeurs numériques peuvent utiliser le **point** comme séparateur décimal pour rester stables à l’international ; documenter le format exact à l’implémentation (ex. 3 décimales alignées sur `export_session`).

## Export détaillé (audit interne)

Format secondaire pour contrôle avant envoi définitif :

```csv
code_categorie,libelle_categorie,barcode,libelle_produit,conditionnement,nb_unites,contribution,unite
LEG,Légumineuses,3083680000123,Lentilles vertes Cassegrain,480 g,10,4.800,kg
LEG,Légumineuses,3083680000456,Lentilles vertes Cassegrain,900 g,5,4.500,kg
```

- **`conditionnement`** : libellé texte d’origine (ex. `package_label`).
- **`nb_unites`** : somme des quantités (nombre de conditionnements) pour cette ligne de regroupement.
- **`contribution`** : quantité convertie dans l’unité de référence de la catégorie.
- **`unite`** : unité de référence (`kg`, `L`, `piece`).

La logique métier d’agrégation est portée par les fonctions SQL `export_session` et `export_session_detail` (voir `docs/02-database.md`).
