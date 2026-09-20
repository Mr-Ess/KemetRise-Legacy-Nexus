-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P04 — Identity Helper Functions (RLS support)
-- Source of truth: KEM-055 §8, KEM-054 §9/§14, KEM-053 §9.2
-- Depends on: P03
-- Depended on by: P19 (every RLS policy calls these functions)
-- =============================================================================

CREATE OR REPLACE FUNCTION identity.current_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = identity, pg_temp
AS $$
    SELECT id FROM identity.users WHERE auth_user_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION identity.has_role(p_role_code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = identity, pg_temp
AS $$
    SELECT EXISTS (
        SELECT 1
        FROM identity.user_roles ur
        JOIN identity.roles r ON r.id = ur.role_id
        WHERE ur.user_id = identity.current_user_id()
          AND r.role_code = p_role_code
    );
$$;

CREATE OR REPLACE FUNCTION identity.has_permission(p_permission_code TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = identity, pg_temp
AS $$
    SELECT identity.has_role('SUPER_ADMIN')
        OR identity.has_role('ADMIN')
        OR EXISTS (
            SELECT 1
            FROM identity.user_roles ur
            JOIN identity.role_permissions rp ON rp.role_id = ur.role_id
            JOIN identity.permissions p ON p.id = rp.permission_id
            WHERE ur.user_id = identity.current_user_id()
              AND p.permission_code = p_permission_code
        );
$$;

CREATE OR REPLACE FUNCTION identity.has_project_access(p_project_id UUID, p_min_level TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = identity, pg_temp
AS $$
    SELECT identity.has_role('SUPER_ADMIN')
        OR identity.has_role('ADMIN')
        OR EXISTS (
            SELECT 1
            FROM identity.user_roles ur
            WHERE ur.user_id = identity.current_user_id()
              AND ur.scope_project_id = p_project_id
        );
$$;
