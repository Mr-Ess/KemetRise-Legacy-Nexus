-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P15 — Security (Secret References)
-- Source of truth: KEM-055 §6.5, §7, §16
-- Depends on: P06
-- Depended on by: none directly (no other table holds a literal FK to this table)
--
-- HARD RULE: this table stores REFERENCES/METADATA ONLY. No column below may ever
-- hold a raw API key, password, access token, private key, credential, or secret
-- value of any kind. Only a secret://... pointer is stored.
-- =============================================================================

CREATE TABLE security.secret_references (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reference_key   TEXT UNIQUE NOT NULL,
    project_id      UUID REFERENCES core.projects(id),
    environment_id  UUID REFERENCES core.environments(id),
    description     TEXT,
    managed_by      TEXT NOT NULL DEFAULT 'EXTERNAL',
    status          core.record_status NOT NULL DEFAULT 'ACTIVE',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_secret_refs_project ON security.secret_references (project_id);
