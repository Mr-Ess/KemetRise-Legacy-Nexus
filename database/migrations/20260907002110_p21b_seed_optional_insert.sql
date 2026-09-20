-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P21b — Optional Seed Data (every environment, non-blocking)
-- Source of truth: KEM-055 §12.2, KEM-053 §13.2
-- Depends on: P21a
-- =============================================================================

INSERT INTO ai.models (provider, model_name, model_version, status) VALUES
    ('anthropic', 'claude', NULL, 'INACTIVE'),
    ('openai', 'gpt', NULL, 'INACTIVE')
ON CONFLICT (provider, model_name, model_version) DO NOTHING;

-- Reversal:
-- DELETE FROM ai.models WHERE provider IN ('anthropic','openai') AND status = 'INACTIVE';
