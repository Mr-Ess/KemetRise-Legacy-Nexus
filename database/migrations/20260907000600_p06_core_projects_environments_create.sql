-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P06 — Core Project Model
-- Source of truth: KEM-055 §6.2, §7, §8, §9
-- Depends on: P02 (enums), P03 (identity.users), P05 (lookup_values + trigger function)
-- Depended on by: P06B, P06C, P07–P16, P21
-- =============================================================================

CREATE TABLE core.projects (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_code TEXT UNIQUE NOT NULL,   -- PRJ-001+; PRJ-000 permanently reserved (KEM-053 §5.2)
    name         TEXT NOT NULL,
    slug         TEXT UNIQUE NOT NULL,
    description  TEXT,
    category     TEXT NOT NULL,   -- trigger-validated: core.lookup_values('PROJECT_CATEGORY')
    status       core.project_status NOT NULL DEFAULT 'IDEA',
    criticality  core.project_criticality NOT NULL DEFAULT 'MEDIUM',
    owner_type   identity.identity_owner_type NOT NULL DEFAULT 'USER',
    owner_id     UUID NOT NULL,
    is_system    BOOLEAN NOT NULL DEFAULT false,
    created_by   UUID REFERENCES identity.users(id),
    updated_by   UUID REFERENCES identity.users(id),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at  TIMESTAMPTZ
);

CREATE TABLE core.environments (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    env_code                 TEXT UNIQUE NOT NULL,
    project_id               UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    name                     TEXT NOT NULL,
    environment_type         core.environment_type NOT NULL,
    status                   core.record_status NOT NULL DEFAULT 'ACTIVE',
    configuration_reference  TEXT,   -- secret:// pointer only, never a raw value
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_environments_project_type UNIQUE (project_id, environment_type)
);

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_projects_status ON core.projects (status);
CREATE INDEX idx_projects_criticality ON core.projects (criticality);
CREATE INDEX idx_projects_owner ON core.projects (owner_id);
CREATE INDEX idx_environments_project ON core.environments (project_id);

-- Lookup-validation trigger attachment (KEM-055 §8: function created once in P05)
CREATE TRIGGER trg_lookup_projects_category
    BEFORE INSERT OR UPDATE OF category ON core.projects
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('PROJECT_CATEGORY', 'category');

-- NOTE (v1.2.0 / Option A): this migration does NOT create PRJ-000. See migration
-- P06C (core.bootstrap_control_tower_project()) and KEM-055 §17 Bootstrap Lifecycle.
