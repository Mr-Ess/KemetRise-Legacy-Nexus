-- =============================================================================
-- POST-BOOTSTRAP OPERATION — NOT A MIGRATION. Do not add this to a migration
-- runner. Do not number it Pxx. Invoke manually/via application bootstrap code,
-- exactly once, only after Phase 2 (Identity Bootstrap) is complete — i.e. only
-- after a real System Admin has signed up AND been granted SUPER_ADMIN.
--
-- See ../post-bootstrap/README.md and KEM-055 §17 (Bootstrap Lifecycle) for the
-- full narrative. This file is the literal, executable reference for Phase 3.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRECONDITION CHECK (run this first, as the intended System Admin's own
-- authenticated session — NOT as service_role). Confirms Phase 2 already
-- happened before attempting Phase 3. This is advisory; the function itself
-- re-validates and will reject the call regardless if this check is skipped.
-- -----------------------------------------------------------------------------
-- SELECT identity.has_role('SUPER_ADMIN');
-- -- must return `true` for this session before proceeding.

-- -----------------------------------------------------------------------------
-- INVOCATION — the entire Phase 3 operation. Run as the System Admin's own
-- authenticated session (e.g. via the Supabase client / PostgREST RPC call
-- `supabase.rpc('bootstrap_control_tower_project')`, or directly via psql/SQL
-- editor while connected as that authenticated user — never as service_role).
-- -----------------------------------------------------------------------------
SELECT core.bootstrap_control_tower_project() AS control_tower_project_id;

-- -----------------------------------------------------------------------------
-- VERIFICATION — confirm exactly one PRJ-000 row exists, owned by the caller.
-- -----------------------------------------------------------------------------
-- SELECT project_code, is_system, owner_id, status
-- FROM core.projects
-- WHERE project_code = 'PRJ-000';
-- -- expect exactly 1 row; owner_id should equal the invoking System Admin's
-- -- identity.users.id (identity.current_user_id() at invocation time).

-- -----------------------------------------------------------------------------
-- IDEMPOTENCY — safe to re-run. A second invocation (by the same or a
-- different SUPER_ADMIN session) returns the existing PRJ-000's id without
-- creating a duplicate row or raising an error.
-- -----------------------------------------------------------------------------
-- SELECT core.bootstrap_control_tower_project(); -- returns the same id again

-- -----------------------------------------------------------------------------
-- FAILURE BEHAVIOR (for reference, not executed by this script):
--   * No authenticated session / no matching identity.users row
--       -> RAISE EXCEPTION 'CONTROL_TOWER_BOOTSTRAP_FAILED: no authenticated
--          identity resolved for caller' (SQLSTATE 28000). No row is created.
--   * Authenticated but not SUPER_ADMIN
--       -> RAISE EXCEPTION 'CONTROL_TOWER_BOOTSTRAP_FAILED: caller <id> is not
--          a SUPER_ADMIN' (SQLSTATE 42501). No row is created.
-- Both failures are single-statement transactions that roll back atomically —
-- there is no partial/half-created PRJ-000 state under any failure path.
-- =============================================================================
