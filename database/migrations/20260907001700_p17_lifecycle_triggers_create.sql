-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P17 — Lifecycle Triggers (updated_at / archived_at maintenance)
-- Source of truth: KEM-055 §6, §8, §9
-- Depends on: P03–P15
-- Depended on by: none
-- updated_at applies to 12 tables (the only ones whose DDL actually declares the
-- column): identity.users; core.projects, core.environments, core.assets,
-- core.documents; infrastructure.servers, infrastructure.databases,
-- infrastructure.repositories, infrastructure.domains, infrastructure.services;
-- automation.workflows; ai.agents. archived_at applies to 3 tables: identity.users,
-- core.projects, core.assets (the only ones with both status and archived_at).
-- =============================================================================

CREATE OR REPLACE FUNCTION core.trigger_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_temp
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION core.trigger_set_archived_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = pg_temp
AS $$
BEGIN
    IF NEW.status = 'ARCHIVED' AND (OLD.status IS DISTINCT FROM 'ARCHIVED') THEN
        NEW.archived_at := now();
    END IF;
    RETURN NEW;
END;
$$;

-- updated_at triggers (12 tables)
CREATE TRIGGER trg_updated_at_identity_users BEFORE UPDATE ON identity.users FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_core_projects BEFORE UPDATE ON core.projects FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_core_environments BEFORE UPDATE ON core.environments FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_core_assets BEFORE UPDATE ON core.assets FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_core_documents BEFORE UPDATE ON core.documents FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_infrastructure_servers BEFORE UPDATE ON infrastructure.servers FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_infrastructure_databases BEFORE UPDATE ON infrastructure.databases FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_infrastructure_repositories BEFORE UPDATE ON infrastructure.repositories FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_infrastructure_domains BEFORE UPDATE ON infrastructure.domains FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_infrastructure_services BEFORE UPDATE ON infrastructure.services FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_automation_workflows BEFORE UPDATE ON automation.workflows FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();
CREATE TRIGGER trg_updated_at_ai_agents BEFORE UPDATE ON ai.agents FOR EACH ROW EXECUTE FUNCTION core.trigger_set_updated_at();

-- archived_at triggers (3 tables)
CREATE TRIGGER trg_archived_at_identity_users BEFORE UPDATE OF status ON identity.users FOR EACH ROW EXECUTE FUNCTION core.trigger_set_archived_at();
CREATE TRIGGER trg_archived_at_core_projects BEFORE UPDATE OF status ON core.projects FOR EACH ROW EXECUTE FUNCTION core.trigger_set_archived_at();
CREATE TRIGGER trg_archived_at_core_assets BEFORE UPDATE OF status ON core.assets FOR EACH ROW EXECUTE FUNCTION core.trigger_set_archived_at();
