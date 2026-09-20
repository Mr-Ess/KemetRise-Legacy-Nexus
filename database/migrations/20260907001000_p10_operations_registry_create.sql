-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P10 — Operations Registry
-- Source of truth: KEM-055 §6.4, §7
-- Depends on: P02, P03, P06, P07, P09
-- Depended on by: P11
-- =============================================================================

CREATE TABLE operations.deployments (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deployment_code     TEXT UNIQUE NOT NULL,
    project_id          UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    environment_id      UUID NOT NULL REFERENCES core.environments(id),
    repository_id       UUID REFERENCES infrastructure.repositories(id),
    version             TEXT,
    status              operations.deployment_status NOT NULL DEFAULT 'QUEUED',
    triggered_by        UUID REFERENCES identity.users(id),
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    rollback_available  BOOLEAN NOT NULL DEFAULT false,
    metadata            JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE operations.incidents (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_code   TEXT UNIQUE NOT NULL,
    project_id      UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    asset_id        UUID REFERENCES core.assets(id),
    severity        operations.incident_severity NOT NULL,
    status          operations.incident_status NOT NULL DEFAULT 'OPEN',
    title           TEXT NOT NULL,
    description     TEXT,
    detected_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at     TIMESTAMPTZ,
    assigned_to     UUID REFERENCES identity.users(id),
    root_cause      TEXT,
    resolution      TEXT
);

CREATE TABLE operations.changes (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    change_code    TEXT UNIQUE NOT NULL,
    project_id     UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    asset_id       UUID REFERENCES core.assets(id),
    change_type    TEXT NOT NULL,
    description    TEXT NOT NULL,
    reason         TEXT,
    risk_level     operations.change_risk_level NOT NULL DEFAULT 'LOW',
    requested_by   UUID NOT NULL REFERENCES identity.users(id),
    approved_by    UUID REFERENCES identity.users(id),
    status         operations.change_status NOT NULL DEFAULT 'REQUESTED',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at   TIMESTAMPTZ,
    CONSTRAINT chk_changes_high_risk_requires_approval CHECK (
        NOT (risk_level IN ('HIGH','CRITICAL') AND status = 'COMPLETED' AND approved_by IS NULL)
    )
);

CREATE TABLE operations.backups (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_code        TEXT UNIQUE NOT NULL,
    project_id         UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    asset_id           UUID NOT NULL REFERENCES core.assets(id),
    backup_type        TEXT NOT NULL,
    provider           TEXT,
    schedule           TEXT,
    retention          TEXT,
    last_backup_at     TIMESTAMPTZ,
    last_verified_at   TIMESTAMPTZ,
    status             operations.backup_status NOT NULL DEFAULT 'UNKNOWN'
);

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_deployments_project ON operations.deployments (project_id);
CREATE INDEX idx_deployments_status ON operations.deployments (status);
CREATE INDEX idx_deployments_environment ON operations.deployments (environment_id);
CREATE INDEX idx_incidents_project ON operations.incidents (project_id);
CREATE INDEX idx_incidents_status ON operations.incidents (status);
CREATE INDEX idx_incidents_severity ON operations.incidents (severity);
CREATE INDEX idx_changes_project ON operations.changes (project_id);
CREATE INDEX idx_changes_status ON operations.changes (status);
CREATE INDEX idx_backups_project ON operations.backups (project_id);
CREATE INDEX idx_backups_status ON operations.backups (status);
CREATE INDEX idx_backups_asset ON operations.backups (asset_id);
