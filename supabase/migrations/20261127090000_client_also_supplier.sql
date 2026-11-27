ALTER TABLE public.erp_clients
  ADD COLUMN IF NOT EXISTS also_supplier boolean NOT NULL DEFAULT false;
