-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P03 — Identity Core
-- Source of truth: KEM-055 §6.1, §8, §9; KEM-053 §7.1
-- Depends on: P00, P01, P02 (core.record_status)
-- Depended on by: P04, and every later phase (identity.users is referenced throughout)
-- Assumes: auth.users already exists (Supabase-managed Auth schema — not created here)
-- =============================================================================

CREATE TABLE identity.users (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id        UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user_code           TEXT UNIQUE NOT NULL,
    full_name           TEXT NOT NULL,
    email               TEXT UNIQUE NOT NULL,
    status              core.record_status NOT NULL DEFAULT 'ACTIVE',
    is_service_account  BOOLEAN NOT NULL DEFAULT false,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at         TIMESTAMPTZ
);

CREATE TABLE identity.roles (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_code    TEXT UNIQUE NOT NULL,
    name         TEXT NOT NULL,
    description  TEXT,
    is_system    BOOLEAN NOT NULL DEFAULT true,
    status       core.record_status NOT NULL DEFAULT 'ACTIVE',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE identity.permissions (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_code  TEXT UNIQUE NOT NULL,
    resource         TEXT NOT NULL,
    action           TEXT NOT NULL,
    description      TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_permissions_resource_action UNIQUE (resource, action)
);

CREATE TABLE identity.role_permissions (
    role_id        UUID NOT NULL REFERENCES identity.roles(id) ON DELETE CASCADE,
    permission_id  UUID NOT NULL REFERENCES identity.permissions(id) ON DELETE CASCADE,
    CONSTRAINT pk_role_permissions PRIMARY KEY (role_id, permission_id)
);

-- identity.user_roles: R-01 (APPROVED) — surrogate PK + separate UNIQUE INDEX, since
-- PostgreSQL PRIMARY KEY constraints cannot use an expression such as COALESCE(...).
-- The scope_project_id FK to core.projects is intentionally NOT declared here — see
-- migration P06B (OQ-01, APPROVED): core.projects does not exist until P06, and
-- PostgreSQL requires the referenced table to exist at FK-creation time regardless of
-- the referencing column's nullability.
CREATE TABLE identity.user_roles (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id           UUID NOT NULL REFERENCES identity.users(id) ON DELETE CASCADE,
    role_id           UUID NOT NULL REFERENCES identity.roles(id) ON DELETE CASCADE,
    scope_project_id  UUID NULL,  -- FK added in P06B, after core.projects exists (OQ-01)
    granted_by        UUID REFERENCES identity.users(id),
    granted_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX uq_user_roles_user_role_scope
    ON identity.user_roles (user_id, role_id, COALESCE(scope_project_id, '00000000-0000-0000-0000-000000000000'::uuid));

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_users_status ON identity.users (status);
CREATE INDEX idx_user_roles_user ON identity.user_roles (user_id);
CREATE INDEX idx_user_roles_project ON identity.user_roles (scope_project_id);

-- -----------------------------------------------------------------------------
-- Auth mirror trigger (KEM-055 §8/§9: identity.handle_new_user(), AFTER INSERT on
-- auth.users). Requires a code-generation sequence for user_code, consistent with the
-- code-generation mechanism KEM-053 §5.2 describes.
-- -----------------------------------------------------------------------------

CREATE SEQUENCE IF NOT EXISTS identity.users_code_seq START 1;

CREATE OR REPLACE FUNCTION identity.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = identity, pg_temp
AS $$
BEGIN
    INSERT INTO identity.users (auth_user_id, user_code, full_name, email)
    VALUES (
        NEW.id,
        'USR-' || lpad(nextval('identity.users_code_seq')::text, 3, '0'),
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
        NEW.email
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_handle_new_user
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION identity.handle_new_user();
