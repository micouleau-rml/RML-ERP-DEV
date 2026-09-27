-- RML ERP DEV V0.10.5 — Maintenance machines & véhicules
-- À exécuter uniquement dans le projet Supabase ERP DEV. Ne touche pas erp_clients.
create extension if not exists pgcrypto;

create table if not exists public.erp_assets (
  id uuid primary key default gen_random_uuid(),
  asset_type text not null default 'Machine',
  name text not null, brand text, model text, registration text, serial_number text,
  service_date date, location text, state text not null default 'En service',
  current_counter numeric, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.erp_maintenance_events (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.erp_assets(id) on delete cascade,
  event_type text not null default 'Entretien', title text not null,
  event_date date, next_due_date date, next_due_counter numeric,
  cost numeric not null default 0, supplier text, downtime_days numeric not null default 0, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists erp_assets_name_idx on public.erp_assets(name);
create index if not exists erp_maintenance_asset_idx on public.erp_maintenance_events(asset_id);
create index if not exists erp_maintenance_due_idx on public.erp_maintenance_events(next_due_date);
alter table public.erp_assets enable row level security;
alter table public.erp_maintenance_events enable row level security;
grant select,insert,update,delete on public.erp_assets to authenticated;
grant select,insert,update,delete on public.erp_maintenance_events to authenticated;
drop policy if exists erp_assets_authenticated on public.erp_assets;
create policy erp_assets_authenticated on public.erp_assets for all to authenticated using (true) with check (true);
drop policy if exists erp_maintenance_authenticated on public.erp_maintenance_events;
create policy erp_maintenance_authenticated on public.erp_maintenance_events for all to authenticated using (true) with check (true);
