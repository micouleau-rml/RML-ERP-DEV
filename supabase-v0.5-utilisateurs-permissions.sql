-- ============================================================
-- RML ERP DEV — Migration V0.5
-- Utilisateurs, rôles et permissions par module
-- À exécuter UNE SEULE FOIS dans Supabase > SQL Editor
-- ============================================================

-- 1) Modèles de permissions
create or replace function public.erp_default_permissions(p_role text)
returns jsonb
language plpgsql
immutable
as $$
begin
  case p_role
    when 'administrateur' then
      return '{"clients":true,"chantiers":true,"preparation":true,"suivi":true,"commandes":true,"pliage":true,"heures":true,"planning":true,"materiel":true,"documents":true,"analyse":true,"utilisateurs":true}'::jsonb;
    when 'direction' then
      return '{"clients":true,"chantiers":true,"preparation":true,"suivi":true,"commandes":true,"pliage":true,"heures":true,"planning":true,"materiel":true,"documents":true,"analyse":true,"utilisateurs":false}'::jsonb;
    when 'chef_equipe' then
      return '{"clients":false,"chantiers":true,"preparation":true,"suivi":true,"commandes":false,"pliage":false,"heures":true,"planning":true,"materiel":true,"documents":true,"analyse":false,"utilisateurs":false}'::jsonb;
    when 'atelier' then
      return '{"clients":false,"chantiers":true,"preparation":true,"suivi":false,"commandes":false,"pliage":true,"heures":true,"planning":false,"materiel":true,"documents":true,"analyse":false,"utilisateurs":false}'::jsonb;
    when 'lecture' then
      return '{"clients":false,"chantiers":true,"preparation":false,"suivi":true,"commandes":false,"pliage":false,"heures":false,"planning":true,"materiel":false,"documents":true,"analyse":false,"utilisateurs":false}'::jsonb;
    else
      return '{"clients":false,"chantiers":true,"preparation":true,"suivi":true,"commandes":false,"pliage":false,"heures":true,"planning":true,"materiel":true,"documents":true,"analyse":false,"utilisateurs":false}'::jsonb;
  end case;
end;
$$;

-- 2) Table des accès ERP
create table if not exists public.erp_user_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nom text,
  role text not null default 'ouvrier'
    check (role in ('administrateur','direction','chef_equipe','ouvrier','atelier','lecture')),
  active boolean not null default true,
  permissions jsonb not null default public.erp_default_permissions('ouvrier'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigger updated_at
drop trigger if exists trg_erp_user_access_updated_at on public.erp_user_access;
create trigger trg_erp_user_access_updated_at
before update on public.erp_user_access
for each row execute function public.erp_set_updated_at();

-- 3) Création automatique d'un profil ERP lors de la création d'un utilisateur Auth
create or replace function public.erp_handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.erp_user_access (user_id, email, nom, role, active, permissions)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', ''),
    'ouvrier',
    true,
    public.erp_default_permissions('ouvrier')
  )
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_erp_access on auth.users;
create trigger on_auth_user_created_erp_access
after insert on auth.users
for each row execute function public.erp_handle_new_auth_user();

-- 4) Rattraper les utilisateurs Auth déjà existants
insert into public.erp_user_access (user_id, email, nom, role, active, permissions)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data->>'name', u.raw_user_meta_data->>'full_name', ''),
  'ouvrier',
  true,
  public.erp_default_permissions('ouvrier')
from auth.users u
on conflict (user_id) do update
set email = excluded.email;

-- 5) Ton compte actuel devient administrateur ERP
update public.erp_user_access
set role = 'administrateur',
    active = true,
    permissions = public.erp_default_permissions('administrateur')
where lower(email) = lower('jcmicouleau@icloud.com');

-- 6) Fonctions de contrôle utilisées par les politiques RLS
create or replace function public.erp_is_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select a.active
    from public.erp_user_access a
    where a.user_id = auth.uid()
  ), false);
$$;

create or replace function public.erp_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select a.active and a.role = 'administrateur'
    from public.erp_user_access a
    where a.user_id = auth.uid()
  ), false);
$$;

create or replace function public.erp_has_permission(p_permission text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((
    select a.active and (
      a.role = 'administrateur'
      or coalesce((a.permissions ->> p_permission)::boolean, false)
    )
    from public.erp_user_access a
    where a.user_id = auth.uid()
  ), false);
$$;

-- 7) RLS sur la table des utilisateurs ERP
alter table public.erp_user_access enable row level security;

drop policy if exists "erp_user_access_select" on public.erp_user_access;
create policy "erp_user_access_select"
on public.erp_user_access
for select
to authenticated
using (user_id = auth.uid() or public.erp_is_admin());

drop policy if exists "erp_user_access_insert_admin" on public.erp_user_access;
create policy "erp_user_access_insert_admin"
on public.erp_user_access
for insert
to authenticated
with check (public.erp_is_admin());

drop policy if exists "erp_user_access_update_admin" on public.erp_user_access;
create policy "erp_user_access_update_admin"
on public.erp_user_access
for update
to authenticated
using (public.erp_is_admin())
with check (public.erp_is_admin());

drop policy if exists "erp_user_access_delete_admin" on public.erp_user_access;
create policy "erp_user_access_delete_admin"
on public.erp_user_access
for delete
to authenticated
using (public.erp_is_admin());

-- 8) Renforcer les politiques des clients
-- Lecture nécessaire pour afficher le nom du client dans les fiches chantier.
drop policy if exists "erp_clients_select_auth" on public.erp_clients;
create policy "erp_clients_select_auth"
on public.erp_clients
for select
to authenticated
using (public.erp_is_active());

drop policy if exists "erp_clients_insert_auth" on public.erp_clients;
create policy "erp_clients_insert_auth"
on public.erp_clients
for insert
to authenticated
with check (public.erp_has_permission('clients'));

drop policy if exists "erp_clients_update_auth" on public.erp_clients;
create policy "erp_clients_update_auth"
on public.erp_clients
for update
to authenticated
using (public.erp_has_permission('clients'))
with check (public.erp_has_permission('clients'));

drop policy if exists "erp_clients_delete_auth" on public.erp_clients;
create policy "erp_clients_delete_auth"
on public.erp_clients
for delete
to authenticated
using (public.erp_has_permission('clients'));

-- 9) Renforcer les politiques des chantiers
drop policy if exists "erp_chantiers_select_auth" on public.erp_chantiers;
create policy "erp_chantiers_select_auth"
on public.erp_chantiers
for select
to authenticated
using (public.erp_is_active());

drop policy if exists "erp_chantiers_insert_auth" on public.erp_chantiers;
create policy "erp_chantiers_insert_auth"
on public.erp_chantiers
for insert
to authenticated
with check (public.erp_has_permission('chantiers'));

drop policy if exists "erp_chantiers_update_auth" on public.erp_chantiers;
create policy "erp_chantiers_update_auth"
on public.erp_chantiers
for update
to authenticated
using (public.erp_has_permission('chantiers'))
with check (public.erp_has_permission('chantiers'));

drop policy if exists "erp_chantiers_delete_auth" on public.erp_chantiers;
create policy "erp_chantiers_delete_auth"
on public.erp_chantiers
for delete
to authenticated
using (public.erp_has_permission('chantiers'));

-- 10) Sécurité des futurs modules stockés dans erp_modules_data
-- La colonne module devra contenir une clé telle que :
-- preparation, suivi, commandes, pliage, heures, planning, materiel, documents, analyse

drop policy if exists "erp_modules_data_select_auth" on public.erp_modules_data;
create policy "erp_modules_data_select_auth"
on public.erp_modules_data
for select
to authenticated
using (public.erp_has_permission(module));

drop policy if exists "erp_modules_data_insert_auth" on public.erp_modules_data;
create policy "erp_modules_data_insert_auth"
on public.erp_modules_data
for insert
to authenticated
with check (public.erp_has_permission(module));

drop policy if exists "erp_modules_data_update_auth" on public.erp_modules_data;
create policy "erp_modules_data_update_auth"
on public.erp_modules_data
for update
to authenticated
using (public.erp_has_permission(module))
with check (public.erp_has_permission(module));

drop policy if exists "erp_modules_data_delete_auth" on public.erp_modules_data;
create policy "erp_modules_data_delete_auth"
on public.erp_modules_data
for delete
to authenticated
using (public.erp_has_permission(module));

-- 11) Droits API
 grant usage on schema public to authenticated;
 grant select, insert, update, delete on table public.erp_user_access to authenticated;
 grant select, insert, update, delete on table public.erp_clients to authenticated;
 grant select, insert, update, delete on table public.erp_chantiers to authenticated;
 grant select, insert, update, delete on table public.erp_modules_data to authenticated;
 grant execute on function public.erp_is_active() to authenticated;
 grant execute on function public.erp_is_admin() to authenticated;
 grant execute on function public.erp_has_permission(text) to authenticated;

-- Vérification finale : doit afficher ton compte en Administrateur
select email, role, active, permissions
from public.erp_user_access
order by email;
