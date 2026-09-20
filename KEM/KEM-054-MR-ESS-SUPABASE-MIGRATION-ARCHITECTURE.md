# KEM-054-MR-ESS-SUPABASE-MIGRATION-ARCHITECTURE.md

# KemetRise — Legacy Nexus

## MR.ESS Project Operating System

### SUPABASE MIGRATION ARCHITECTURE & SQL DESIGN SPECIFICATION

**Document ID:** KEM-054
**System ID:** MR-ESS-POS
**Parent System:** KemetRise — Legacy Nexus
**System Role:** Control Tower — Database Migration Architecture Layer
**Owner:** MR.ESS
**Version:** 1.2.0
**Status:** APPROVED — READY FOR SQL GENERATION (pending explicit authorization to begin)
**Date:** 2026-09-03
**Direct Parent:** KEM-053 (Supabase Database Implementation Specification, v1.2.0, APPROVED)
**Structural Parents:** KEM-052 (Technical Architecture), KEM-051 (Master Implementation Blueprint)

**Revision note (v1.1.0):** Three REQUIRES REVIEW items from v1.0.0 are resolved and locked: (1) enum types are schema-qualified per domain, never placed in `public`; (2) lookup-value validation is confirmed as trigger-based, fully documented; (3) `pg_trgm` is explicitly DEFERRED — SEARCH-DEPENDENT EXTENSION, not part of the foundation migration set. A dependency-order defect is corrected: schema creation (P01) now precedes enum creation (P02), since schema-qualified enums cannot be created before their target schema exists. All phase numbering from P03 onward is unchanged — only P01 and P02 swap. Every cross-reference to phase order, enum placement, and the dependency graph has been re-verified against this corrected order, not merely renumbered. No SQL was generated or executed in producing this revision. No file outside `/KEM/KEM-053-...` and this document was modified.

**Revision note (v1.2.0):** Resolves **NEW-01**, the discrepancy logged in KEM-055's conflict register: static validation of the generated SQL (a separate, later task) found that `core.projects.owner_id` (`NOT NULL`, no default) cannot be populated for `PRJ-000` by pure SQL, since no real `identity.users` row exists at migration time. Mr. Ess adopted **Option A — Bootstrap Sequencing Correction** (KEM-052 §186's existing, unmodified bootstrap order: System Admin before Control Tower System Record). This revision synchronizes KEM-054 with that decision and with KEM-055 v1.2.0. While reconciling, this document was also found to never have recorded **P06B** (`OQ-01`'s FK-timing fix for `identity.user_roles.scope_project_id`, approved earlier but left KEM-055-only at the time) — since P06C's correct position (`P03 → P06 → P06B → P06C → P07`, per the actual file timestamps in `/database/migrations/`) cannot be stated truthfully without it, **both P06B and P06C are added in this revision**. A new **Section 9-BIS — Bootstrap Lifecycle (Three-Phase Model)** documents the full Phase 1/2/3 split; P21's description is corrected to state explicitly that it does **not** create PRJ-000. Historical v1.1.0 content is preserved — nothing is deleted, only extended and corrected where it assumed PRJ-000 was ordinary seed data. **No SQL, and no KEM-052/053/055 file, was modified to produce this revision** — only this document. Schemas, tables, enums, FK architecture, RLS architecture, rollback tiers, non-PRJ-000 seed strategy, storage architecture, and naming conventions are unchanged.

---

# 0. PURPOSE AND BOUNDARY

KEM-053 defines **what** the database is (schemas, tables, columns, RLS strategy, seed data).

**KEM-054 defines *how* the database gets built, in what order, safely, verifiably, and reversibly — without yet writing a single executable `.sql` file, without connecting to any live Supabase project, and without running any statement.**

This document is a **migration architecture and SQL design specification**. Every phase below describes exactly what a future migration file will contain and why it must run in that position — it does not contain runnable migration files themselves. That is explicitly reserved for a future, separately-authorized artifact.

**Hard boundary restated:** producing this document did not connect to, query, or modify any live Supabase project; did not execute any SQL, DDL, or DML; did not create any `.sql` file; did not create application/frontend/backend code; and did not modify KEM-000 through KEM-052.

---

# 1. MIGRATION PHILOSOPHY

```text
1. Deterministic     — the same migration sequence, run twice from empty, produces an
                        identical schema. No manual steps, no "run this by hand first."
2. Additive-first     — every migration adds; nothing destructive runs without a
                        dedicated, separately-reviewed migration of its own.
3. Small and single-purpose — one migration file changes one coherent thing (one table,
                        one policy set, one trigger family) so failures are easy to isolate.
4. Forward-auditable  — every migration is version-controlled, timestamped, and captured
                        in Supabase's own schema_migrations history — never applied by
                        hand against a running database.
5. RLS-closed by default — a table is never left without RLS enabled for longer than the
                        single migration that creates it; enabling RLS is not deferred
                        to "later."
6. No secrets, ever   — no migration file may contain a credential, key, token, or
                        password, per KEM-053 §7.9's hard rule. Seed data containing
                        anything secret-shaped is rejected at review, not just at runtime.
7. Reversible where the object allows it — every migration has a stated rollback
                        approach (Section 17), even where "rollback" means restore-from-
                        backup rather than a clean DOWN script (Section 18).
```

This philosophy governs every phase in Section 9 (Phase Inventory) without exception.

---

# 2. MIGRATION DIRECTORY STRUCTURE

```text
/supabase
  /migrations
    <timestamp>_<phase>_<description>.sql        ← forward migration files (future artifact)
  /seed
    seed_required.sql                             ← required seed data (Section 16.1)
    seed_optional.sql                              ← optional seed data (Section 16.2)
    seed_development.sql                            ← dev/test-only fixtures (Section 16.3, never applied to prod)
  /policies
    <schema>_<table>_policies.sql                    ← RLS policy definitions, one file per table
                                                        (referenced by, not duplicated in, the
                                                        table-creation migration — see Section 14)
  /functions
    identity_current_user_id.sql
    identity_has_role.sql
    identity_has_permission.sql
    identity_has_project_access.sql
    trigger_set_updated_at.sql
    trigger_set_archived_at.sql
    trigger_audit_event.sql
  /storage
    storage_buckets.sql
    storage_policies.sql
  /tests
    <phase>_test.sql                                  ← per-phase validation queries (Section 22)
  /docs
    KEM-054-MIGRATION-MAP.md                            ← generated index mirroring Section 9 (future artifact)
```

This directory structure is itself **not yet created** — it is the target layout the future SQL-generation phase must follow. `/supabase/migrations` is the Supabase CLI's conventional path and is adopted as-is for compatibility (Section 28).

---

# 3. MIGRATION NAMING CONVENTION

```text
<YYYYMMDDHHMMSS>_<phase_number>_<domain>_<object>_<action>.sql

Examples (illustrative — not yet created):
20260903090000_p00_core_extensions_create.sql
20260903090100_p01_core_enums_create.sql
20260903090200_p02_schemas_create.sql
20260903090300_p03_identity_users_create.sql
20260903091500_p18_all_rls_enable.sql
20260903091600_p19_identity_users_policies_create.sql
20260903092000_p21_seed_required_insert.sql
```

```text
Timestamp   → UTC, sortable, guarantees execution order matches filename order
                (matches Supabase CLI convention exactly — no custom ordering table needed)
phase_number → zero-padded phase id (p00–p21) matching Section 9 Phase Inventory, so a
                reviewer can map any filename straight back to this document
domain       → schema/domain the migration targets (identity, core, infrastructure, …)
object        → table/function/policy family affected
action         → create | alter | drop | seed | backfill (never abbreviated or omitted)
```

No migration file name is ever reused, edited retroactively, or renumbered after being applied — a mistake is corrected by a new forward migration, never by rewriting history (Section 1, principle 4).

---

# 4. EXACT MIGRATION DEPENDENCY ORDER

This is the authoritative, phase-level order. It expands and supersedes the 35-step list in KEM-053 §10 without contradicting it — every KEM-053 step maps onto exactly one phase below (mapping given per-phase in Section 9).

```text
P00  Preflight & Extensions
P01  Schema Creation
P02  Enum Types
P03  Identity Core (users, roles, permissions, role_permissions, user_roles)
P04  Identity Helper Functions
P05  Lookup Values (core.lookup_values)
P06  Core Project Model (projects, environments)
P06B Identity Scope FK Add — adds identity.user_roles.scope_project_id FK to core.projects
     (OQ-01, resolves the P03→P06 forward-reference that could not be a same-migration FK)
P06C Control Tower Bootstrap Function — defines core.bootstrap_control_tower_project()
     ONLY (does NOT create PRJ-000; see Section 9-BIS, Bootstrap Lifecycle)
P07  Core Asset Model (assets, asset_projects, asset_dependencies)
P08  Core Documents
P09  Infrastructure Registry (servers, databases, repositories, domains, certificates, services)
P10  Operations Registry (deployments, incidents, changes, backups)
P11  Operations Events & Notifications
P12  Automation (workflows)
P13  AI (models, agents)
P14  Finance (costs)
P15  Security (secret_references)
P16  Audit (audit_events + audit trigger functions)
P17  Lifecycle Triggers (updated_at / archived_at, all tables)
P18  RLS Enablement (all tables)
P19  RLS Policies (all tables)
P20  Storage Buckets & Storage RLS
P21  Seed Data (required → optional → development)
```

This order is **strict**: a later phase may depend on any earlier phase, but never the reverse. Full object-level dependency detail is in Section 9 and the graph in Section 30.

---

# 5. SCHEMA CREATION ORDER

Per KEM-053 §4 (locked, schema-per-domain), all nine schemas are created together in **P01**, immediately after extensions and before any enum type or table exists — schema-qualified enums (Section 7) require their target schema to already exist, which is exactly why schema creation now precedes enum creation (corrected in v1.1.0; see Revision Note). Fixed order below (alphabetical is deliberately not used — this order reflects dependency weight, heaviest-depended-upon first):

```text
1. identity        — everything else eventually references identity.users
2. core             — the project/asset backbone every domain schema hangs off
3. infrastructure    — depends on core.assets, core.projects
4. operations         — depends on core.projects, core.environments, infrastructure.*
5. automation          — depends on core.projects
6. ai                   — depends on core.projects
7. finance               — depends on core.projects, core.assets
8. security               — depends on core.projects, core.environments
9. audit                   — depends on identity.users, core.projects (nullable FK only)
```

`CREATE SCHEMA` statements themselves have no inter-schema dependency (schemas are just namespaces), but this order is preserved anyway so the migration file order reads in the same dependency sequence as everything that follows — reviewers never have to jump around.

---

# 6. EXTENSION REQUIREMENTS

Applied in **P00**, before anything else:

```text
pgcrypto     → INCLUDED in the foundation migration set (P00). Required for
               gen_random_uuid() (KEM-053 §5.1 UUID strategy). pgcrypto is enabled by
               default on Supabase-managed Postgres; the migration still declares
               CREATE EXTENSION IF NOT EXISTS pgcrypto for determinism (principle 1)
               rather than assuming platform defaults.

pg_trgm      → DEFERRED — SEARCH-DEPENDENT EXTENSION (locked 2026-09-03).
               NOT included in the foundation migration set (P00) or anywhere in this
               document's phase inventory. It is not needed by any table, constraint,
               index, or query defined in KEM-053 or KEM-054 — its only cited use is
               future free-text search across core.assets.name / core.projects.name
               (KEM-052 §82 global search), a feature that does not exist yet. Adding
               an extension the foundation migrations do not use would violate the
               "no unnecessary extensions" principle; it is introduced later, in its
               own dedicated migration, only once actual search requirements exist
               and justify it. This closes the item previously listed under
               REQUIRES REVIEW (v1.0.0) — no further review is pending on it.
```

No extension requiring superuser privileges beyond what Supabase's managed Postgres already grants the `postgres`/project owner role is required. The foundation migration set (P00–P21) requires **`pgcrypto` only**.

---

# 7. ENUM CREATION ORDER

**RESOLVED (2026-09-03, locked):** enum types are never created in `public`. Because the architecture is schema-per-domain, every enum type is schema-qualified and lives in the domain schema it semantically belongs to — created in **P02**, immediately after **P01** (Schema Creation) so every target schema already exists. This closes the item previously listed under REQUIRES REVIEW (v1.0.0).

## 7.1 Placement Rule

```text
1. Each enum is assigned to the ONE domain schema it is semantically specific to —
   not to whichever table happens to consume it, when those differ.
2. An enum genuinely used by tables across MULTIPLE unrelated domains is placed in
   `core` (the shared/foundational schema) and referenced schema-qualified
   (e.g. `core.record_status`) from every consuming schema.
3. No enum is duplicated across schemas. Each of the 15 enums exists exactly once.
```

## 7.2 Final Enum-to-Schema Assignment

```text
core schema        (shared/core + core-domain-specific):
  core.record_status          ← genuinely cross-domain: consumed by identity.users,
                                 identity.roles, core.environments, core.assets,
                                 infrastructure.*, automation.workflows, ai.models,
                                 ai.agents, security.secret_references — the one enum
                                 that meets the "genuinely shared" bar in rule 2 above
  core.project_status          ← core.projects only
  core.project_criticality      ← core.projects, core.assets (both core-schema tables)
  core.environment_type          ← core.environments only
  core.dependency_type             ← core.asset_dependencies only

identity schema:
  identity.identity_owner_type      ← semantically an identity/ownership-taxonomy concept
                                       (USER / TEAM / ORGANIZATION); consumed by
                                       core.projects.owner_type, referenced cross-schema
                                       as identity.identity_owner_type — single consumer,
                                       so rule 2's "shared → core" escalation does not
                                       apply; it stays identity-owned by domain meaning

infrastructure schema:
  infrastructure.health_status        ← infrastructure.services only
  infrastructure.ssl_status            ← infrastructure.domains, infrastructure.certificates
                                        (both infrastructure-schema tables)

operations schema:
  operations.deployment_status          ← operations.deployments only
  operations.incident_severity           ← operations.incidents only
  operations.incident_status              ← operations.incidents only
  operations.change_status                 ← operations.changes only
  operations.change_risk_level              ← operations.changes only
  operations.backup_status                   ← operations.backups only

ai schema:
  ai.ai_autonomy_level                        ← ai.agents only

automation schema:   (no dedicated enum — automation.workflows uses TEXT + core.lookup_values
                       for engine/trigger_type, not a native enum, per KEM-053 §7.5)
finance schema:       (no dedicated enum — finance.costs uses TEXT + core.lookup_values
                       for cost_type, per KEM-053 §7.7)
security schema:      (no dedicated enum — security.secret_references uses core.record_status
                       only, already covered under the shared core enum above)
audit schema:         (no dedicated enum — audit.audit_events uses TEXT columns for
                       action/result, deliberately not enums, so the audit action vocabulary
                       can be extended by forward migration without an enum-value-add
                       restriction, per Section 18's enum-are-forward-only-only physical
                       constraint)
```

15 enums total, zero duplicates, matching the 15-type inventory in KEM-053 §6.1 exactly — this is a placement decision, not a redefinition of any type's values.

## 7.3 Cross-Schema Reference Rule

Every column typed with an enum from a schema other than the table's own schema is declared with the fully schema-qualified type name — e.g. `core.projects.owner_type identity.identity_owner_type`, `infrastructure.servers.status core.record_status`. No `search_path`-relative bare type name is ever used in a `CREATE TABLE` statement, so table definitions remain unambiguous regardless of the session's search_path at migration time.

## 7.4 Creation Order Within P02

Enums have no inter-enum dependency, so creation order among them is arbitrary — but this document fixes one order for determinism (principle 1), grouped by schema in the same dependency-weight order as Section 5:

```text
core.record_status → core.project_status → core.project_criticality →
core.environment_type → core.dependency_type →
identity.identity_owner_type →
infrastructure.health_status → infrastructure.ssl_status →
operations.deployment_status → operations.incident_severity →
operations.incident_status → operations.change_status →
operations.change_risk_level → operations.backup_status →
ai.ai_autonomy_level
```

---

# 8. TABLE CREATION ORDER

Full table-by-table order, matching Section 9's phases exactly (this section is the flattened view; Section 9 is the detailed view):

```text
 1. identity.users
 2. identity.roles
 3. identity.permissions
 4. identity.role_permissions
 5. identity.user_roles
 6. core.lookup_values
 7. core.projects
 8. core.environments
 9. core.assets
10. core.asset_projects
11. core.asset_dependencies
12. core.documents
13. infrastructure.servers
14. infrastructure.databases
15. infrastructure.repositories
16. infrastructure.domains
17. infrastructure.certificates
18. infrastructure.services
19. operations.deployments
20. operations.incidents
21. operations.changes
22. operations.backups
23. operations.events
24. operations.notifications
25. automation.workflows
26. ai.models
27. ai.agents
28. finance.costs
29. security.secret_references
30. audit.audit_events
```

30 tables total (matches KEM-053 §17 inventory of 21 conceptual tables plus the sub-tables and junction tables enumerated individually: `asset_projects`, `role_permissions`, `user_roles`, `permissions`, `notifications`, `certificates`, `lookup_values`, `asset_dependencies`, `documents` were grouped conceptually in KEM-053's inventory count of 21 — no new table is introduced here that KEM-053 did not already specify).

---

# 9. PHASE INVENTORY — FULL DEPENDENCY DETAIL

Every phase below states: **Prerequisites**, **Objects Created**, **Objects Depended Upon**, **Objects That Depend On It**, **Validation Checks**, **Rollback/Recovery Considerations**. This is the authoritative detail level requested; Sections 4–8 are summaries of this section, not the other way around.

## P00 — Preflight & Extensions
```text
Prerequisites:        Supabase project exists (empty), migration runner has owner-level DB access
Objects created:       EXTENSION pgcrypto
Depended upon:         none (first phase)
Depended on by:        every subsequent phase (gen_random_uuid() used in every table's id column)
Validation checks:     SELECT * FROM pg_extension WHERE extname = 'pgcrypto' returns 1 row
Rollback/recovery:      DROP EXTENSION pgcrypto — safe only if no table yet exists; after P03
                        this becomes a full rebuild, not a targeted rollback (Section 17)
```

## P01 — Schema Creation
```text
Prerequisites:        P00 complete
Objects created:       9 schemas (Section 5)
Depended upon:         none beyond P00
Depended on by:        P02 (every schema-qualified enum needs its target schema first),
                        every table-creation phase (P03, P05–P16)
Validation checks:     information_schema.schemata contains all 9 expected schema names
Rollback/recovery:      DROP SCHEMA ... CASCADE — destructive once populated; treated as a
                        full-environment rebuild trigger, never a partial rollback in production
                        (Section 17)
```

## P02 — Enum Types
```text
Prerequisites:        P00, P01 complete (every target schema from Section 7.2 must already
                        exist — this is precisely the dependency-order defect corrected in
                        v1.1.0; enum creation could not previously precede schema creation
                        once enums became schema-qualified)
Objects created:       15 enum types, schema-qualified per the placement in Section 7.2
                        (5 in core, 1 in identity, 2 in infrastructure, 6 in operations,
                        1 in ai; automation/finance/security/audit intentionally have none)
Depended upon:         P01 (each enum's target schema)
Depended on by:        P03, P06–P16 (every table with an enum-typed column, referencing the
                        schema-qualified type name per Section 7.3)
Validation checks:     for each of the 9 schemas, SELECT t.typname, n.nspname FROM pg_type t
                        JOIN pg_namespace n ON t.typnamespace = n.oid WHERE t.typtype='e'
                        returns exactly the 15 expected (schema, type) pairs from Section 7.2 —
                        zero enums found in `public`, zero duplicates across schemas
Rollback/recovery:      DROP TYPE <schema>.<name> ... CASCADE only safe before any table
                        references it; once any P03+ table exists, an enum change requires a
                        new migration that adds a value (ALTER TYPE <schema>.<name> ...
                        ADD VALUE) rather than a drop — enum value REMOVAL is never performed
                        via rollback, only forward migration (Section 18)
```

## P03 — Identity Core
```text
Prerequisites:        P00–P02 complete; Supabase Auth (auth.users) already exists (platform-managed)
Objects created:       identity.users, identity.roles, identity.permissions,
                        identity.role_permissions, identity.user_roles
                        + trigger function handle_new_user() on auth.users AFTER INSERT
Depended upon:         auth.users (Supabase-managed, pre-existing), core.record_status (P02)
Depended on by:        every project-scoped table in every later phase (via created_by/updated_by,
                        owner_id, actor_id, or direct FK); P04 helper functions; P18/P19 RLS
Validation checks:     5 tables exist with expected columns (compare against KEM-053 §7.1
                        column-for-column); FK identity.users.auth_user_id → auth.users(id)
                        resolves; inserting a row into auth.users in a test environment produces
                        exactly one identity.users row via the trigger, with zero roles granted
Rollback/recovery:      DROP TABLE identity.user_roles, role_permissions, permissions, roles, users
                        CASCADE, in that reverse order; DROP TRIGGER handle_new_user first to
                        avoid orphaned trigger errors — full detail in Section 17
```

## P04 — Identity Helper Functions
```text
Prerequisites:        P03 complete
Objects created:       identity.current_user_id(), identity.has_role(text),
                        identity.has_permission(text), identity.has_project_access(uuid, text)
                        — all SECURITY DEFINER, per KEM-053 §9.2
Depended upon:         identity.users, identity.user_roles, identity.role_permissions (P03)
Depended on by:        every RLS policy created in P19
Validation checks:     each function exists in pg_proc with prosecdef = true (confirms
                        SECURITY DEFINER is actually set, not silently dropped); a smoke test
                        with a known seeded SUPER_ADMIN user returns true from has_role('SUPER_ADMIN')
Rollback/recovery:      DROP FUNCTION — safe only before P19 exists; once policies reference these
                        functions, dropping requires dropping dependent policies first (CASCADE is
                        deliberately NOT used here — policy loss must be explicit, never implicit)
```

## P05 — Lookup Values
```text
Prerequisites:        P01 complete (schema core exists)
Objects created:       core.lookup_values
Depended upon:         none beyond P01
Depended on by:        core.projects.category, core.assets.asset_type, finance.costs.cost_type,
                        infrastructure.servers.provider, infrastructure.databases.engine
                        (all trigger-validated against this table per KEM-053 §5.8 and Section 12.1)
Validation checks:     table exists; UNIQUE(category, value) constraint present; seeded category
                        set (Section 16) matches the exact list in KEM-053 §6.2 with no gaps
Rollback/recovery:      DROP TABLE — safe until any table with a lookup-value CHECK constraint
                        exists (P06 onward); after that, treated as append-only in practice
                        (values are deactivated via is_active=false, never deleted)
```

## P06 — Core Project Model
```text
Prerequisites:        P02–P05 complete
Objects created:       core.projects, core.environments
Depended upon:         core.project_status/core.project_criticality/identity.identity_owner_type/
                        core.environment_type (P02), core.lookup_values (P05), identity.users
                        (P03, via owner_id/created_by/updated_by)
Depended on by:         P06B, P06C, and every project-scoped table in P07–P16 (all reference
                        core.projects.id)
Validation checks:     core.projects.project_code sequence exists (KEM-053 §5.2 — PRJ-000
                        permanently reserved, not assigned by the sequence); UNIQUE(project_id,
                        environment_type) on core.environments enforced; a test insert of a
                        duplicate environment_type for the same project_id is correctly rejected.
                        NOTE (corrected, v1.2.0): P06 does NOT seed or otherwise create PRJ-000 —
                        see Section 9-BIS, Bootstrap Lifecycle.
Rollback/recovery:      DROP TABLE core.environments, core.projects CASCADE — this is the single
                        highest-blast-radius rollback short of a full rebuild, since 20+ downstream
                        tables FK into core.projects; treated as PRODUCTION-FORBIDDEN (Section 17)
                        — only ever performed against an empty/dev database
```

## P06B — Identity Scope FK Add
```text
Prerequisites:        P03 (identity.user_roles table exists, scope_project_id column present
                        but unconstrained), P06 (core.projects exists)
Objects created:       none (ALTER TABLE only)
Objects modified:      identity.user_roles — adds FK constraint
                        fk_user_roles_scope_project (scope_project_id -> core.projects.id)
Depended upon:         P03, P06
Depended on by:        P19 (RLS policies that join through scope_project_id rely on this FK
                        for referential integrity, though not for their own creation), P21
Validation checks:     pg_constraint shows fk_user_roles_scope_project resolved against
                        core.projects; a test insert of a user_roles row with a non-existent
                        scope_project_id is correctly rejected after this migration (and was
                        NOT rejected before it, since P03 created the column with no FK)
Rollback/recovery:      DROP CONSTRAINT fk_user_roles_scope_project — safe, additive-only
                        migration, no data loss
```

**Why P06B exists (OQ-01):** `identity.user_roles.scope_project_id` is created in P03, before `core.projects` exists — PostgreSQL requires the *referenced* table to physically exist at `FOREIGN KEY`-creation time, regardless of whether the referencing column is nullable. P06B is the deferred, correctly-ordered fix: the column exists from P03 onward (unconstrained), and the constraint itself is added once its target table (P06) exists.

## P06C — Control Tower Bootstrap Function
```text
Prerequisites:        P04 (identity.current_user_id(), identity.has_role()), P06 (core.projects)
Objects created:       core.bootstrap_control_tower_project() — SECURITY DEFINER function only
Objects modified:      none
Depended upon:         P04, P06
Depended on by:        none within P00–P21 — this function is DEFINED here but INVOKED only
                        later, as a separate POST-BOOTSTRAP OPERATION outside this migration
                        sequence entirely (see Section 9-BIS, Bootstrap Lifecycle)
Validation checks:     function exists, prosecdef=true, EXECUTE revoked from PUBLIC and
                        granted only to the authenticated role
Rollback/recovery:      DROP FUNCTION — safe; the function defines behavior only and holds no
                        data of its own
```

**What P06C explicitly does NOT do:** it does not create `PRJ-000`, does not seed any row, and is not invoked as part of `P00`–`P21`. Defining the function is safe at migration time (no user dependency); *calling* it is not, and is deliberately kept out of the migration chain — see Section 9-BIS.

## P07 — Core Asset Model
```text
Prerequisites:        P06 complete (P06B, P06C sort between P06 and P07 in the migration
                        sequence but are independent additions — P07's own dependencies are
                        satisfied by P06 alone; P06B/P06C are not prerequisites of P07 itself)
Objects created:       core.assets, core.asset_projects, core.asset_dependencies
Depended upon:         core.projects, core.environments (P06), identity.users (P03),
                        core.lookup_values (P05), core.dependency_type/core.project_criticality (P02)
Depended on by:        infrastructure.* (P09, all FK asset_id), any future asset-typed extension
Validation checks:     core.asset_dependencies.CHECK(source_asset_id <> target_asset_id) rejects
                        a self-referential row in a test; UNIQUE(source_asset_id, target_asset_id,
                        dependency_type) rejects an exact duplicate edge
Rollback/recovery:      DROP TABLE core.asset_dependencies, asset_projects, assets CASCADE
                        (reverse creation order); cascades into every infrastructure.* row —
                        same PRODUCTION-FORBIDDEN treatment as P06
```

## P08 — Core Documents
```text
Prerequisites:        P06, P07 complete
Objects created:       core.documents
Depended upon:         core.projects (P06), identity.users (P03)
Depended on by:        none yet (leaf table at MVP)
Validation checks:     storage_path column is NOT NULL and non-empty on any test insert;
                        classification column defaults to 'INTERNAL' per KEM-053 §7.2
Rollback/recovery:      DROP TABLE core.documents — low blast radius, no downstream dependents;
                        safe to roll back independently even in production if genuinely empty
```

## P09 — Infrastructure Registry
```text
Prerequisites:        P07 complete
Objects created:       infrastructure.servers, databases, repositories, domains,
                        certificates, services
Depended upon:         core.assets, core.projects, core.environments (P06/P07),
                        infrastructure.ssl_status/infrastructure.health_status (P02), core.lookup_values (P05)
Depended on by:        operations.deployments (repository_id), operations.services'
                        health-status feeds into future monitoring automation (out of scope here)
Validation checks:     infrastructure.certificates.domain_id FK resolves; infrastructure.services
                        .server_id is nullable and correctly allows NULL for serverless services;
                        each table's asset_id FK correctly cascades on the parent asset's delete
                        in a dev-environment test
Rollback/recovery:      DROP in reverse dependency order: services → certificates → domains →
                        repositories → databases → servers; certificates MUST drop before domains
                        (FK direction) or the CASCADE step will silently take domains with it —
                        this ordering is the one place in Section 9 where rollback order is NOT
                        simply the reverse of creation order and must be followed exactly
```

## P10 — Operations Registry
```text
Prerequisites:        P06, P09 complete
Objects created:       operations.deployments, incidents, changes, backups
Depended upon:         core.projects, core.environments (P06), infrastructure.repositories,
                        core.assets (P07/P09), identity.users (P03),
                        operations.deployment_status/operations.incident_severity/
                        operations.incident_status/operations.change_status/
                        operations.change_risk_level/operations.backup_status (P02)
Depended on by:        operations.events (P11, loosely via resource_id, not a hard FK)
Validation checks:     operations.changes CHECK constraint chk_changes_high_risk_requires_approval
                        (KEM-053 §7.4) rejects a HIGH/CRITICAL change reaching status='COMPLETED'
                        without approved_by set, verified via a negative test case
Rollback/recovery:      DROP TABLE backups, changes, incidents, deployments CASCADE
                        (reverse order); no other table FKs into these four, so blast radius is
                        contained to this phase
```

## P11 — Operations Events & Notifications
```text
Prerequisites:        P10 complete
Objects created:       operations.events, operations.notifications
Depended upon:         core.projects (P06, nullable), identity.users (P03)
Depended on by:        none (leaf tables)
Validation checks:     operations.events.event_type validated against core.lookup_values
                        ('EVENT_TYPE') via CHECK; operations.notifications.related_event_id FK
                        is nullable and resolves correctly when set
Rollback/recovery:      DROP TABLE notifications, events — lowest-risk rollback in the entire
                        phase inventory; these are the two tables Section 12.8 already classifies
                        as short-retention/prunable, so periodic truncation is expected operational
                        behavior, not just a rollback scenario
```

## P12 — Automation
```text
Prerequisites:        P06 complete
Objects created:       automation.workflows
Depended upon:         core.projects (P06, nullable), identity.users (P03)
Depended on by:        none at MVP (workflow_executions deferred, KEM-053 §18 item L-05)
Validation checks:     n8n_reference column accepts NULL (workflow may be defined but not yet
                        wired to an n8n instance) without violating any constraint
Rollback/recovery:      DROP TABLE automation.workflows — isolated, no dependents
```

## P13 — AI
```text
Prerequisites:        P06 complete
Objects created:       ai.models, ai.agents
Depended upon:         core.projects (P06, nullable), identity.users (P03),
                        ai.ai_autonomy_level (P02)
Depended on by:        none at MVP
Validation checks:     ai.agents CHECK constraint chk_agents_l3_l4_require_owner (KEM-053 §7.6)
                        rejects an L3/L4 agent with owner_id NULL, verified via negative test;
                        ai.models UNIQUE(provider, model_name, model_version) rejects a duplicate
                        model registration
Rollback/recovery:      DROP TABLE ai.agents, ai.models (reverse order — agents FK models)
```

## P14 — Finance
```text
Prerequisites:        P06, P07 complete
Objects created:       finance.costs
Depended upon:         core.projects (P06), core.assets (P07, nullable), core.lookup_values (P05)
Depended on by:        none at MVP
Validation checks:     CHECK chk_costs_amount_nonnegative rejects a negative amount; GiST index
                        on billing_period accepts a DATERANGE value and supports overlap queries
                        in a test SELECT
Rollback/recovery:      DROP TABLE finance.costs — isolated, no dependents; note the GiST index
                        must be dropped implicitly with the table, not separately, to avoid an
                        orphaned-index error on some Postgres versions
```

## P15 — Security
```text
Prerequisites:        P06 complete
Objects created:       security.secret_references
Depended upon:         core.projects, core.environments (P06)
Depended on by:        none directly (referenced conceptually by configuration_reference-style
                        columns elsewhere, but no other table holds a literal FK to this table —
                        by design, so that deleting a project's secret reference never cascades
                        into infrastructure records)
Validation checks:     reference_key UNIQUE constraint rejects a duplicate secret:// pointer;
                        a manual code-review check (not a SQL check — see Section 29) confirms no
                        column in this table or anywhere in the schema could hold a raw secret value
Rollback/recovery:      DROP TABLE security.secret_references — isolated, no cascading dependents
```

## P16 — Audit
```text
Prerequisites:        P03–P15 complete (audit triggers must attach to already-existing tables)
Objects created:       audit.audit_events + one AFTER INSERT/UPDATE/DELETE trigger function per
                        governed table (Section 12.7's action list), all SECURITY DEFINER,
                        writing to audit.audit_events only, never reading it back
Depended upon:         identity.users (P03, actor_id), core.projects (P06, nullable), every
                        table created in P03–P15 (each gets its own trigger attached here)
Depended on by:        none downstream; this is the terminal write target for every other phase
Validation checks:     performing a test UPDATE on core.projects.status produces exactly one
                        audit.audit_events row with action='UPDATE', resource_type='projects',
                        and a metadata JSONB diff containing the old and new status values;
                        REVOKE UPDATE, DELETE ON audit.audit_events FROM PUBLIC is confirmed via
                        information_schema.role_table_grants showing no UPDATE/DELETE grant to
                        any non-superuser role
Rollback/recovery:      Triggers are dropped individually per governed table (DROP TRIGGER ...
                        for each); audit.audit_events itself is NEVER dropped in a live
                        environment even during rollback — it is append-only and its own rollback
                        path is "do not roll this table back," full stop (Section 17)
```

## P17 — Lifecycle Triggers
```text
Prerequisites:        P03–P15 complete
Objects created:       trigger_set_updated_at() and trigger_set_archived_at() trigger functions,
                        attached to every table with updated_at / status columns respectively
Depended upon:         every table from P03–P15
Depended on by:        none
Validation checks:     a test UPDATE on any governed table changes updated_at automatically even
                        when the application does not set it explicitly; a test transition of
                        status → 'ARCHIVED' sets archived_at automatically and a second transition
                        away from 'ARCHIVED' does NOT clear archived_at (history-preserving,
                        per KEM-053 §5.6 intent)
Rollback/recovery:      DROP TRIGGER per table — safe, no data loss, since these triggers only
                        maintain metadata columns, never business data
```

## P18 — RLS Enablement
```text
Prerequisites:        P03–P17 complete (every table and every trigger must exist first —
                        RLS is enabled last among structural changes, so no table is ever
                        briefly "live" with data before RLS is on)
Objects created:       ALTER TABLE ... ENABLE ROW LEVEL SECURITY for every table except
                        core.lookup_values (public read reference data, KEM-053 §9)
Depended upon:         every table from P03–P16
Depended on by:        P19 (policies cannot attach meaningfully before RLS is enabled, though
                        PostgreSQL permits creating policies before enabling RLS — this document
                        deliberately sequences enablement BEFORE policy creation so that between
                        P18 and P19 completing, every table is RLS-enabled with zero policies,
                        i.e. default-deny, never briefly open)
Validation checks:     SELECT relrowsecurity FROM pg_class joined to pg_namespace confirms every
                        expected table (all except lookup_values) has RLS enabled; a test SELECT
                        as an unprivileged role against any table returns zero rows between P18
                        and P19 (proves default-deny, not default-allow)
Rollback/recovery:      ALTER TABLE ... DISABLE ROW LEVEL SECURITY — this is the single most
                        dangerous rollback action in the entire document (it reopens every table
                        to default Postgres grants) and is flagged PRODUCTION-FORBIDDEN outright;
                        the only acceptable "rollback" of P18 is forward-fixing a specific policy
                        in P19, never disabling RLS itself (Section 17)
```

## P19 — RLS Policies
```text
Prerequisites:        P04 (helper functions), P18 (RLS enabled) complete
Objects created:       SELECT/INSERT/UPDATE/DELETE policies per table, following the baseline
                        pattern in KEM-053 §9.3 and the role-to-access table in KEM-053 §9.4,
                        one file per table under /supabase/policies (Section 2)
Depended upon:         identity.current_user_id(), has_role(), has_permission(),
                        has_project_access() (P04); every table (P18)
Depended on by:        none structurally; this is what makes every earlier table actually usable
                        by the application layer
Validation checks:     for each of the 9 roles in KEM-053 §9.4, a scripted test session confirms:
                        (a) SUPER_ADMIN/ADMIN can read/write across all scoped tables,
                        (b) VIEWER can read but never write,
                        (c) a user with no role assignment reads and writes nothing,
                        (d) a user scoped to PROJECT_MANAGER on Project A cannot read Project B's
                            rows in any project-scoped table,
                        (e) audit.audit_events rejects UPDATE/DELETE from every role including
                            SUPER_ADMIN (Section 9.6, KEM-053)
Rollback/recovery:      DROP POLICY per policy name — safe and granular; a single misbehaving
                        policy can be dropped and replaced by a new forward migration without
                        touching any other table's policies (this granularity is exactly why
                        policies are file-per-table, per Section 2)
```

## P20 — Storage Buckets & Storage RLS
```text
Prerequisites:        P06 (core.projects), P08 (core.documents), P19 (RLS policy pattern
                        established, so Storage policies can mirror it) complete
Objects created:       one Supabase Storage bucket ("documents"), plus Storage RLS policies on
                        storage.objects mirroring identity.has_project_access() exactly
                        (KEM-053 §7.2/§11, DECISION LOCKED)
Depended upon:         core.documents.storage_path convention (KEM-053 §7.2), identity helper
                        functions (P04)
Depended on by:        none structurally; consumed by any future document-upload feature
Validation checks:     a test file uploaded under documents/prj-001/... is readable only by a
                        session with has_project_access() true for PRJ-001, verified by a
                        negative test from a session scoped to a different project
Rollback/recovery:      Storage RLS policies are dropped independently of the bucket; the bucket
                        itself is never deleted as a "rollback" step if it may contain files —
                        object deletion is out of scope for a schema rollback entirely
                        (Section 17)
```

## P21 — Seed Data
```text
Prerequisites:        every structural phase (P00–P20) complete
Objects created:       rows only, no schema objects — required seed (Section 16.1), then
                        optional seed (Section 16.2); development seed (Section 16.3) is a
                        SEPARATE, environment-gated step, never bundled with P21 required/optional
Depended upon:         every table and constraint from every prior phase
Depended on by:        none (terminal phase)
Validation checks:     row counts match expected seed counts exactly (e.g. identity.roles = 9,
                        core.lookup_values = expected category/value pair count from KEM-053 §6.2);
                        core.projects contains exactly one is_system=true row with
                        project_code='PRJ-000'; no seeded row in any environment contains a
                        value matching secret-shaped patterns (Section 29 validation)
Rollback/recovery:      DELETE seeded rows by a known seed-tag/batch identifier inserted alongside
                        each seed row for exactly this purpose — never a blind DELETE FROM, which
                        risks removing legitimate application data that happens to share a table
                        with seed rows (e.g. identity.roles could theoretically gain
                        application-created custom roles after go-live)
```

---

# 9-BIS. BOOTSTRAP LIFECYCLE (THREE-PHASE MODEL)

**`PRJ-000` is an identity-dependent Control Tower bootstrap record, not ordinary static seed data.** `core.projects.owner_id` is `NOT NULL` with no default (KEM-053 §7.2, unchanged — KEM-053 was not modified for this). No real `identity.users` row exists at `P00`–`P21` migration time, so `PRJ-000` cannot be created there. Per **KEM-052 §186** (existing, authoritative, unmodified bootstrap order), the correct sequence is:

```text
CREATE SYSTEM ADMIN  →  CREATE ROLES/PERMISSIONS  →  CREATE CONTROL TOWER SYSTEM RECORD  →  CREATE FIRST PROJECT
```

This section documents that sequence as it applies to this migration architecture.

## 9-BIS.1 Phase 1 — Database Migration Bootstrap
```text
Scope:        P00 -> P21, /database/migrations/
Produces:      schemas, enums, tables, functions, triggers, RLS, roles, permissions, lookup
               values, optional seed (KEM-054 §16-bis, unchanged for everything except
               PRJ-000 — see 9-BIS.4). Fully automated, deterministic, no user dependency.
Does NOT produce: PRJ-000. P06C (this section's Phase 3 mechanism) is DEFINED in this phase
               but never INVOKED in it.
```

## 9-BIS.2 Phase 2 — Identity Bootstrap
```text
Scope:         Application layer + Supabase Auth. Outside this migration chain entirely —
               no file in /database/migrations/ performs this phase.
Steps:         1. A real person signs up via Supabase Auth (application layer).
               2. auth.users gains a row -> the existing trg_handle_new_user trigger (P03,
                  unchanged) fires automatically -> identity.users row created, zero role
                  grants (unchanged P03 behavior).
               3. A trusted backend process, authenticated with the Supabase service_role
                  key (bypasses RLS entirely — KEM-053 §9.5, unchanged), inserts one row
                  into identity.user_roles granting that identity.users.id the SUPER_ADMIN
                  role (already seeded in Phase 1). This is the only step in the entire
                  lifecycle using a privileged, RLS-bypassing credential, and it must never
                  be reachable from a frontend or any untrusted caller.
```

## 9-BIS.3 Phase 3 — Control Tower Bootstrap
```text
Scope:         /database/post-bootstrap/ — a directory structurally separate from
               /database/migrations/, containing 001_control_tower_bootstrap_invoke.sql
               (a documented reference invocation, NOT a migration) and a README.
Trigger:       Once Phase 2 is complete, the now-authenticated System Admin's OWN normal
               session (never service_role) invokes:

                   SELECT core.bootstrap_control_tower_project();

               defined in migration P06C. This single call is the entirety of Phase 3.
Mechanism:     The function resolves the caller's own identity.current_user_id(), requires
               identity.has_role('SUPER_ADMIN') to be true for that id (both checks run
               BEFORE checking whether PRJ-000 already exists, so an unauthorized caller is
               rejected outright rather than merely being denied a write), then creates
               PRJ-000 with owner_id bound to the caller's own id. Idempotent: a second
               call, by the same or a different SUPER_ADMIN, returns the existing PRJ-000's
               id without creating a duplicate or raising an error (core.projects.
               project_code is also UNIQUE, so a race condition is rejected at the database
               level regardless).
Invocation must NOT: use the service_role key — service_role has no corresponding
               auth.uid(), so identity.current_user_id() resolves to NULL and the function
               rejects the call by itself, on the same path as "no System Admin exists".
```

## 9-BIS.4 P21 correction

**P21 does NOT create `PRJ-000`.** KEM-054 v1.1.0's Section 16-bis (§16.1) and its Tier 5 rollback description (§17) previously assumed `PRJ-000` was part of ordinary required seed data — that assumption is corrected here (those sections' text is intentionally left as historical record below rather than silently rewritten; this note is the authoritative correction). `PRJ-000` is created exclusively via Phase 3 (9-BIS.3), never by any file under `/database/migrations/P21*`.

## 9-BIS.5 What this section deliberately preserves unchanged

Per Mr. Ess's explicit instruction, nothing else in this document's architecture is altered to accommodate this correction: `core.projects.owner_id` remains `NOT NULL` with no default; no zero/nil UUID, sentinel user, or other placeholder is used anywhere; schemas, tables, enums, FK architecture, RLS architecture, rollback tiers (Section 17), non-PRJ-000 seed strategy, storage architecture, and migration naming conventions are all unchanged by this section.

---

# 10. FOREIGN-KEY DEPENDENCY ORDER

Restated from Section 9 as a single flat list, in the order FKs may first be declared (a table's own FKs are declared at its own creation phase, never deferred to a later phase):

```text
P03: identity.users.auth_user_id → auth.users(id) [Supabase-managed]
P03: identity.role_permissions.{role_id,permission_id} → roles(id), permissions(id)
P03: identity.user_roles.{user_id,role_id,scope_project_id} → users(id), roles(id), core.projects(id)*
     * declared here but core.projects does not exist until P06 — see Section 4/9 dependency
       exception below
P06: core.environments.project_id → core.projects(id)
P07: core.assets.{project_id,environment_id,owner_id} → projects(id), environments(id), users(id)
P07: core.asset_projects.{asset_id,project_id} → assets(id), projects(id)
P07: core.asset_dependencies.{source_asset_id,target_asset_id} → assets(id)
P08: core.documents.{project_id,owner_id} → projects(id), users(id)
P09: infrastructure.*.{asset_id,project_id,environment_id,server_id,domain_id} → core/infra tables
P10: operations.*.{project_id,environment_id,asset_id,repository_id,requested_by,approved_by,
     assigned_to,triggered_by} → core.projects, core.environments, core.assets,
     infrastructure.repositories, identity.users
P11: operations.events.project_id → core.projects(id) [nullable]
     operations.notifications.{recipient_id,related_event_id} → identity.users(id), events(id)
P12: automation.workflows.{project_id,owner_id} → core.projects(id) [nullable], identity.users(id)
P13: ai.agents.{project_id,model_id,owner_id,service_account_user_id} → core.projects [nullable],
     ai.models, identity.users
P14: finance.costs.{project_id,asset_id} → core.projects(id), core.assets(id) [nullable]
P15: security.secret_references.{project_id,environment_id} → core.projects, core.environments
P16: audit.audit_events.{actor_id,project_id} → identity.users(id) [nullable], core.projects [nullable]
```

**Dependency exception, explicitly resolved:** `identity.user_roles.scope_project_id` is declared as NULLABLE precisely so that P03 (Identity Core) does not have to wait for P06 (core.projects) to exist. The FK constraint itself is still added in P03's migration file as `REFERENCES core.projects(id)` — PostgreSQL permits declaring a FK to a table that exists later **only if the referencing column allows NULL and no row is inserted before the referenced table exists**, which holds here since P03 seeds zero `user_roles` rows (seeding happens in P21, long after P06). This single exception is called out explicitly rather than silently reordered, per Section 1 principle 1 (determinism) and Section 21 (validation must catch any future violation of this exact assumption).

---

# 11. INDEX CREATION ORDER

Indexes are created **in the same migration file as the table they belong to**, immediately after the table's `CREATE TABLE` statement — never deferred to a separate later phase — so that a table is never briefly live without its declared indexes. The full index inventory (already specified per-table in KEM-053 §7) is not repeated here; this section fixes the **ordering rule**, not the list:

```text
1. Primary key index         (implicit, created with the PK constraint itself)
2. Unique constraint indexes  (implicit, created with each UNIQUE constraint)
3. Foreign-key indexes         (explicit — Postgres does NOT auto-index FK columns;
                                every FK column listed in Section 10 gets an explicit
                                btree index in the same migration)
4. Domain-specific indexes      (status, severity, type, timestamp columns used in
                                dashboard/filter queries — per KEM-053 §7 per-table lists)
5. Composite/specialized indexes (GiST for finance.costs.billing_period; any future
                                composite index for a multi-column filter)
```

No index is created via a separate "add indexes later" migration — this avoids a window where a table exists under load without the index its query patterns require.

---

# 12. CONSTRAINT CREATION ORDER

Also created inline with each table's `CREATE TABLE` statement, in this fixed sub-order per table:

```text
1. NOT NULL           (column-level, as declared in KEM-053 §7)
2. PRIMARY KEY          (id column)
3. UNIQUE                (human-readable codes, natural keys)
4. FOREIGN KEY            (Section 10 order)
5. CHECK                   (business-rule constraints — e.g. chk_changes_high_risk_requires_approval,
                           chk_agents_l3_l4_require_owner, chk_costs_amount_nonnegative,
                           chk_asset_deps_no_self_reference)
6. DEFAULT                  (applied last conceptually, though syntactically part of the column
                           definition — listed last here because defaults are the constraint
                           type most likely to be revised in a later forward migration without
                           touching anything else)
```

## 12.1 Lookup-Value Validation — RESOLVED: Trigger-Based (locked 2026-09-03)

CHECK constraints that reference `core.lookup_values` (Section 6.2's extensible-enum pattern) are implemented as **trigger-based validation**, never as a literal SQL `CHECK` clause. This closes the item previously listed under REQUIRES REVIEW (v1.0.0).

**Why a trigger is required:** PostgreSQL `CHECK` constraints are evaluated per-row using only that row's own column values — they cannot execute a subquery against another table. Since `core.lookup_values` is a separate, dynamically-extensible table (new categories/values can be added without a schema migration, per KEM-053 §5.8's explicit design intent), the only mechanism capable of validating "does this column's value exist as an active row in `core.lookup_values` for the right category" is a `BEFORE INSERT OR UPDATE` trigger that runs the lookup as an actual query. A literal `CHECK` clause is architecturally incapable of this, not merely a stylistic choice against it.

**Which columns use it:**
```text
core.projects.category                  → category 'PROJECT_CATEGORY'
core.assets.asset_type                    → category 'ASSET_TYPE'
finance.costs.cost_type                    → category 'COST_TYPE'
infrastructure.servers.provider             → category 'SERVER_PROVIDER_TYPE'
infrastructure.databases.engine               → category 'DATABASE_ENGINE'
operations.events.event_type                    → category 'EVENT_TYPE'
```

**What lookup category is validated:** each column above is checked against exactly one `core.lookup_values.category` value (listed alongside it), matched on `core.lookup_values.value = NEW.<column>` AND `core.lookup_values.category = '<the fixed category for that column>'` AND `core.lookup_values.is_active = true`.

**What happens when a lookup value is invalid:** the trigger function raises an exception (`RAISE EXCEPTION 'invalid lookup value % for category %', NEW.<column>, '<category>'`) and the triggering `INSERT`/`UPDATE` is aborted — the same effective behavior a `CHECK` constraint would produce (a rejected statement, not a silently-corrected or silently-accepted one), just implemented as a trigger instead of a declarative constraint. A value that is present in `core.lookup_values` but has `is_active = false` is treated identically to a value that does not exist at all — both are rejected, so deactivating a lookup value (Section 9, P05) immediately blocks its future use without needing a separate migration.

**How the trigger is tested:** per Section 22 (Database Testing Requirements), each of the six columns above gets a positive test (an active, correctly-categorized value is accepted) and a negative test (an inactive value is rejected; a value belonging to the wrong category is rejected; a value that does not exist at all is rejected) — three negative cases per column, run as part of that column's table-creation phase validation checks in Section 9.

**How the trigger behaves during migration/seed operations:** the trigger is created in the same migration file as the table it protects (immediately after the table's constraints, per the ordering in Section 12), which means seed data for these six columns (Section 16) can only be inserted **after** `core.lookup_values` itself is seeded in P05 — this is already guaranteed by phase order (P05 precedes P06 onward) and is restated here so it is not mistaken for an independent requirement. Development seed data (Section 16.3) is subject to the exact same trigger — no environment, including development, bypasses lookup validation.

## 12.2 What Still Uses a Literal CHECK

Static, row-local invariants that do not depend on another table's state continue to use literal `CHECK` constraints exactly as specified in KEM-053 §7 — this includes `chk_changes_high_risk_requires_approval`, `chk_agents_l3_l4_require_owner`, `chk_costs_amount_nonnegative`, and `chk_asset_deps_no_self_reference` (Section 9, P07/P10/P13/P14). The trigger-based approach in 12.1 is used **only** for the six lookup-value-dependent columns listed above — it is not a blanket replacement of `CHECK` constraints throughout the schema.

---

# 13. RLS ENABLEMENT ORDER

Detailed already at the phase level in **P18** (Section 9). Restated as a rule: RLS is enabled **table-by-table, in the same order tables were created (Section 8)**, as one migration file per table (not one blanket `ALTER TABLE ALL`), so that a failure enabling RLS on table N does not leave the migration runner uncertain whether tables 1 through N-1 succeeded. `core.lookup_values` is the sole exception (Section 9, P18) — RLS is deliberately not enabled on it, since it is public governed reference data with no per-row sensitivity.

---

# 14. HELPER-FUNCTION CREATION ORDER

Detailed at the phase level in **P04** (Section 9). Internal order among the four functions:

```text
1. identity.current_user_id()      — no dependency on the other three
2. identity.has_role(text)          — depends on current_user_id()
3. identity.has_permission(text)     — depends on current_user_id(), and transitively on
                                      has_role() for the SUPER_ADMIN/ADMIN bypass path
4. identity.has_project_access(...)   — depends on current_user_id() and has_role()
                                      (global-role bypass) before checking scope_project_id
```

This order is enforced because function 2–4 each call function 1 in their body; PostgreSQL requires the called function to exist first (`CREATE OR REPLACE FUNCTION` does not forward-declare).

---

# 15. RLS POLICY CREATION ORDER

Detailed at the phase level in **P19** (Section 9). Internal order: policies are created in the same table order as Section 8, and **within a table**, always `SELECT` → `INSERT` → `UPDATE` → `DELETE`, matching the order a request lifecycle typically needs them (a row must be selectable before an update policy is meaningfully testable, etc.). `audit.audit_events` is the sole table where only a `SELECT` and `INSERT` policy are ever created — no `UPDATE`/`DELETE` policy is written for any role, ever (Section 9.6 of KEM-053, restated here as a migration-order rule: there is no P19 sub-step that creates one).

---

# 16. STORAGE BUCKET AND STORAGE RLS STRATEGY

Detailed at the phase level in **P20** (Section 9). Summary of the approach locked in KEM-053 §7.2/§11:

```text
Bucket:            "documents" — single bucket at MVP, path-namespaced by project
                    (documents/<project_code>/<document_code>.<ext>), not one bucket per project
Access model:       Storage RLS policies query the exact same identity.has_project_access()
                    function used for table RLS — no parallel/duplicate authorization logic
Public access:      none — the bucket is private by default; no anonymous read path exists
                    at MVP (KEM-052 defines no public-document feature)
Upload path:        application-layer only, via an authenticated Supabase client session;
                    no direct anonymous upload capability
```

No second bucket is created at MVP — a future need (e.g. public marketing assets) would be a new, separately-authorized migration, not an extension of P20 by default.

---

# 16-BIS. SEED-DATA STRATEGY

(Numbered to match the requested topic list; content below expands Section 9's P21.)

## 16.1 Required Seed Data

**CORRECTED (v1.2.0) — see Section 9-BIS.4:** the `PRJ-000` clause below is **superseded**. `PRJ-000` is NOT part of required seed data and is never created by P21 or any file under `/database/migrations/`. It is created exclusively via the Phase 3 Control Tower Bootstrap mechanism (Section 9-BIS.3), after a real System Admin exists. The original v1.1.0 text is preserved below, unchanged, as historical record of the prior (superseded) assumption:

> Exactly as specified in KEM-053 §13.1: `core.lookup_values` full category set, all 9 `identity.roles`, the baseline `identity.permissions` set, `identity.role_permissions` grants per KEM-053 §9.4, and the single `core.projects` row for `PRJ-000` (`is_system = true`). Applied to **every** environment — dev, staging, production — identically, with no environment-specific variation.
>
> *(Superseded, v1.2.0: strike the `PRJ-000` clause specifically. Everything else in this paragraph — lookup values, roles, permissions, role_permissions — remains accurate and unchanged.)*

## 16.2 Optional Seed Data
`ai.models` placeholder rows (`status = 'INACTIVE'`), per KEM-053 §13.2. Applied to every environment by default but explicitly marked non-blocking — a missing optional-seed row is a REQUIRES REVIEW finding (Section 22), never a failed migration.

## 16.3 Development / Test Seed Data
Sample `PRJ-001` project, environments, and a fabricated asset/dependency graph, per KEM-053 §13.3. **Never applied to staging or production** — gated by an explicit environment flag the migration runner checks before executing `/supabase/seed/seed_development.sql` at all (Section 27).

Every seed row, in every category, carries a `seed_batch_id` value (a fixed UUID constant per seed file/version) so Section 9's P21 rollback path can target exactly the rows a given seed run inserted, without risk to organically-created data.

---

# 17. ROLLBACK STRATEGY

```text
Tier 1 — Structural, pre-data (P00–P17, before any real application data exists):
    Standard DOWN migrations: DROP the exact objects the corresponding UP migration created,
    in reverse dependency order (Section 9 gives the per-phase specifics, including the one
    explicit exception in P09).

Tier 2 — Structural, post-data (P00–P17, after real application data may exist):
    DOWN migrations are NOT run against a database with live data for anything upstream of
    (and including) P06/P07 (core.projects/core.assets) — the blast radius is total. Recovery
    is via Supabase's Point-In-Time Recovery (PITR) restore to a pre-migration timestamp,
    not a scripted DOWN migration (Section 26).

Tier 3 — RLS (P18–P19):
    A bad policy is fixed by a new forward migration that replaces the specific policy
    (DROP POLICY + CREATE POLICY in one file). RLS enablement itself (P18) is never rolled
    back / disabled in a live environment (Section 9, P18 — PRODUCTION-FORBIDDEN).

Tier 4 — Audit (P16):
    audit.audit_events is never rolled back, truncated, or restored-over in isolation —
    it is either present in full or the environment is being fully rebuilt from scratch
    (Section 9, P16).

Tier 5 — Seed (P21):
    Rolled back via seed_batch_id-targeted DELETE (Section 16-bis), safe at any time,
    in any environment, including production for optional/development seed categories.
    Required seed is never rolled back in a live environment without a corresponding
    plan for what replaces it (a database with zero roles is a broken database, not a
    rolled-back one).
```

---

# 18. FORWARD-ONLY VS REVERSIBLE MIGRATIONS

```text
Reversible (a real DOWN script is written and tested):
    P00, P01 (before P03 exists), P02 (before P03 exists), P05, P08, P11, P12, P14, P15,
    P20, P21 — all genuinely low-blast-radius, isolated, or explicitly batch-tagged (seed)

Forward-only by design (no DOWN script is ever written; recovery is PITR restore, Section 26):
    P03 (once any auth.users row exists), P06, P07, P09 (once dependent rows exist),
    P16 (audit — always), P18 (RLS enablement — always, per its PRODUCTION-FORBIDDEN rollback)

Conditionally reversible (DOWN script exists but is gated by an emptiness check):
    P04, P10, P13, P17, P19 — the DOWN script first verifies zero dependent rows/policies
    exist before proceeding, and refuses (raises an error, does not silently no-op) if that
    check fails
```

Enum value additions (`ALTER TYPE ... ADD VALUE`, Section 7) are always forward-only — PostgreSQL does not support removing an enum value at all, reversible or not, so this is a physical constraint, not a policy choice.

---

# 19. TRANSACTION BOUNDARIES

```text
Rule:  every migration file is exactly one transaction (Supabase CLI's default behavior —
       BEGIN...COMMIT wraps the whole file automatically). This document adopts that default
       rather than introducing manual transaction control, EXCEPT:

Exception 1 — CREATE TYPE ... ADD VALUE (enum additions, if ever needed after P02) cannot run
       inside the same transaction as a statement that uses the new value — PostgreSQL
       restriction. Any future enum-extension migration is therefore explicitly split into
       two sequential migration files (add value, then use value), never one file.

Exception 2 — Seed data (P21) is split into three separate transactions (required, optional,
       development) rather than one, precisely so a failure in optional or development seeding
       never rolls back required seeding that already succeeded.

Exception 3 — RLS enablement (P18) is one transaction PER TABLE (Section 13), not one
       transaction for all tables, so a single table's enablement failure is isolated and
       does not leave every other table's RLS state in an ambiguous rolled-back condition.
```

No migration ever spans multiple logical phases inside one transaction — this would violate Section 1 principle 3 (single-purpose) even where technically possible.

---

# 20. IDEMPOTENCY REQUIREMENTS

```text
CREATE EXTENSION IF NOT EXISTS ...       — P00
CREATE SCHEMA IF NOT EXISTS ...           — P01
CREATE TYPE ... (no IF NOT EXISTS support in Postgres for types) — P02 migrations instead
       check pg_catalog.pg_type joined to pg_namespace for the schema-qualified type name via
       a DO block before creating, and skip with a RAISE NOTICE if present, rather than
       failing outright on re-run
CREATE TABLE IF NOT EXISTS ...             — every table-creation phase
CREATE INDEX IF NOT EXISTS ...              — every index
CREATE OR REPLACE FUNCTION ...               — every helper/trigger function (P04, P16, P17)
DROP POLICY IF EXISTS ... ; CREATE POLICY ...  — every RLS policy (P19), since Postgres has no
       CREATE POLICY IF NOT EXISTS — policies are always re-created via explicit drop-then-create
INSERT ... ON CONFLICT DO NOTHING             — every seed statement (P21), keyed on each table's
       natural unique constraint (role_code, permission_code, project_code, category+value, etc.)
```

Every migration in this architecture must be safely re-runnable against a database where it has already partially or fully applied, without manual intervention — this is a hard requirement, not an aspiration, and is checked explicitly in Section 21.

---

# 21. MIGRATION VALIDATION REQUIREMENTS

```text
Before merge (static):
    - Filename matches Section 3 convention exactly
    - Migration is idempotent per Section 20's applicable pattern for its object type
    - No literal secret-shaped value appears anywhere in the file (Section 29)
    - Migration touches exactly one phase's objects (Section 1 principle 3) — a linter rule,
      not just a review guideline
    - Every object created has the validation query from its Section 9 phase entry attached
      as an accompanying test file under /supabase/tests (Section 2)

At apply time (dynamic, per environment):
    - The Section 9 "Validation checks" for the phase being applied are run automatically
      immediately after the migration, before the runner proceeds to the next phase
    - A failed validation check halts the migration run entirely — later phases are never
      applied on top of an unvalidated earlier phase
```

---

# 22. DATABASE TESTING REQUIREMENTS

```text
Unit level     — one test file per table verifying every CHECK constraint's positive and
                 negative case (e.g. chk_changes_high_risk_requires_approval accepts a HIGH-risk
                 change WITH approval and rejects one WITHOUT), per Section 9's per-phase
                 validation checks
Integration    — one test suite per RLS role (Section 9, P19) exercising the full 9-role matrix
                 from KEM-053 §9.4 against a representative table set, run against a seeded
                 (Section 16.3) development database only
Regression     — the full validation-check suite from every phase in Section 9 is re-run after
                 every new migration is added anywhere in the sequence, not just after the
                 newest one, to catch an earlier phase's assumption being silently broken later
```

---

# 23. PRE-MIGRATION CHECKS

```text
1. Target environment identified explicitly (dev / staging / production) — no migration runs
   against an ambiguous or default-inferred target
2. Current schema_migrations state read and compared against the expected phase sequence
   (Section 4) — any gap or out-of-order state halts before applying anything
3. For production only: a PITR restore point is confirmed available and recent (Section 26)
   before any migration in Tier 2/Forward-only categories (Section 17/18) is applied
4. Required seed data (Section 16.1) is confirmed NOT already present with conflicting
   values (e.g. a differently-worded role description) before P21 runs, to avoid a silent
   ON CONFLICT DO NOTHING masking a real drift
```

---

# 24. POST-MIGRATION CHECKS

```text
1. Every phase's Section 9 validation check re-run and confirmed passing, in phase order
2. RLS enabled on every expected table (Section 9, P18 validation check) re-confirmed as a
   standalone post-migration query, independent of the P18 migration's own internal check
3. Row counts for every seeded table match Section 21.1's expected counts exactly
4. No table exists without RLS enabled except the single documented exception
   (core.lookup_values) — a full-schema sweep query, not a per-table assumption
5. audit.audit_events REVOKE state (Section 9, P16) re-confirmed
```

---

# 25. FAILURE RECOVERY PROCEDURE

```text
1. Migration fails mid-transaction  → Postgres auto-rolls back that single transaction
                                       (Section 19); the schema is left exactly as it was
                                       before that migration file ran. No action needed
                                       beyond fixing the migration and re-applying.
2. Migration "succeeds" but post-migration checks (Section 24) fail
                                     → treat as a failed migration despite the successful
                                       COMMIT; do not proceed to the next phase; either a
                                       Tier-1/reversible DOWN migration (Section 17/18) is
                                       run, or — for Tier-2/forward-only phases — escalate
                                       to a PITR restore decision (Section 26) rather than
                                       attempting an improvised manual fix
3. Data corruption or unexpected data loss suspected
                                     → halt all further migrations immediately; do not
                                       attempt any DOWN migration; go directly to PITR
                                       restore evaluation (Section 26)
4. Idempotency violated (a migration is accidentally re-run and produces duplicate data
   despite Section 20)              → this is treated as a defect in that migration file
                                       itself, logged, and fixed via a new forward migration
                                       that de-duplicates — never via manual row deletion
                                       against production without the same review rigor as
                                       any other production migration
```

---

# 26. PRODUCTION DEPLOYMENT PROCEDURE

```text
1. All migrations applied and validated against a staging environment that was itself built
   from the same P00–P21 sequence from empty (Section 1 principle 1 — determinism proves
   itself here: staging and production must be reachable by the exact same path)
2. A Supabase PITR restore point is confirmed within policy (Section 23, item 3) immediately
   before the production run begins
3. Migrations are applied in strict Section 4 phase order, with Section 24's post-migration
   checks run after EVERY phase, not just at the end of the full sequence — production never
   runs phases 00 through 21 "as one block" without intermediate validation
4. Required seed data (Section 16.1) is applied identically to staging — no production-only
   seed content exists outside the explicitly-separate optional-seed category
5. Development seed data (Section 16.3) is never applied to production — enforced by the
   environment gate in Section 27, checked and logged, not merely assumed
```

---

# 27. DEVELOPMENT / STAGING / PRODUCTION DIFFERENCES

```text
                    DEVELOPMENT          STAGING              PRODUCTION
Required seed        Yes                  Yes                  Yes
Optional seed         Yes                  Yes                  Yes
Development seed       Yes                  No                   No
RLS enforcement          Full (P18/P19)       Full (P18/P19)       Full (P18/P19)
                        — RLS is never relaxed in dev for developer convenience; a service-role
                        key is used for direct data seeding/debugging instead (KEM-053 §9.5)
PITR restore point        Not required           Recommended            REQUIRED before every run
Migration approval           Single-reviewer         Single-reviewer        Two-reviewer
                        (Section 21 static checks)  (same)                   (Section 21 + explicit
                                                                              sign-off log entry)
```

---

# 28. SUPABASE-SPECIFIC CONSIDERATIONS

```text
Migration tooling:   Supabase CLI (`supabase migration new`, `supabase db push`) is the adopted
                      tool — Section 2's directory structure matches its conventions exactly, so
                      no custom migration runner needs to be built.
auth.users:           Platform-managed; never created or altered by any KEM-054 migration.
                      identity.users only ever reads from it via the P03 trigger.
service_role key:      Used exclusively by the migration runner itself and by trusted
                      backend/n8n processes (KEM-053 §9.5) — never embedded in any migration
                      file's checked-in source (Section 29).
Realtime:              Not enabled by any migration in this document (Section 11 of KEM-053
                      notes it as optional, not required for MVP) — deferred to a future,
                      separately-authorized migration if/when dashboard live-updates are built.
Connection pooling / compute tier:
                      Explicitly out of scope for KEM-054 (these are Supabase project
                      settings, not schema migrations) — carried forward from KEM-053 §16
                      NOT YET SPECIFIED list, unchanged here.
```

---

# 29. SECURITY VALIDATION

```text
1. Static scan of every migration file, before merge, for secret-shaped strings (API-key-like
   patterns, password= assignments, private-key PEM headers) — same pattern class used in the
   original repository audit; a match blocks merge outright, no exceptions
2. Confirmation that security.secret_references (P15) contains no column capable of holding a
   raw value — a schema-shape check, not just a data check, since the risk is a future migration
   accidentally ADDing such a column, not just a bad seed row
3. Confirmation that every table has RLS enabled except the one documented exception
   (Section 24, item 4) run as an explicit security-validation step, not only a functional one
4. Confirmation that no RLS policy grants USING (true) / WITH CHECK (true) unconditionally on
   any table other than core.lookup_values's SELECT policy (its one intentional public-read
   exception) — an unconditional-true policy anywhere else is treated as a security defect,
   not a passable review comment
5. Confirmation that service_role-level access is never exposed through any RLS policy path
   available to the 'authenticated' Postgres role (KEM-053 §9.5 boundary, re-verified here at
   the migration-design level, not assumed from KEM-053 alone)
```

---

# 30. COMPLETE DEPENDENCY GRAPH

```text
P00 Extensions
 └─▶ P01 Schemas
      └─▶ P02 Enums (schema-qualified per Section 7.2 — requires P01's schemas to exist first)
           └─▶ P03 Identity Core ──▶ P04 Identity Helper Functions
                └─▶ P05 Lookup Values
                     └─▶ P06 Core Project Model (projects, environments)
                          ├─▶ P06B Identity Scope FK Add (OQ-01)
                          ├─▶ P06C Control Tower Bootstrap Function DEFINITION only (Section 9-BIS)
                          ├─▶ P07 Core Asset Model (assets, asset_projects, asset_dependencies)
                          │    └─▶ P09 Infrastructure Registry
                          │         └─▶ P10 Operations Registry ──▶ P11 Events & Notifications
                          ├─▶ P08 Core Documents ─────────────────▶ P20 Storage & Storage RLS
                          ├─▶ P12 Automation
                          ├─▶ P13 AI
                          ├─▶ P14 Finance
                          └─▶ P15 Security (secret_references)
                                                                     ┌── all of P03–P15 ──┐
                                                                     ▼                     ▼
                                                              P16 Audit Triggers   P17 Lifecycle Triggers
                                                                     └──────────┬──────────┘
                                                                                ▼
                                                                        P18 RLS Enablement
                                                                                ▼
                                                                        P19 RLS Policies ◀── P04
                                                                                ▼
                                                                        P20 Storage RLS ◀── P08, P19
                                                                                ▼
                                                                        P21 Seed Data ◀── everything
                                                                                       (roles, permissions,
                                                                                       lookup values — NOT
                                                                                       PRJ-000, Section 9-BIS.4)

── OUT OF BAND, NOT PART OF P00–P21 ──
Phase 2 (Identity Bootstrap: real signup + SUPER_ADMIN grant)
     ↓
Phase 3 (Control Tower Bootstrap) ── core.bootstrap_control_tower_project() [P06C] ──▶ PRJ-000
     (/database/post-bootstrap/ — Section 9-BIS.3; depends on P06C's definition existing,
      and on Phase 2 having already happened, but is never itself a migration step)
```

Every arrow in this graph corresponds to a "Depended upon" / "Depended on by" pair already stated explicitly in Section 9 (and Section 9-BIS for the bootstrap-specific nodes) — this diagram is a visual index into that section, not new information.

---

# 31. KEM-054 MIGRATION READINESS CHECKLIST

## ✅ READY
```text
P00 Preflight & Extensions
P01 Schema Creation
P02 Enum Types (schema-qualified per domain, per Section 7.2 — RESOLVED)
P03 Identity Core
P04 Identity Helper Functions
P05 Lookup Values
P06 Core Project Model
P06B Identity Scope FK Add (OQ-01) — RESOLVED, added this revision
P06C Control Tower Bootstrap Function (definition only) — RESOLVED, added this revision
P07 Core Asset Model
P08 Core Documents
P09 Infrastructure Registry
P10 Operations Registry
P11 Operations Events & Notifications
P12 Automation
P13 AI
P14 Finance
P15 Security (secret_references)
P16 Audit
P17 Lifecycle Triggers
P18 RLS Enablement
P19 RLS Policies
P20 Storage Buckets & Storage RLS
P21 Seed Data (required + optional; PRJ-000 explicitly excluded — Section 9-BIS.4, RESOLVED;
    development seed gated per Section 27)
Bootstrap Lifecycle three-phase model (Section 9-BIS) — RESOLVED, added this revision
Migration naming convention (Section 3)
Migration directory structure (Section 2)
Enum schema placement (Section 7) — RESOLVED
Lookup-value trigger-based validation (Section 12.1) — RESOLVED
Extension strategy: pgcrypto only in foundation set, pg_trgm DEFERRED (Section 6) — RESOLVED
Corrected dependency order: P01 Schemas → P02 Enums (Section 4, 30) — RESOLVED
Rollback tiering (Section 17)
Transaction boundary rules (Section 19)
Idempotency patterns (Section 20)
```

## 🚫 BLOCKED
```text
(none) — nothing in this architecture is blocked on an external dependency; every phase's
prerequisites are satisfied by an earlier phase within this same document
```

## ⚠️ REQUIRES REVIEW
```text
(none) — all three items open at v1.0.0 are RESOLVED as of v1.1.0 (2026-09-03):
  1. Enum schema placement            → RESOLVED, Section 7
  2. Lookup-value validation mechanism → RESOLVED, Section 12.1
  3. pg_trgm inclusion timing           → RESOLVED (DEFERRED), Section 6
No new REQUIRES REVIEW item was introduced while resolving these three.
```

## ⏸️ DEFERRED
```text
pg_trgm — DEFERRED — SEARCH-DEPENDENT EXTENSION (Section 6). Not part of the foundation
        migration set. Introduced later, in its own migration, once actual search
        requirements exist.
Actual .sql migration file generation — this document's own architecture has since been
        implemented as real SQL (a separate, later task, outside this document's scope);
        KEM-054 itself remains an architecture document, not a source of executable SQL.
Realtime enablement on operations.incidents/deployments (KEM-053 §11) — optional, not MVP-required
Table ID registry, per-table temporal history, workflow_executions, alerts, integrations,
        organizations, system_settings/feature_flags — all carried forward unchanged from
        KEM-053 §18's DEFERRED classification; KEM-054 does not reopen any of them
Supabase project-level configuration (compute tier, pooling, PITR window length) — remains
        out of scope per KEM-053 §16, restated here in Section 28
```

## 📋 NOTED, NOT RESOLVED (outside this revision's scope)
```text
Section 16-bis §16.3 and Section 17 Tier 5 both still describe seed rollback via a
        `seed_batch_id`-tagged DELETE. KEM-055 v1.2.0's R-02 (approved by Mr. Ess,
        KEM-055-only at the time) replaced this with natural-key-scoped DELETE and
        removed the seed_batch_id concept entirely, for reasons unrelated to PRJ-000/
        NEW-01. This document's seed-rollback description is therefore now also stale
        relative to KEM-055 — logged here per instruction, NOT fixed in this revision,
        since it is outside NEW-01's scope and touches seed/rollback strategy this
        revision was explicitly told to leave alone unless directly tied to PRJ-000.
```

## 🟢 OVERALL STATUS

**READY FOR SQL GENERATION.**

Every phase (P00–P21, plus P06B and P06C) is classified READY. Nothing is BLOCKED. Nothing remains under REQUIRES REVIEW. **NEW-01 is resolved**: this document now documents P06C (Control Tower Bootstrap Function definition), P06B (the previously-undocumented OQ-01 FK fix), and the full three-phase Bootstrap Lifecycle (Section 9-BIS), synchronized with KEM-055 v1.2.0 and the actual `/database/migrations/` + `/database/post-bootstrap/` file layout. One adjacent, unrelated discrepancy (`seed_batch_id`, above) was found and logged, not resolved, per instruction. This readiness statement covers the **architecture only**: it does not itself authorize generating or modifying `.sql` files; per Section 0's boundary and Mr. Ess's standing instruction, that remains a separate, explicit authorization.

---

# 32. END OF SPECIFICATION

**KemetRise — Legacy Nexus**

**MR.ESS Project Operating System**

**SUPABASE MIGRATION ARCHITECTURE & SQL DESIGN SPECIFICATION**

**Version:** 1.2.0

**STATUS:** APPROVED — READY FOR SQL GENERATION (pending explicit authorization to begin)

No live Supabase project was connected to or modified. No SQL was executed. No `.sql` migration file was created or modified in producing this revision. No application, frontend, or backend code was created. No KEM file from KEM-000 through KEM-052, nor KEM-053 or KEM-055, was modified. Only this file, KEM-054 (this revision, v1.1.0 → v1.2.0), was touched, resolving NEW-01 as logged in KEM-055's conflict register.
