-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P06B — Identity Scope FK Add
-- Source of truth: KEM-055 §2, §20 (OQ-01, APPROVED by Mr. Ess)
-- Depends on: P03 (identity.user_roles table), P06 (core.projects table)
-- Depended on by: P19, P21
-- No forced ordering vs P06C: both depend only on P06 (and P06C also on P04); neither
-- touches the other's object. P06B precedes P06C by naming/historical convention only.
-- =============================================================================

ALTER TABLE identity.user_roles
    ADD CONSTRAINT fk_user_roles_scope_project
    FOREIGN KEY (scope_project_id) REFERENCES core.projects(id);
