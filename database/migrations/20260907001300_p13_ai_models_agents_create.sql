-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P13 — AI
-- Source of truth: KEM-055 §6.5, §7
-- Depends on: P02, P03, P06
-- Depended on by: none at MVP
-- =============================================================================

CREATE TABLE ai.models (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider       TEXT NOT NULL,
    model_name     TEXT NOT NULL,
    model_version  TEXT,
    capabilities   JSONB NOT NULL DEFAULT '[]'::jsonb,
    status         core.record_status NOT NULL DEFAULT 'ACTIVE',
    metadata       JSONB NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT uq_models_provider_name_version UNIQUE (provider, model_name, model_version)
);

CREATE TABLE ai.agents (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agent_code                TEXT UNIQUE NOT NULL,
    project_id                UUID REFERENCES core.projects(id) ON DELETE CASCADE,
    name                      TEXT NOT NULL,
    role                      TEXT NOT NULL,
    status                    core.record_status NOT NULL DEFAULT 'ACTIVE',
    model_id                  UUID REFERENCES ai.models(id),
    autonomy_level            ai.ai_autonomy_level NOT NULL DEFAULT 'L0_OBSERVE',
    owner_id                  UUID REFERENCES identity.users(id),
    service_account_user_id   UUID REFERENCES identity.users(id),
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_agents_l3_l4_require_owner CHECK (
        NOT (autonomy_level IN ('L3_APPROVAL_REQUIRED','L4_GUARDED_AUTONOMY') AND owner_id IS NULL)
    )
);

CREATE INDEX idx_agents_project ON ai.agents (project_id);
CREATE INDEX idx_agents_status ON ai.agents (status);
