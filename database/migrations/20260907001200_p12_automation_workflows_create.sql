-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P12 — Automation
-- Source of truth: KEM-055 §6.5, §7
-- Depends on: P03, P06
-- Depended on by: none at MVP
-- =============================================================================

CREATE TABLE automation.workflows (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workflow_code   TEXT UNIQUE NOT NULL,
    project_id      UUID REFERENCES core.projects(id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    engine          TEXT NOT NULL DEFAULT 'N8N',
    trigger_type    TEXT NOT NULL,
    purpose         TEXT,
    status          core.record_status NOT NULL DEFAULT 'ACTIVE',
    version         TEXT NOT NULL DEFAULT '1.0.0',
    owner_id        UUID REFERENCES identity.users(id),
    n8n_reference   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_workflows_project ON automation.workflows (project_id);
CREATE INDEX idx_workflows_status ON automation.workflows (status);
