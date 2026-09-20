-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P21c — Development-Only Seed Data
-- Source of truth: KEM-055 §12.3, KEM-054 §27 (environment gate)
--
-- *** NEVER APPLY THIS FILE TO STAGING OR PRODUCTION ***
--
-- OWNER_ID: core.projects.owner_id is NOT NULL with no default (KEM-053 §7.2,
-- unchanged). This file uses NO zero-UUID/placeholder value. PRJ-001 is ordinary dev
-- seed data (not identity-dependent bootstrap data like PRJ-000), so it resolves
-- owner_id dynamically to any already-existing identity.users row. This file is a
-- no-op (logs a NOTICE) if run before at least one real user exists in this dev
-- environment — it never fabricates an owner.
-- =============================================================================

DO $$
DECLARE
    v_owner_id UUID;
BEGIN
    SELECT id INTO v_owner_id FROM identity.users ORDER BY created_at ASC LIMIT 1;

    IF v_owner_id IS NULL THEN
        RAISE NOTICE 'P21c skipped: no identity.users row exists yet in this dev environment — PRJ-001 dev seed requires at least one real user to own it.';
        RETURN;
    END IF;

    INSERT INTO core.projects (project_code, name, slug, category, is_system, status, owner_id)
    VALUES ('PRJ-001', 'Sample Development Project', 'sample-dev-project', 'INTERNAL', false, 'BUILDING', v_owner_id)
    ON CONFLICT (project_code) DO NOTHING;
END;
$$;

INSERT INTO core.environments (env_code, project_id, name, environment_type)
SELECT 'ENV-001', id, 'Development', 'DEV' FROM core.projects WHERE project_code = 'PRJ-001'
ON CONFLICT (project_id, environment_type) DO NOTHING;

INSERT INTO core.assets (asset_code, project_id, asset_type, name, status)
SELECT 'AST-001', id, 'SERVER', 'Sample Dev Server', 'ACTIVE' FROM core.projects WHERE project_code = 'PRJ-001'
ON CONFLICT (asset_code) DO NOTHING;

-- Reversal (dev-only):
-- DELETE FROM core.assets WHERE asset_code = 'AST-001';
-- DELETE FROM core.environments WHERE env_code = 'ENV-001';
-- DELETE FROM core.projects WHERE project_code = 'PRJ-001';
