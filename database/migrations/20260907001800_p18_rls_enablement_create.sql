-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P18 — RLS Enablement
-- Source of truth: KEM-055 §10.1
-- Depends on: P03–P17 (every table and trigger must exist first)
-- Depended on by: P19
-- RLS is enabled on every table EXCEPT core.lookup_values. Between this migration
-- and P19, every table below is RLS-enabled with ZERO policies — default-deny.
-- 29 tables total.
-- =============================================================================

ALTER TABLE identity.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE identity.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE identity.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE identity.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE identity.user_roles ENABLE ROW LEVEL SECURITY;

ALTER TABLE core.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.environments ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.asset_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.asset_dependencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE core.documents ENABLE ROW LEVEL SECURITY;

ALTER TABLE infrastructure.servers ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastructure.databases ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastructure.repositories ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastructure.domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastructure.certificates ENABLE ROW LEVEL SECURITY;
ALTER TABLE infrastructure.services ENABLE ROW LEVEL SECURITY;

ALTER TABLE operations.deployments ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations.incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations.changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations.backups ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE operations.notifications ENABLE ROW LEVEL SECURITY;

ALTER TABLE automation.workflows ENABLE ROW LEVEL SECURITY;

ALTER TABLE ai.models ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai.agents ENABLE ROW LEVEL SECURITY;

ALTER TABLE finance.costs ENABLE ROW LEVEL SECURITY;

ALTER TABLE security.secret_references ENABLE ROW LEVEL SECURITY;

ALTER TABLE audit.audit_events ENABLE ROW LEVEL SECURITY;

-- core.lookup_values intentionally NOT RLS-enabled (sole documented exception).
