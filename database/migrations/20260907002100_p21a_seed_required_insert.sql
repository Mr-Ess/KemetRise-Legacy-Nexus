-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P21a — Required Seed Data (every environment: dev, staging, production)
-- Source of truth: KEM-055 §12.1, §12.4 (R-02 — natural-key based, no seed_batch_id
-- column); KEM-053 §6.2 (lookup categories), §13.1 (roles/permissions)
-- Depends on: every structural migration (P00–P20)
--
-- ARCHITECTURAL DECISION (Option A, approved by Mr. Ess): PRJ-000 is NOT inserted
-- here. core.projects.owner_id is NOT NULL with no default (KEM-053 §7.2, unchanged),
-- and no real identity.users row exists at pure-migration time. PRJ-000 is created
-- exclusively via Phase 3 of the Bootstrap Lifecycle (KEM-055 §17), invoked through
-- core.bootstrap_control_tower_project() (migration P06C), only after a real System
-- Admin exists. No zero UUID, sentinel user, or placeholder owner_id is used anywhere
-- in this file.
--
-- Idempotent: every INSERT uses ON CONFLICT on the table's own natural key.
-- Reversal (where the phase's tier, KEM-054 §17/§18, permits it): natural-key-scoped
-- DELETE statements are given in comments at the end of this file — no stored batch
-- identifier is used (R-02).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- core.lookup_values — MUST precede any dependent trigger-validated column use
-- -----------------------------------------------------------------------------
INSERT INTO core.lookup_values (category, value, label) VALUES
    ('PROJECT_CATEGORY','SAAS','SaaS'),
    ('PROJECT_CATEGORY','AI','AI'),
    ('PROJECT_CATEGORY','AUTOMATION','Automation'),
    ('PROJECT_CATEGORY','ECOMMERCE','E-Commerce'),
    ('PROJECT_CATEGORY','EDUCATION','Education'),
    ('PROJECT_CATEGORY','HEALTHCARE','Healthcare'),
    ('PROJECT_CATEGORY','REAL_ESTATE','Real Estate'),
    ('PROJECT_CATEGORY','MEDIA','Media'),
    ('PROJECT_CATEGORY','FINTECH','Fintech'),
    ('PROJECT_CATEGORY','INTERNAL','Internal'),
    ('PROJECT_CATEGORY','EXPERIMENTAL','Experimental'),

    ('ASSET_TYPE','SERVER','Server'),
    ('ASSET_TYPE','DATABASE','Database'),
    ('ASSET_TYPE','REPOSITORY','Repository'),
    ('ASSET_TYPE','DOMAIN','Domain'),
    ('ASSET_TYPE','SERVICE','Service'),
    ('ASSET_TYPE','STORAGE','Storage'),
    ('ASSET_TYPE','CERTIFICATE','Certificate'),
    ('ASSET_TYPE','API','API'),
    ('ASSET_TYPE','WORKFLOW','Workflow'),
    ('ASSET_TYPE','AI_AGENT','AI Agent'),
    ('ASSET_TYPE','MODEL','Model'),
    ('ASSET_TYPE','DOCUMENT','Document'),
    ('ASSET_TYPE','OTHER','Other'),

    ('COST_TYPE','INFRASTRUCTURE','Infrastructure'),
    ('COST_TYPE','DATABASE','Database'),
    ('COST_TYPE','STORAGE','Storage'),
    ('COST_TYPE','DOMAIN','Domain'),
    ('COST_TYPE','API','API'),
    ('COST_TYPE','AI','AI'),
    ('COST_TYPE','AUTOMATION','Automation'),
    ('COST_TYPE','SOFTWARE','Software'),
    ('COST_TYPE','OTHER','Other'),

    ('SERVER_PROVIDER_TYPE','VPS_PROVIDER','VPS Provider'),
    ('SERVER_PROVIDER_TYPE','CLOUD_PROVIDER','Cloud Provider'),
    ('SERVER_PROVIDER_TYPE','DEDICATED_HOST','Dedicated Host'),
    ('SERVER_PROVIDER_TYPE','ON_PREMISE','On-Premise'),

    ('DATABASE_ENGINE','POSTGRESQL','PostgreSQL'),
    ('DATABASE_ENGINE','MYSQL','MySQL'),
    ('DATABASE_ENGINE','MARIADB','MariaDB'),
    ('DATABASE_ENGINE','MONGODB','MongoDB'),
    ('DATABASE_ENGINE','REDIS','Redis'),
    ('DATABASE_ENGINE','SQLITE','SQLite'),
    ('DATABASE_ENGINE','OTHER','Other'),

    ('EVENT_TYPE','PROJECT_CREATED','Project Created'),
    ('EVENT_TYPE','ASSET_CREATED','Asset Created'),
    ('EVENT_TYPE','DEPLOYMENT_STARTED','Deployment Started'),
    ('EVENT_TYPE','DEPLOYMENT_FAILED','Deployment Failed'),
    ('EVENT_TYPE','BACKUP_FAILED','Backup Failed'),
    ('EVENT_TYPE','SERVER_UNHEALTHY','Server Unhealthy'),
    ('EVENT_TYPE','DOMAIN_EXPIRING','Domain Expiring'),
    ('EVENT_TYPE','CERTIFICATE_EXPIRING','Certificate Expiring'),

    ('DRIFT_SEVERITY','INFO','Info'),
    ('DRIFT_SEVERITY','WARNING','Warning'),
    ('DRIFT_SEVERITY','CRITICAL','Critical')
ON CONFLICT (category, value) DO NOTHING;

-- -----------------------------------------------------------------------------
-- identity.roles — 9 roles (KEM-053 §9.4)
-- -----------------------------------------------------------------------------
INSERT INTO identity.roles (role_code, name, is_system) VALUES
    ('SUPER_ADMIN', 'Super Administrator', true),
    ('ADMIN', 'Administrator', true),
    ('PROJECT_MANAGER', 'Project Manager', true),
    ('DEVELOPER', 'Developer', true),
    ('DEVOPS', 'DevOps', true),
    ('SECURITY', 'Security', true),
    ('VIEWER', 'Viewer', true),
    ('AI_AGENT', 'AI Agent', true),
    ('SERVICE_ACCOUNT', 'Service Account', true)
ON CONFLICT (role_code) DO NOTHING;

-- -----------------------------------------------------------------------------
-- identity.permissions — baseline CRUD permission set per resource (KEM-053 §13.1)
-- -----------------------------------------------------------------------------
INSERT INTO identity.permissions (permission_code, resource, action) VALUES
    ('projects.read','projects','read'), ('projects.create','projects','create'),
    ('projects.update','projects','update'), ('projects.archive','projects','archive'),
    ('assets.read','assets','read'), ('assets.create','assets','create'),
    ('assets.update','assets','update'), ('assets.archive','assets','archive'),
    ('environments.read','environments','read'), ('environments.create','environments','create'),
    ('environments.update','environments','update'),
    ('deployments.read','deployments','read'), ('deployments.create','deployments','create'),
    ('deployments.execute','deployments','execute'), ('deployments.rollback','deployments','rollback'),
    ('incidents.read','incidents','read'), ('incidents.create','incidents','create'),
    ('incidents.update','incidents','update'), ('incidents.assign','incidents','assign'),
    ('incidents.resolve','incidents','resolve'), ('incidents.close','incidents','close'),
    ('changes.read','changes','read'), ('changes.create','changes','create'),
    ('changes.approve','changes','approve'), ('changes.reject','changes','reject'),
    ('backups.read','backups','read'), ('backups.create','backups','create'),
    ('automations.read','automations','read'), ('automations.create','automations','create'),
    ('automations.update','automations','update'), ('automations.execute','automations','execute'),
    ('ai.read','ai','read'), ('ai.create','ai','create'), ('ai.update','ai','update'),
    ('finance.read','finance','read'), ('finance.create','finance','create'),
    ('audit.read','audit','read'),
    ('identity.read','identity','read'), ('identity.create','identity','create'),
    ('identity.update','identity','update')
ON CONFLICT (resource, action) DO NOTHING;

-- -----------------------------------------------------------------------------
-- identity.role_permissions — SUPER_ADMIN gets every permission (KEM-053 §13.1)
-- -----------------------------------------------------------------------------
INSERT INTO identity.role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM identity.roles r
CROSS JOIN identity.permissions p
WHERE r.role_code = 'SUPER_ADMIN'
ON CONFLICT (role_id, permission_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Reversal (natural-key scoped, R-02 — no seed_batch_id column):
--
-- DELETE FROM identity.role_permissions WHERE role_id IN (SELECT id FROM identity.roles WHERE role_code = 'SUPER_ADMIN');
-- DELETE FROM identity.permissions WHERE permission_code IN ( <the 40 codes above> );
-- DELETE FROM identity.roles WHERE role_code IN ('SUPER_ADMIN','ADMIN','PROJECT_MANAGER','DEVELOPER','DEVOPS','SECURITY','VIEWER','AI_AGENT','SERVICE_ACCOUNT');
-- DELETE FROM core.lookup_values WHERE category IN ('PROJECT_CATEGORY','ASSET_TYPE','COST_TYPE','SERVER_PROVIDER_TYPE','DATABASE_ENGINE','EVENT_TYPE','DRIFT_SEVERITY');
-- (Required seed is not reversed in a live environment without a replacement plan —
-- KEM-054 §17, Tier 5 — this reversal is intended for a dev/test rebuild, not production.)
-- =============================================================================
