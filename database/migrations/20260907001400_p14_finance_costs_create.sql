-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P14 — Finance
-- Source of truth: KEM-055 §6.5, §7, §8, §9
-- Depends on: P03, P05, P06, P07
-- Depended on by: none at MVP
-- =============================================================================

CREATE TABLE finance.costs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cost_code       TEXT UNIQUE,
    project_id      UUID NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE,
    asset_id        UUID REFERENCES core.assets(id),
    provider        TEXT,
    cost_type       TEXT NOT NULL,   -- trigger-validated: lookup_values('COST_TYPE')
    amount          NUMERIC(14,2) NOT NULL,
    currency        CHAR(3) NOT NULL DEFAULT 'USD',
    billing_period  DATERANGE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'RECORDED',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_costs_amount_nonnegative CHECK (amount >= 0)
);

CREATE INDEX idx_costs_project ON finance.costs (project_id);
CREATE INDEX idx_costs_billing_period ON finance.costs USING GIST (billing_period);

-- Lookup-validation trigger attachment
CREATE TRIGGER trg_lookup_costs_type
    BEFORE INSERT OR UPDATE OF cost_type ON finance.costs
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('COST_TYPE', 'cost_type');
