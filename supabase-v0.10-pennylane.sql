-- RML ERP DEV — V0.10 — Préparation intégration Pennylane
-- À exécuter uniquement dans le projet Supabase RML ERP DEV.
-- Aucun token/API Pennylane n'est stocké dans la base ou dans GitHub.

alter table public.erp_clients
  add column if not exists siren text,
  add column if not exists pennylane_customer_id text,
  add column if not exists pennylane_external_reference text,
  add column if not exists pennylane_sync_status text not null default 'non_lie',
  add column if not exists pennylane_synced_at timestamptz;

create index if not exists erp_clients_siren_idx on public.erp_clients(siren);
create index if not exists erp_clients_pennylane_customer_idx on public.erp_clients(pennylane_customer_id);
create index if not exists erp_clients_pennylane_external_ref_idx on public.erp_clients(pennylane_external_reference);

comment on column public.erp_clients.pennylane_customer_id is 'Identifiant API V2 du client Pennylane';
comment on column public.erp_clients.pennylane_external_reference is 'Référence externe Pennylane / ERP pour rapprochement';
