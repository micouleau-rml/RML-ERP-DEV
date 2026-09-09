-- RML ERP DEV — Schéma V0.2
-- À exécuter UNIQUEMENT dans un projet Supabase DEV séparé des applications de production.
create extension if not exists pgcrypto;

create table if not exists public.erp_clients (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  code text,
  telephone text,
  email text,
  adresse text,
  notes text,
  actif boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.erp_chantiers (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.erp_clients(id) on delete restrict,
  nom text not null,
  adresse text,
  contact_nom text,
  contact_telephone text,
  chef_equipe text,
  statut text not null default 'actif' check (statut in ('actif','attente','termine','archive')),
  date_debut date,
  date_fin date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.erp_modules_data (
  id uuid primary key default gen_random_uuid(),
  chantier_id uuid not null references public.erp_chantiers(id) on delete cascade,
  module text not null,
  entity_type text not null,
  entity_id text not null,
  payload jsonb not null default '{}'::jsonb,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(module, entity_type, entity_id)
);

create index if not exists erp_clients_nom_idx on public.erp_clients(lower(nom));
create index if not exists erp_chantiers_client_idx on public.erp_chantiers(client_id);
create index if not exists erp_chantiers_statut_idx on public.erp_chantiers(statut);
create index if not exists erp_modules_chantier_idx on public.erp_modules_data(chantier_id);
create index if not exists erp_modules_updated_idx on public.erp_modules_data(updated_at);

create or replace function public.erp_set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end; $$;

drop trigger if exists trg_erp_clients_updated_at on public.erp_clients;
create trigger trg_erp_clients_updated_at before update on public.erp_clients for each row execute function public.erp_set_updated_at();
drop trigger if exists trg_erp_chantiers_updated_at on public.erp_chantiers;
create trigger trg_erp_chantiers_updated_at before update on public.erp_chantiers for each row execute function public.erp_set_updated_at();
drop trigger if exists trg_erp_modules_updated_at on public.erp_modules_data;
create trigger trg_erp_modules_updated_at before update on public.erp_modules_data for each row execute function public.erp_set_updated_at();

alter table public.erp_clients enable row level security;
alter table public.erp_chantiers enable row level security;
alter table public.erp_modules_data enable row level security;

-- IMPORTANT : aucune policy permissive n'est créée ici.
-- Tant que l'authentification du futur ERP n'est pas choisie, l'accès API reste fermé.
