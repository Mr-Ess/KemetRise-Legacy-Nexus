-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P05 — Lookup Values + Trigger-Validation Function
-- Source of truth: KEM-055 §6.2, §8, §9, §12.1
-- Depends on: P01
-- Depended on by: P06, P07, P09, P11, P14 (6 trigger-validated columns), P16, P21a
-- =============================================================================

CREATE TABLE core.lookup_values (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category    TEXT NOT NULL,
    value       TEXT NOT NULL,
    label       TEXT NOT NULL,
    is_active   BOOLEAN NOT NULL DEFAULT true,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_lookup_values_category_value UNIQUE (category, value)
);

-- -----------------------------------------------------------------------------
-- Trigger-based lookup validation (KEM-054 §12.1). Created ONCE here; attached six
-- times across P06/P07/P09/P11/P14, parameterized by category and column name via
-- trigger arguments. Never recreated per table.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION core.trigger_validate_lookup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = core, pg_temp
AS $$
DECLARE
    v_category TEXT := TG_ARGV[0];
    v_column   TEXT := TG_ARGV[1];
    v_value    TEXT;
    v_found    BOOLEAN;
BEGIN
    EXECUTE format('SELECT ($1).%I', v_column) INTO v_value USING NEW;
    SELECT EXISTS (
        SELECT 1 FROM core.lookup_values
        WHERE category = v_category AND value = v_value AND is_active = true
    ) INTO v_found;
    IF NOT v_found THEN
        RAISE EXCEPTION 'invalid lookup value % for category %', v_value, v_category;
    END IF;
    RETURN NEW;
END;
$$;
