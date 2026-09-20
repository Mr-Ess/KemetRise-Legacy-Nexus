-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P08 — Core Documents
-- Source of truth: KEM-055 §6.2, §7
-- Depends on: P06, P07
-- Depended on by: P20 (Storage RLS)
-- =============================================================================

CREATE TABLE core.documents (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_code  TEXT UNIQUE NOT NULL,
    project_id     UUID REFERENCES core.projects(id) ON DELETE CASCADE,
    title          TEXT NOT NULL,
    doc_type       TEXT NOT NULL,
    version        TEXT NOT NULL DEFAULT '1.0.0',
    storage_path   TEXT NOT NULL,   -- Supabase Storage object path — never binary content
    status         core.record_status NOT NULL DEFAULT 'ACTIVE',
    classification TEXT NOT NULL DEFAULT 'INTERNAL',
    owner_id       UUID REFERENCES identity.users(id),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_documents_project ON core.documents (project_id);
