-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P20 — Storage Buckets & Storage RLS
-- Source of truth: KEM-055 §11, KEM-053 §7.2 (DECISION LOCKED)
-- Depends on: P06 (core.projects), P08 (core.documents), P19 (RLS pattern established)
-- Depended on by: none structurally
-- NOTE: bucket creation is typically performed via the Supabase Management API or
-- dashboard, not raw SQL; the statement below is included for completeness/
-- idempotency where storage.buckets is directly writable.
-- =============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY documents_select ON storage.objects
    FOR SELECT
    USING (
        bucket_id = 'documents'
        AND identity.has_project_access(
            (SELECT id FROM core.projects WHERE project_code = (storage.foldername(name))[1])
        )
    );

CREATE POLICY documents_insert ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'documents'
        AND identity.has_project_access(
            (SELECT id FROM core.projects WHERE project_code = (storage.foldername(name))[1]),
            'WRITE'
        )
    );

-- Binary file content is never stored in PostgreSQL — no table in this migration set
-- has a bytea column (KEM-053 §7.2, DECISION LOCKED).
