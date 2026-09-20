-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P09 — Infrastructure Registry
-- Source of truth: KEM-055 §6.3, §7, §8, §9
-- Depends on: P02, P03, P05, P06, P07
-- Depended on by: P10
-- NOTE: certificates references domains, so domains MUST be created before
-- certificates within this file — table order below preserves this.
-- =============================================================================

CREATE TABLE infrastructure.servers (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    server_code        TEXT UNIQUE NOT NULL,
    asset_id           UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    provider           TEXT NOT NULL,   -- trigger-validated: lookup_values('SERVER_PROVIDER_TYPE')
    hostname           TEXT NOT NULL,
    ip_reference       TEXT,
    server_type        TEXT NOT NULL,
    operating_system   TEXT,
    region             TEXT,
    status             core.record_status NOT NULL DEFAULT 'ACTIVE',
    capacity_metadata  JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE infrastructure.databases (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    database_code             TEXT UNIQUE NOT NULL,
    asset_id                  UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    project_id                UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    engine                    TEXT NOT NULL,   -- trigger-validated: lookup_values('DATABASE_ENGINE')
    version                   TEXT,
    provider                  TEXT,
    host_reference            TEXT,
    database_name_reference   TEXT,
    environment_id            UUID REFERENCES core.environments(id),
    status                    core.record_status NOT NULL DEFAULT 'ACTIVE',
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE infrastructure.repositories (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    repository_code           TEXT UNIQUE NOT NULL,
    asset_id                  UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    project_id                UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    provider                  TEXT NOT NULL,
    repository_name           TEXT NOT NULL,
    repository_url_reference  TEXT NOT NULL,
    default_branch            TEXT NOT NULL DEFAULT 'main',
    visibility                TEXT NOT NULL DEFAULT 'PRIVATE',
    status                    core.record_status NOT NULL DEFAULT 'ACTIVE',
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE infrastructure.domains (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    domain_code        TEXT UNIQUE NOT NULL,
    asset_id           UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    project_id         UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    domain_reference   TEXT NOT NULL UNIQUE,
    provider           TEXT,
    status             core.record_status NOT NULL DEFAULT 'ACTIVE',
    ssl_status         infrastructure.ssl_status NOT NULL DEFAULT 'UNKNOWN',
    expiration_date    DATE,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE infrastructure.certificates (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    certificate_code   TEXT UNIQUE NOT NULL,
    domain_id          UUID NOT NULL REFERENCES infrastructure.domains(id) ON DELETE CASCADE,
    issuer             TEXT,
    valid_from         DATE,
    valid_until        DATE,
    status             infrastructure.ssl_status NOT NULL DEFAULT 'UNKNOWN',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE infrastructure.services (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_code    TEXT UNIQUE NOT NULL,
    asset_id        UUID NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE,
    project_id      UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    service_type    TEXT NOT NULL,
    version         TEXT,
    environment_id  UUID REFERENCES core.environments(id),
    server_id       UUID REFERENCES infrastructure.servers(id),
    status          core.record_status NOT NULL DEFAULT 'ACTIVE',
    health_status   infrastructure.health_status NOT NULL DEFAULT 'UNKNOWN',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_servers_asset ON infrastructure.servers (asset_id);
CREATE INDEX idx_servers_status ON infrastructure.servers (status);
CREATE INDEX idx_databases_project ON infrastructure.databases (project_id);
CREATE INDEX idx_databases_asset ON infrastructure.databases (asset_id);
CREATE INDEX idx_repositories_project ON infrastructure.repositories (project_id);
CREATE INDEX idx_domains_project ON infrastructure.domains (project_id);
CREATE INDEX idx_domains_expiration ON infrastructure.domains (expiration_date);
CREATE INDEX idx_certificates_domain ON infrastructure.certificates (domain_id);
CREATE INDEX idx_certificates_valid_until ON infrastructure.certificates (valid_until);
CREATE INDEX idx_services_project ON infrastructure.services (project_id);
CREATE INDEX idx_services_server ON infrastructure.services (server_id);
CREATE INDEX idx_services_health ON infrastructure.services (health_status);

-- Lookup-validation trigger attachments
CREATE TRIGGER trg_lookup_servers_provider
    BEFORE INSERT OR UPDATE OF provider ON infrastructure.servers
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('SERVER_PROVIDER_TYPE', 'provider');

CREATE TRIGGER trg_lookup_databases_engine
    BEFORE INSERT OR UPDATE OF engine ON infrastructure.databases
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('DATABASE_ENGINE', 'engine');
