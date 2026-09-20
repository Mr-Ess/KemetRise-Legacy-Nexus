-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P06C — Control Tower Bootstrap Function
-- Source of truth: KEM-052 §186 (BOOTSTRAP sequence, unmodified), KEM-055 §17
-- (Bootstrap Lifecycle — Option A, approved by Mr. Ess)
-- Depends on: P04 (identity.current_user_id, identity.has_role), P06 (core.projects)
-- Depended on by: nothing in the P00–P21 migration sequence itself — this function is
-- DEFINED here (safe: defining a function creates no data and has no admin
-- dependency), but it is INVOKED only later, as a separate POST-BOOTSTRAP OPERATION
-- (see /database/post-bootstrap/, NOT part of this migration sequence, NOT auto-run).
--
-- THIS MIGRATION DOES NOT CREATE PRJ-000. It only makes the mechanism available.
-- =============================================================================

CREATE OR REPLACE FUNCTION core.bootstrap_control_tower_project()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = core, identity, pg_temp
AS $$
DECLARE
    v_caller_id    UUID;
    v_existing_id  UUID;
    v_new_id       UUID;
BEGIN
    -- -------------------------------------------------------------------
    -- Prerequisite validation (Test A): the caller must resolve to a real,
    -- known identity.users row. If no session is authenticated, or the
    -- session does not map to any identity.users row, this fails closed.
    --
    -- Authorization is checked BEFORE the idempotency short-circuit below,
    -- deliberately: checking idempotency first would let ANY authenticated
    -- caller — including a non-admin — learn or "return" the existing
    -- PRJ-000 id via this SECURITY DEFINER function, bypassing RLS read
    -- restrictions on core.projects entirely. Authorization must gate
    -- every code path, including the idempotent-return path, not just the
    -- INSERT path (Test D).
    -- -------------------------------------------------------------------
    v_caller_id := identity.current_user_id();
    IF v_caller_id IS NULL THEN
        RAISE EXCEPTION 'CONTROL_TOWER_BOOTSTRAP_FAILED: no authenticated identity resolved for caller'
            USING ERRCODE = '28000';  -- invalid_authorization_specification
    END IF;

    -- -------------------------------------------------------------------
    -- Authorization (Test D): the caller must hold SUPER_ADMIN. This is
    -- checked explicitly and independently of RLS (this function is
    -- SECURITY DEFINER and therefore bypasses RLS as table owner) — the
    -- check below is the sole gate protecting this operation, by design
    -- (defense in depth, KEM-055 §16 least-privilege principle). It gates
    -- BOTH the idempotent-return path and the INSERT path below.
    -- -------------------------------------------------------------------
    IF NOT identity.has_role('SUPER_ADMIN') THEN
        RAISE EXCEPTION 'CONTROL_TOWER_BOOTSTRAP_FAILED: caller % is not a SUPER_ADMIN', v_caller_id
            USING ERRCODE = '42501';  -- insufficient_privilege
    END IF;

    -- -------------------------------------------------------------------
    -- Idempotency (Test C): only reached by an already-authorized
    -- SUPER_ADMIN. If PRJ-000 already exists, return its id and do nothing
    -- further. No duplicate row is ever created.
    -- -------------------------------------------------------------------
    SELECT id INTO v_existing_id FROM core.projects WHERE project_code = 'PRJ-000';
    IF v_existing_id IS NOT NULL THEN
        RETURN v_existing_id;
    END IF;

    -- -------------------------------------------------------------------
    -- Binding: owner_id is set to the invoking, verified System Admin's OWN
    -- identity.users.id — never an arbitrary, unrelated, or fabricated value.
    -- Single INSERT, single implicit transaction (the function call itself);
    -- any failure below rolls back the entire function invocation atomically,
    -- leaving no partial row (Test A/D failure behavior).
    -- -------------------------------------------------------------------
    INSERT INTO core.projects (project_code, name, slug, category, is_system, status, owner_id)
    VALUES ('PRJ-000', 'MR-ESS Control Tower', 'control-tower', 'INTERNAL', true, 'LIVE', v_caller_id)
    RETURNING id INTO v_new_id;

    RETURN v_new_id;
END;
$$;

-- Grant-level control (defense in depth alongside the internal has_role() check):
-- anon (unauthenticated) can never even attempt this; only authenticated sessions can,
-- and the internal check above still rejects any non-SUPER_ADMIN authenticated caller.
REVOKE EXECUTE ON FUNCTION core.bootstrap_control_tower_project() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION core.bootstrap_control_tower_project() TO authenticated;
