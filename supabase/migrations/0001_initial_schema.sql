-- Inventaire associatif — schéma initial (V1 socle : tables + fonctions, sans RLS)
-- Région cible projet Supabase : Europe (Frankfurt)

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
  package_label text,
  unit_type text,
  source text default 'manual',
  is_internal boolean default false,
  internal_sku text unique,
  fetched_at timestamptz,
  created_at timestamptz default now()
);

create index products_label_trgm_idx on products using gin (label gin_trgm_ops);
create index products_is_internal_true_idx on products (is_internal) where is_internal = true;

-- Trigger : déduire unit_type depuis package_unit
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

-- Mapping produit ↔ catégorie (persistant entre inventaires)
create table product_category_mapping (
  barcode text references products (barcode) on delete cascade,
  category_code text references categories (code) on delete cascade,
  created_at timestamptz default now(),
  primary key (barcode, category_code)
);

-- V1 : un produit = une seule catégorie
create unique index product_category_mapping_barcode_unique_idx on product_category_mapping (barcode);
create index product_category_mapping_category_code_idx on product_category_mapping (category_code);

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
  session_id uuid references inventory_sessions (id) on delete cascade,
  barcode text references products (barcode),
  quantity numeric not null,
  scanned_at timestamptz default now(),
  operator_pseudo text
);

create index inventory_entries_session_id_idx on inventory_entries (session_id);
create index inventory_entries_barcode_idx on inventory_entries (barcode);

-- Codes d'accès opérateurs (pseudo + PIN partagé côté app ; stockage métier)
create table access_codes (
  code text primary key,
  label text,
  valid_from timestamptz default now(),
  valid_until timestamptz,
  created_at timestamptz default now()
);

-- Conversion vers unité de référence catégorie
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

-- Export agrégé par catégorie (CSV principal)
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

-- Détail session (audit)
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

-- Anomalies session
create or replace function session_warnings(p_session_id uuid)
returns table (
  type_anomalie text,
  barcode text,
  libelle text,
  nb_entrees int
) language sql as $$
  select 'sans_categorie'::text, p.barcode, p.label, count(*)::int
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  left join product_category_mapping pcm on pcm.barcode = p.barcode
  where ie.session_id = p_session_id and pcm.barcode is null
  group by p.barcode, p.label

  union all

  select 'sans_conditionnement'::text, p.barcode, p.label, count(*)::int
  from inventory_entries ie
  join products p on p.barcode = ie.barcode
  where ie.session_id = p_session_id
    and (p.package_size is null or p.package_unit is null)
  group by p.barcode, p.label

  union all

  select 'unite_incompatible'::text, p.barcode,
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
