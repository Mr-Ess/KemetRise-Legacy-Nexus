-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P07 — Core Asset Model
-- Source of truth: KEM-055 §6.2, §7, §8, §9
-- Depends on: P06 complete (P06B, P06C sort between P06 and P07 in the migration
-- sequence but are independent additions — P07's own dependencies are satisfied by
-- P06 alone; P06B/P06C are not prerequisites of P07 itself)
-- Depended on by: P09–P16
-- =============================================================================

CREATE TABLE core.assets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_code      TEXT UNIQUE NOT NULL,
    project_id      UUID REFERENCES core.projects(id) ON DELETE SET NULL,
    asset_type      TEXT NOT NULL,   -- trigger-validated: core.lookup_values('ASSET_TYPE')
    name            TEXT NOT NULL,
    description     TEXT,
    status          core.record_status NOT NULL DEFAULT 'ACTIVE',
    criticality     core.project_criticality NOT NULL DEFAULT 'MEDIUM',
    environment_id  UUID REFERENCES core.environments(id),
    owner_id        UUID REFERENCES identity.users(id),
    metadata        JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    archived_at     TIMESTAMPTZ
);

CREATE TABLE core.asset_projects (
    asset_id      UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    project_id    UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    relationship  TEXT NOT NULL DEFAULT 'SHARED',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_asset_projects PRIMARY KEY (asset_id, project_id)
);

CREATE TABLE core.asset_dependencies (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_asset_id   UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    target_asset_id   UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    dependency_type   core.dependency_type NOT NULL,
    criticality       core.project_criticality NOT NULL DEFAULT 'MEDIUM',
    status            core.record_status NOT NULL DEFAULT 'ACTIVE',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_asset_deps_no_self_reference CHECK (source_asset_id <> target_asset_id),
    CONSTRAINT uq_asset_deps_source_target_type UNIQUE (source_asset_id, target_asset_id, dependency_type)
);

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_assets_project ON core.assets (project_id);
CREATE INDEX idx_assets_type ON core.assets (asset_type);
CREATE INDEX idx_assets_status ON core.assets (status);
CREATE INDEX idx_assets_environment ON core.assets (environment_id);
CREATE INDEX idx_asset_deps_source ON core.asset_dependencies (source_asset_id);
CREATE INDEX idx_asset_deps_target ON core.asset_dependencies (target_asset_id);

-- Lookup-validation trigger attachment
CREATE TRIGGER trg_lookup_assets_type
    BEFORE INSERT OR UPDATE OF asset_type ON core.assets
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('ASSET_TYPE', 'asset_type');
