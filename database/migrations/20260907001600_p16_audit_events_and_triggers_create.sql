-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P16 — Audit
-- Source of truth: KEM-055 §6.5, §7, §8, §9, §16
-- Depends on: P03–P15 (every governed table must already exist)
-- Depended on by: none downstream (terminal write target)
-- 23 governed tables (identity: 3, core: 5, infrastructure: 6, operations: 4,
-- automation: 1, ai: 2, finance: 1, security: 1) — core.lookup_values is treated as
-- an implicit exclusion (public governed reference data, same as its RLS exclusion),
-- as are operations.events/notifications, core.asset_projects, identity.role_
-- permissions/user_roles (logged at their owning-entity level), and audit.audit_events
-- itself.
-- =============================================================================

CREATE TABLE audit.audit_events (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id       UUID REFERENCES identity.users(id),
    action         TEXT NOT NULL,
    resource_type  TEXT NOT NULL,
    resource_id    UUID NOT NULL,
    project_id     UUID REFERENCES core.projects(id),
    "timestamp"    TIMESTAMPTZ NOT NULL DEFAULT now(),
    result         TEXT NOT NULL DEFAULT 'SUCCESS',
    metadata       JSONB NOT NULL DEFAULT '{}'::jsonb
);

REVOKE UPDATE, DELETE ON audit.audit_events FROM PUBLIC;

CREATE INDEX idx_audit_resource ON audit.audit_events (resource_type, resource_id);
CREATE INDEX idx_audit_project ON audit.audit_events (project_id);
CREATE INDEX idx_audit_timestamp ON audit.audit_events ("timestamp");
CREATE INDEX idx_audit_actor ON audit.audit_events (actor_id);

-- -----------------------------------------------------------------------------
-- Generic audit trigger function. Writes one audit.audit_events row per statement-
-- row with an action/resource_type/resource_id/metadata diff. Fail-closed: if the
-- audit write itself fails, the triggering statement is aborted.
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION audit.trigger_audit_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = audit, pg_temp
AS $$
DECLARE
    v_action       TEXT;
    v_resource_id  UUID;
    v_project_id   UUID;
    v_metadata     JSONB;
BEGIN
    IF TG_OP = 'INSERT' THEN
        v_action := 'CREATE';
        v_resource_id := NEW.id;
        v_metadata := jsonb_build_object('new', to_jsonb(NEW));
        v_project_id := NULLIF(to_jsonb(NEW) ->> 'project_id', '')::UUID;
    ELSIF TG_OP = 'UPDATE' THEN
        v_action := 'UPDATE';
        v_resource_id := NEW.id;
        v_metadata := jsonb_build_object('old', to_jsonb(OLD), 'new', to_jsonb(NEW));
        v_project_id := NULLIF(to_jsonb(NEW) ->> 'project_id', '')::UUID;
    ELSIF TG_OP = 'DELETE' THEN
        v_action := 'DELETE';
        v_resource_id := OLD.id;
        v_metadata := jsonb_build_object('old', to_jsonb(OLD));
        v_project_id := NULLIF(to_jsonb(OLD) ->> 'project_id', '')::UUID;
    END IF;

    INSERT INTO audit.audit_events (actor_id, action, resource_type, resource_id, project_id, metadata)
    VALUES (identity.current_user_id(), v_action, TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME,
            v_resource_id, v_project_id, v_metadata);

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- Attach to all 23 governed tables
-- -----------------------------------------------------------------------------

CREATE TRIGGER trg_audit_identity_users AFTER INSERT OR UPDATE OR DELETE ON identity.users FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_identity_roles AFTER INSERT OR UPDATE OR DELETE ON identity.roles FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_identity_permissions AFTER INSERT OR UPDATE OR DELETE ON identity.permissions FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_core_projects AFTER INSERT OR UPDATE OR DELETE ON core.projects FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_core_environments AFTER INSERT OR UPDATE OR DELETE ON core.environments FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_core_assets AFTER INSERT OR UPDATE OR DELETE ON core.assets FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_core_asset_dependencies AFTER INSERT OR UPDATE OR DELETE ON core.asset_dependencies FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_core_documents AFTER INSERT OR UPDATE OR DELETE ON core.documents FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_infrastructure_servers AFTER INSERT OR UPDATE OR DELETE ON infrastructure.servers FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_infrastructure_databases AFTER INSERT OR UPDATE OR DELETE ON infrastructure.databases FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_infrastructure_repositories AFTER INSERT OR UPDATE OR DELETE ON infrastructure.repositories FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_infrastructure_domains AFTER INSERT OR UPDATE OR DELETE ON infrastructure.domains FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_infrastructure_certificates AFTER INSERT OR UPDATE OR DELETE ON infrastructure.certificates FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_infrastructure_services AFTER INSERT OR UPDATE OR DELETE ON infrastructure.services FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_operations_deployments AFTER INSERT OR UPDATE OR DELETE ON operations.deployments FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_operations_incidents AFTER INSERT OR UPDATE OR DELETE ON operations.incidents FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_operations_changes AFTER INSERT OR UPDATE OR DELETE ON operations.changes FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_operations_backups AFTER INSERT OR UPDATE OR DELETE ON operations.backups FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_automation_workflows AFTER INSERT OR UPDATE OR DELETE ON automation.workflows FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_ai_models AFTER INSERT OR UPDATE OR DELETE ON ai.models FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
CREATE TRIGGER trg_audit_ai_agents AFTER INSERT OR UPDATE OR DELETE ON ai.agents FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_finance_costs AFTER INSERT OR UPDATE OR DELETE ON finance.costs FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();

CREATE TRIGGER trg_audit_security_secret_references AFTER INSERT OR UPDATE OR DELETE ON security.secret_references FOR EACH ROW EXECUTE FUNCTION audit.trigger_audit_event();
