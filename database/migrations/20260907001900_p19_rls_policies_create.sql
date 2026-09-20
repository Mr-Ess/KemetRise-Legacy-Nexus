-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P19 — RLS Policies
-- Source of truth: KEM-055 §10.2 (baseline pattern), §10.3 (per-table instantiation)
-- Depends on: P04 (helper functions), P18 (RLS enabled, zero policies)
-- Depended on by: P20 (Storage RLS mirrors this logic)
-- =============================================================================

-- identity.users — full deviation (identity table, not project-scoped)
CREATE POLICY users_select ON identity.users
    FOR SELECT
    USING ( id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );
CREATE POLICY users_update ON identity.users
    FOR UPDATE
    USING ( id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

-- identity.roles / permissions / role_permissions — global reference tables
CREATE POLICY roles_select ON identity.roles FOR SELECT USING ( true );
CREATE POLICY roles_write ON identity.roles FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

CREATE POLICY permissions_select ON identity.permissions FOR SELECT USING ( true );
CREATE POLICY permissions_write ON identity.permissions FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

CREATE POLICY role_permissions_select ON identity.role_permissions FOR SELECT USING ( true );
CREATE POLICY role_permissions_write ON identity.role_permissions FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

-- identity.user_roles — grants are never self-service
CREATE POLICY user_roles_select ON identity.user_roles
    FOR SELECT
    USING (
        user_id = identity.current_user_id()
        OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (scope_project_id IS NOT NULL AND identity.has_project_access(scope_project_id))
    );
CREATE POLICY user_roles_write ON identity.user_roles FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

-- core.projects — path is `id` itself (root of scope)
CREATE POLICY projects_select ON core.projects
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(id) );
CREATE POLICY projects_insert ON core.projects
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );
CREATE POLICY projects_update ON core.projects
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(id, 'WRITE') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(id, 'WRITE') );
CREATE POLICY projects_delete ON core.projects
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- Baseline, unmodified (direct project_id column)
CREATE POLICY environments_select ON core.environments FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY environments_insert ON core.environments FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY environments_update ON core.environments FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY environments_delete ON core.environments FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY assets_select ON core.assets FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
CREATE POLICY assets_insert ON core.assets FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY assets_update ON core.assets FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY assets_delete ON core.assets FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY documents_meta_select ON core.documents FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
CREATE POLICY documents_meta_insert ON core.documents FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY documents_meta_update ON core.documents FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY documents_meta_delete ON core.documents FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY asset_projects_select ON core.asset_projects FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY asset_projects_insert ON core.asset_projects FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY asset_projects_delete ON core.asset_projects FOR DELETE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );

CREATE POLICY databases_select ON infrastructure.databases FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY databases_insert ON infrastructure.databases FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY databases_update ON infrastructure.databases FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY databases_delete ON infrastructure.databases FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY repositories_select ON infrastructure.repositories FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY repositories_insert ON infrastructure.repositories FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY repositories_update ON infrastructure.repositories FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY repositories_delete ON infrastructure.repositories FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY domains_select ON infrastructure.domains FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY domains_insert ON infrastructure.domains FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY domains_update ON infrastructure.domains FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY domains_delete ON infrastructure.domains FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY services_select ON infrastructure.services FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY services_insert ON infrastructure.services FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY services_update ON infrastructure.services FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY services_delete ON infrastructure.services FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY deployments_select ON operations.deployments FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY deployments_insert ON operations.deployments FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY deployments_update ON operations.deployments FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY deployments_delete ON operations.deployments FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY incidents_select ON operations.incidents FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY incidents_insert ON operations.incidents FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY incidents_update ON operations.incidents FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY incidents_delete ON operations.incidents FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY changes_select ON operations.changes FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY changes_insert ON operations.changes FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY changes_update ON operations.changes FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY changes_delete ON operations.changes FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY backups_select ON operations.backups FOR SELECT USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id) );
CREATE POLICY backups_insert ON operations.backups FOR INSERT WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY backups_update ON operations.backups FOR UPDATE USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') ) WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY backups_delete ON operations.backups FOR DELETE USING ( identity.has_role('SUPER_ADMIN') );

-- core.asset_dependencies — path via source_asset_id -> core.assets.project_id
CREATE POLICY asset_dependencies_select ON core.asset_dependencies
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = source_asset_id) ) );
CREATE POLICY asset_dependencies_insert ON core.asset_dependencies
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = source_asset_id), 'WRITE' ) );
CREATE POLICY asset_dependencies_update ON core.asset_dependencies
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = source_asset_id), 'WRITE' ) )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = source_asset_id), 'WRITE' ) );
CREATE POLICY asset_dependencies_delete ON core.asset_dependencies
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- infrastructure.servers — path via asset_id -> core.assets.project_id
CREATE POLICY servers_select ON infrastructure.servers
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = asset_id) ) );
CREATE POLICY servers_insert ON infrastructure.servers
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = asset_id), 'WRITE' ) );
CREATE POLICY servers_update ON infrastructure.servers
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = asset_id), 'WRITE' ) )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM core.assets WHERE id = asset_id), 'WRITE' ) );
CREATE POLICY servers_delete ON infrastructure.servers
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- infrastructure.certificates — path via domain_id -> infrastructure.domains.project_id
CREATE POLICY certificates_select ON infrastructure.certificates
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM infrastructure.domains WHERE id = domain_id) ) );
CREATE POLICY certificates_insert ON infrastructure.certificates
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM infrastructure.domains WHERE id = domain_id), 'WRITE' ) );
CREATE POLICY certificates_update ON infrastructure.certificates
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM infrastructure.domains WHERE id = domain_id), 'WRITE' ) )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR identity.has_project_access( (SELECT project_id FROM infrastructure.domains WHERE id = domain_id), 'WRITE' ) );
CREATE POLICY certificates_delete ON infrastructure.certificates
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- operations.events — direct project_id, NULLABLE (null rows: admin only)
CREATE POLICY events_select ON operations.events
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
CREATE POLICY events_insert ON operations.events
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );

-- operations.notifications — user-scoped, not project-scoped
CREATE POLICY notifications_select ON operations.notifications
    FOR SELECT
    USING ( recipient_id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );
CREATE POLICY notifications_update ON operations.notifications
    FOR UPDATE
    USING ( recipient_id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( recipient_id = identity.current_user_id() OR identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

-- automation.workflows / ai.agents — direct project_id, NULLABLE
CREATE POLICY workflows_select ON automation.workflows
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
CREATE POLICY workflows_insert ON automation.workflows
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY workflows_update ON automation.workflows
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY workflows_delete ON automation.workflows
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

CREATE POLICY agents_select ON ai.agents
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
CREATE POLICY agents_insert ON ai.agents
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY agents_update ON ai.agents
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id, 'WRITE')) );
CREATE POLICY agents_delete ON ai.agents
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- ai.models — global catalog
CREATE POLICY models_select ON ai.models FOR SELECT USING ( true );
CREATE POLICY models_write ON ai.models FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') );

-- finance.costs — baseline + additive SELECT for SECURITY role (KEM-053 §9.4)
CREATE POLICY costs_select ON finance.costs
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_role('SECURITY')
        OR identity.has_project_access(project_id) );
CREATE POLICY costs_insert ON finance.costs
    FOR INSERT
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY costs_update ON finance.costs
    FOR UPDATE
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_project_access(project_id, 'WRITE') );
CREATE POLICY costs_delete ON finance.costs
    FOR DELETE
    USING ( identity.has_role('SUPER_ADMIN') );

-- security.secret_references — SECURITY/ADMIN/SUPER_ADMIN only, all operations
CREATE POLICY secret_references_all ON security.secret_references
    FOR ALL
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_role('SECURITY') )
    WITH CHECK ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN') OR identity.has_role('SECURITY') );

-- audit.audit_events — append-only. SELECT only; NO INSERT/UPDATE/DELETE policy for
-- any role, including SUPER_ADMIN (writes happen exclusively via the SECURITY
-- DEFINER audit.trigger_audit_event() trigger function, P16).
CREATE POLICY audit_events_select ON audit.audit_events
    FOR SELECT
    USING ( identity.has_role('SUPER_ADMIN') OR identity.has_role('ADMIN')
        OR (project_id IS NOT NULL AND identity.has_project_access(project_id)) );
