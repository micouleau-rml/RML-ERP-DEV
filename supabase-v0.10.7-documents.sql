-- RML ERP DEV — V0.10.7 — Documents
-- À exécuter UNIQUEMENT dans le projet Supabase RML ERP DEV.
-- Ne modifie pas erp_clients.

create extension if not exists pgcrypto;

create table if not exists public.erp_documents (
  id uuid primary key default gen_random_uuid(),
  client_id uuid references public.erp_clients(id) on delete restrict,
  chantier_id uuid not null references public.erp_chantiers(id) on delete cascade,
  category text not null default 'Autre',
  file_name text not null,
  storage_path text not null unique,
  mime_type text,
  file_size bigint,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists erp_documents_chantier_idx on public.erp_documents(chantier_id);
create index if not exists erp_documents_client_idx on public.erp_documents(client_id);
create index if not exists erp_documents_category_idx on public.erp_documents(category);

alter table public.erp_documents enable row level security;
grant select,insert,update,delete on public.erp_documents to authenticated;

drop policy if exists erp_documents_authenticated on public.erp_documents;
create policy erp_documents_authenticated on public.erp_documents for all to authenticated using (true) with check (true);

insert into storage.buckets (id,name,public,file_size_limit)
values ('erp-documents','erp-documents',false,52428800)
on conflict (id) do update set public=false, file_size_limit=52428800;

drop policy if exists erp_documents_storage_select on storage.objects;
create policy erp_documents_storage_select on storage.objects for select to authenticated using (bucket_id='erp-documents');
drop policy if exists erp_documents_storage_insert on storage.objects;
create policy erp_documents_storage_insert on storage.objects for insert to authenticated with check (bucket_id='erp-documents');
drop policy if exists erp_documents_storage_update on storage.objects;
create policy erp_documents_storage_update on storage.objects for update to authenticated using (bucket_id='erp-documents') with check (bucket_id='erp-documents');
drop policy if exists erp_documents_storage_delete on storage.objects;
create policy erp_documents_storage_delete on storage.objects for delete to authenticated using (bucket_id='erp-documents');

NOTIFY pgrst, 'reload schema';
