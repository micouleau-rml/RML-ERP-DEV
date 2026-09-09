-- RML ERP DEV — Policies RLS V0.3
-- Accès réservé aux utilisateurs authentifiés Supabase

drop policy if exists "erp_clients_select_auth" on public.erp_clients;
create policy "erp_clients_select_auth" on public.erp_clients for select to authenticated using (true);
drop policy if exists "erp_clients_insert_auth" on public.erp_clients;
create policy "erp_clients_insert_auth" on public.erp_clients for insert to authenticated with check (true);
drop policy if exists "erp_clients_update_auth" on public.erp_clients;
create policy "erp_clients_update_auth" on public.erp_clients for update to authenticated using (true) with check (true);
drop policy if exists "erp_clients_delete_auth" on public.erp_clients;
create policy "erp_clients_delete_auth" on public.erp_clients for delete to authenticated using (true);

drop policy if exists "erp_chantiers_select_auth" on public.erp_chantiers;
create policy "erp_chantiers_select_auth" on public.erp_chantiers for select to authenticated using (true);
drop policy if exists "erp_chantiers_insert_auth" on public.erp_chantiers;
create policy "erp_chantiers_insert_auth" on public.erp_chantiers for insert to authenticated with check (true);
drop policy if exists "erp_chantiers_update_auth" on public.erp_chantiers;
create policy "erp_chantiers_update_auth" on public.erp_chantiers for update to authenticated using (true) with check (true);
drop policy if exists "erp_chantiers_delete_auth" on public.erp_chantiers;
create policy "erp_chantiers_delete_auth" on public.erp_chantiers for delete to authenticated using (true);

drop policy if exists "erp_modules_data_select_auth" on public.erp_modules_data;
create policy "erp_modules_data_select_auth" on public.erp_modules_data for select to authenticated using (true);
drop policy if exists "erp_modules_data_insert_auth" on public.erp_modules_data;
create policy "erp_modules_data_insert_auth" on public.erp_modules_data for insert to authenticated with check (true);
drop policy if exists "erp_modules_data_update_auth" on public.erp_modules_data;
create policy "erp_modules_data_update_auth" on public.erp_modules_data for update to authenticated using (true) with check (true);
drop policy if exists "erp_modules_data_delete_auth" on public.erp_modules_data;
create policy "erp_modules_data_delete_auth" on public.erp_modules_data for delete to authenticated using (true);
