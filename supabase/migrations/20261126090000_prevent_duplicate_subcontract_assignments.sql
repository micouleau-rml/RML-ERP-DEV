BEGIN;

CREATE INDEX IF NOT EXISTS erp_subcontract_assignments_intervention_lookup
ON public.erp_subcontract_assignments (chantier_id, subcontractor_id, planned_date);

CREATE OR REPLACE FUNCTION public.erp_check_subcontract_intervention()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
BEGIN
  IF NEW.chantier_id IS NULL OR NEW.subcontractor_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    IF ROW(OLD.chantier_id, OLD.subcontractor_id, OLD.planned_date)
       IS NOT DISTINCT FROM ROW(NEW.chantier_id, NEW.subcontractor_id, NEW.planned_date) THEN
      RETURN NEW;
    END IF;
  END IF;

  -- Serialize assignments for this chantier and subcontractor, including undated drafts.
  PERFORM pg_advisory_xact_lock(hashtextextended(
    'subcontract:' || NEW.chantier_id::text || ':' || NEW.subcontractor_id::text, 0
  ));

  IF EXISTS (
    SELECT 1
    FROM public.erp_subcontract_assignments AS assignment
    WHERE assignment.chantier_id = NEW.chantier_id
      AND assignment.subcontractor_id = NEW.subcontractor_id
      AND assignment.id IS DISTINCT FROM NEW.id
      AND (assignment.planned_date = NEW.planned_date
           OR assignment.planned_date IS NULL OR NEW.planned_date IS NULL)
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '23505',
      MESSAGE = 'Chantier déjà attribué',
      CONSTRAINT = 'erp_subcontract_intervention_unique';
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.erp_check_subcontract_intervention() FROM PUBLIC;
DROP TRIGGER IF EXISTS erp_subcontract_intervention_guard ON public.erp_subcontract_assignments;
CREATE TRIGGER erp_subcontract_intervention_guard
BEFORE INSERT OR UPDATE OF chantier_id, subcontractor_id, planned_date
ON public.erp_subcontract_assignments
FOR EACH ROW EXECUTE FUNCTION public.erp_check_subcontract_intervention();

COMMIT;
