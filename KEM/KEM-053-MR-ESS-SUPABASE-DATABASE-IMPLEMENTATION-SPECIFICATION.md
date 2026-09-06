# KEM-053-MR-ESS-SUPABASE-DATABASE-IMPLEMENTATION-SPECIFICATION.md

# KemetRise — Legacy Nexus

## MR.ESS Project Operating System

### SUPABASE DATABASE IMPLEMENTATION SPECIFICATION

**Document ID:** KEM-053
**System ID:** MR-ESS-POS
**Parent System:** KemetRise — Legacy Nexus
**System Role:** Control Tower — Database Implementation Layer
**Owner:** MR.ESS
**Version:** 1.2.0
**Status:** APPROVED — AUTHORITATIVE DATABASE IMPLEMENTATION SPECIFICATION (for currently defined implementation scope)
**Date:** 2026-09-03
**Direct Parent:** KEM-052 (Control Tower Technical Architecture & Database Specification)
**Structural Parent:** KEM-051 (Master Implementation Blueprint)

**Revision note (v1.1.0):** Five previously-open architectural decisions were reviewed and approved by Mr. Ess and are now locked (Section 9.7, Section 11, Section 12.8, Section 13.4, and updates throughout). A new Section 18 — LEGACY REQUIREMENTS REQUIRING FUTURE RECONCILIATION — was added per the reconciliation rule: KEM-052's silence on an older requirement is never treated as automatic supersession. No KEM-000 through KEM-052 file was modified to produce this revision.

**Revision note (v1.2.0):** KEM-053 is APPROVED as the authoritative database implementation specification for the currently defined implementation scope. The five Section 18 items classified POTENTIALLY MISSING (`organizations` L-01, `alerts` L-03, `workflow_executions` L-05, `integrations` L-09, `system_settings`/`feature_flags` L-12) are formally **DEFERRED** — not added to the MVP database, not deleted, legacy references and classifications preserved intact. Each carries an explicit deferral reason in Section 18. No KEM-000 through KEM-052 file was modified.

---

# 1. PURPOSE

KEM-051 defined the physical implementation blueprint.

KEM-052 defined the Control Tower technical architecture and logical entity model.

**KEM-053 translates the KEM-052 entity model into a concrete, implementation-ready PostgreSQL/Supabase database specification** — schemas, tables, columns, types, constraints, relationships, indexes, Row Level Security strategy, migration order, seed data, and data governance rules.

This document is **specification only**. It does not contain runnable SQL migration files, application code, or Supabase project configuration. It is the contract that a future migration-writing phase must follow exactly.

---

# 2. AUTHORITATIVE SPECIFICATION POLICY

This document operates under the authoritative policy established for this phase:

```text
KEM-051  → authoritative for physical project/repository structure
KEM-052  → authoritative for Control Tower technical architecture & entity model
KEM-053  → authoritative for PostgreSQL/Supabase database implementation (this document)
```

KEM-000 through KEM-050 are treated as **historical/legacy specifications**. Where they conflict with KEM-052, KEM-052 wins. Every such conflict actually found while writing this document is logged in **Section 15 — SPECIFICATION CONFLICTS & RESOLUTIONS**, not silently discarded.

No KEM file has been deleted, modified, or renamed in producing this document.

---

# 3. DATABASE ARCHITECTURE OVERVIEW

```text
Platform:        Supabase (managed PostgreSQL)
Engine:           PostgreSQL 15+
Auth:             Supabase Auth (auth.users as the identity root)
Access control:   Row Level Security (RLS) + application-level RBAC
Realtime:         Supabase Realtime (optional, for dashboard live updates)
Storage:          Supabase Storage (optional, for document/asset attachments — references only)
```

Per KEM-052 §3 (Architectural Principle), this database stores **Control Tower management metadata** — projects, assets, infrastructure records, relationships, state, governance, and operational intelligence. It does **not** store the business data belonging to individual KemetRise projects, and it **never** stores secret values (passwords, private keys, tokens) — only references (§61–62).

---

# 4. SCHEMA ORGANIZATION

**DECISION LOCKED (2026-09-03):** Schema-per-domain is the approved and final database architecture. A single flat `public` schema is **not used** for the core application model. All nine domain schemas below are created as true PostgreSQL schemas from the first migration onward, remaining fully compatible with Supabase/PostgreSQL (Supabase supports arbitrary schemas alongside `public`, `auth`, and `storage`).

```text
core           → projects, environments, assets, asset relationships, documents
identity       → users, roles, permissions, role assignments, project-scoped access
infrastructure → servers, databases, repositories, domains, services, certificates
operations     → deployments, incidents, changes, backups, events, notifications
automation     → workflows
ai             → agents, models
finance        → costs
security       → secret references (pointers only, never values)
audit          → audit_events
```

This resolves Conflict #6 (Section 15) and closes the corresponding item that previously sat under REQUIRES DECISION (Section 16).

---

# 5. GLOBAL CONVENTIONS

## 5.1 Identifier Strategy

Every primary entity has two identifiers, per KEM-052 §9:

```text
id            UUID    — immutable internal identifier, PRIMARY KEY, DEFAULT gen_random_uuid()
<entity>_code TEXT    — human-readable operational identifier, UNIQUE, NOT NULL
```

UUIDs are never recycled (KEM-002 §9 — retained, non-conflicting with KEM-052).

## 5.2 Human-Readable Code Format Registry

Resolves a conflict between KEM-002 (3-digit, e.g. `PRJ-001`) and KEM-016 (4-digit, e.g. `PRJ-0007`). **Resolution: 3-digit minimum, zero-padded, unbounded growth** (i.e. `PRJ-9999` rolls to `PRJ-10000` rather than wrapping or breaking). This preserves KEM-002's format while removing the fixed-width ambiguity. See Section 15, Conflict #1.

**DECISION LOCKED (2026-09-03): `PRJ-000` is permanently reserved** for the MR-ESS / KemetRise Control Tower system project itself (`core.projects.is_system = true`, see 7.2). It is never assigned to a KemetRise product project. Numbering for ordinary projects begins at `PRJ-001`.

```text
PRJ-000     RESERVED — Control Tower system project only
PRJ-001     Projects
SRV-001     Servers
DB-001      Databases (registered)
REPO-001    Repositories
DOM-001     Domains
SVC-001     Services
ENV-001     Environments
DEP-001     Deployments
WF-001      Workflows / Automations
AGT-001     AI Agents
MDL-001     AI Models
INC-001     Incidents
CHG-001     Changes
BKP-001     Backups
CERT-001    Certificates
DOC-001     Documents
COST-001    Cost records (optional; high volume, may skip human code)
AST-001     Generic / uncategorized assets
```

Codes are generated by a PostgreSQL sequence per entity type (e.g. `core.projects_code_seq`), not derived from `id`, so they remain stable and gap-tolerant.

## 5.3 Naming Conventions

```text
Schemas:     lowercase, singular          (core, identity, operations)
Tables:      lowercase, snake_case, plural (projects, asset_dependencies)
Columns:     lowercase, snake_case         (created_at, project_id)
Enums:       lowercase, snake_case type name; UPPER_SNAKE_CASE values
Indexes:     idx_<table>_<column(s)>
FKs:         fk_<table>_<referenced_table>
Constraints: chk_<table>_<rule>, uq_<table>_<column(s)>
```

## 5.4 Common Columns Template

Every operational table includes, at minimum (per KEM-052 §67 + KEM-002 §8):

```text
id            UUID          PRIMARY KEY DEFAULT gen_random_uuid()
<x>_code      TEXT          UNIQUE NOT NULL          -- human-readable code
created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at    TIMESTAMPTZ   NOT NULL DEFAULT now()    -- maintained by trigger
created_by    UUID          REFERENCES identity.users(id)
updated_by    UUID          REFERENCES identity.users(id)
```

Project-scoped tables additionally include:

```text
project_id    UUID          REFERENCES core.projects(id)
```

## 5.5 Timestamps

All timestamps are `TIMESTAMPTZ`, stored in UTC (KEM-052 §68). No naive `TIMESTAMP` columns are used anywhere in this schema.

## 5.6 Record Lifecycle / Status Convention

Resolves a conflict between KEM-052 (status-enum lifecycle: `ACTIVE / INACTIVE / ARCHIVED`, §66) and KEM-016 (`deleted_at` soft-delete timestamp, §42). **Resolution: hybrid.**

```text
status        <entity_status_enum>   NOT NULL DEFAULT 'ACTIVE'   -- primary lifecycle signal
archived_at   TIMESTAMPTZ            NULL                        -- set when status → ARCHIVED
deleted_at    TIMESTAMPTZ            NULL                        -- reserved for hard-delete audit trail only
```

- `status` is the operational lifecycle field the application reads (matches KEM-052).
- `archived_at` is set automatically (trigger) the moment `status` transitions to `ARCHIVED`, giving KEM-016's timestamp-based query convenience without making `deleted_at` the primary mechanism.
- `deleted_at` exists only as a marker for the rare **governed hard-delete** path (Section 12.6) and is `NULL` in all normal operation. See Section 15, Conflict #2.

## 5.7 Audit Strategy

Every `INSERT`, `UPDATE` (status/ownership/security-relevant fields), and hard `DELETE` on a governed table is written to `audit.audit_events` via trigger, per KEM-052 §42–43. Full column-level diff is stored in the event's `metadata JSONB` field, not as a separate per-table history table (keeps MVP scope small — full temporal tables are a **NOT YET SPECIFIED / future** item, Section 16).

## 5.8 Enum Strategy

PostgreSQL native `ENUM` types are used for closed, rarely-changing value sets (statuses, severities). Open-ended/extensible sets (project category, asset type, cost type) use `TEXT` with a `CHECK` constraint against a lookup table (`core.lookup_values`) rather than a native enum, so KEM-052's explicit requirement that these sets be extensible without a schema migration (§13, §16) is honored.

---

# 6. ENUM & LOOKUP TYPE DEFINITIONS

## 6.1 Native PostgreSQL Enums (closed sets)

```sql
CREATE TYPE record_status            AS ENUM ('ACTIVE','INACTIVE','ARCHIVED');

CREATE TYPE project_status           AS ENUM (
  'IDEA','PLANNING','APPROVED','BUILDING','TESTING',
  'STAGING','LIVE','MAINTENANCE','SUSPENDED','RETIRED','ARCHIVED');

CREATE TYPE project_criticality      AS ENUM ('LOW','MEDIUM','HIGH','CRITICAL');

CREATE TYPE environment_type         AS ENUM ('DEV','TEST','STAGE','PROD','DR');

CREATE TYPE deployment_status        AS ENUM (
  'QUEUED','RUNNING','SUCCESS','FAILED','ROLLED_BACK','CANCELLED');

CREATE TYPE incident_severity        AS ENUM ('SEV-1','SEV-2','SEV-3','SEV-4');

CREATE TYPE incident_status          AS ENUM (
  'OPEN','INVESTIGATING','MITIGATED','RESOLVED','CLOSED');

CREATE TYPE change_status            AS ENUM (
  'REQUESTED','APPROVED','REJECTED','SCHEDULED',
  'IMPLEMENTING','COMPLETED','ROLLED_BACK');

CREATE TYPE change_risk_level        AS ENUM ('LOW','MEDIUM','HIGH','CRITICAL');

CREATE TYPE backup_status            AS ENUM ('HEALTHY','WARNING','FAILED','UNKNOWN');

CREATE TYPE ai_autonomy_level        AS ENUM (
  'L0_OBSERVE','L1_RECOMMEND','L2_LOW_RISK_AUTOMATION',
  'L3_APPROVAL_REQUIRED','L4_GUARDED_AUTONOMY');

CREATE TYPE dependency_type          AS ENUM (
  'REQUIRES','DEPENDS_ON','HOSTED_ON','CONNECTS_TO',
  'DEPLOYS_TO','READS_FROM','WRITES_TO','AUTHENTICATES_WITH');

CREATE TYPE health_status            AS ENUM ('HEALTHY','WARNING','CRITICAL','UNKNOWN');

CREATE TYPE identity_owner_type      AS ENUM ('USER','TEAM','ORGANIZATION');

CREATE TYPE ssl_status               AS ENUM ('VALID','EXPIRING','EXPIRED','NOT_CONFIGURED','UNKNOWN');
```

## 6.2 Extensible Lookup Table (open sets)

```text
core.lookup_values
------------------------------------------------
id            UUID          PK
category      TEXT          NOT NULL   -- e.g. 'PROJECT_CATEGORY','ASSET_TYPE','COST_TYPE'
value         TEXT          NOT NULL   -- e.g. 'SAAS','FINTECH'
label         TEXT          NOT NULL
is_active     BOOLEAN       NOT NULL DEFAULT true
sort_order    INTEGER       NOT NULL DEFAULT 0
created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()

UNIQUE (category, value)
```

Seeded categories at launch (Section 13):

```text
PROJECT_CATEGORY:  SAAS, AI, AUTOMATION, ECOMMERCE, EDUCATION, HEALTHCARE,
                    REAL_ESTATE, MEDIA, FINTECH, INTERNAL, EXPERIMENTAL

ASSET_TYPE:        SERVER, DATABASE, REPOSITORY, DOMAIN, SERVICE, STORAGE,
                    CERTIFICATE, API, WORKFLOW, AI_AGENT, MODEL, DOCUMENT, OTHER

COST_TYPE:         INFRASTRUCTURE, DATABASE, STORAGE, DOMAIN, API, AI,
                    AUTOMATION, SOFTWARE, OTHER

SERVER_PROVIDER_TYPE: VPS_PROVIDER, CLOUD_PROVIDER, DEDICATED_HOST, ON_PREMISE

DATABASE_ENGINE:   POSTGRESQL, MYSQL, MARIADB, MONGODB, REDIS, SQLITE, OTHER

EVENT_TYPE:        PROJECT_CREATED, ASSET_CREATED, DEPLOYMENT_STARTED,
                    DEPLOYMENT_FAILED, BACKUP_FAILED, SERVER_UNHEALTHY,
                    DOMAIN_EXPIRING, CERTIFICATE_EXPIRING

DRIFT_SEVERITY:    INFO, WARNING, CRITICAL
```

---

# 7. TABLE SPECIFICATIONS

## 7.1 IDENTITY SCHEMA

### `identity.users`

```text
id                UUID          PK DEFAULT gen_random_uuid()
auth_user_id      UUID          UNIQUE NOT NULL   -- FK → auth.users(id) [Supabase Auth]
user_code         TEXT          UNIQUE NOT NULL   -- USR-001
full_name         TEXT          NOT NULL
email             TEXT          UNIQUE NOT NULL
status            record_status NOT NULL DEFAULT 'ACTIVE'
is_service_account BOOLEAN      NOT NULL DEFAULT false
last_login_at     TIMESTAMPTZ   NULL
created_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
archived_at       TIMESTAMPTZ   NULL

Indexes: idx_users_auth_user_id, idx_users_email, idx_users_status
```

`auth_user_id` is the single, non-negotiable link into Supabase Auth (KEM-052 §59). No password, token, or credential is ever stored in this table (KEM-052 §61).

### `identity.roles`

```text
id            UUID          PK
role_code     TEXT          UNIQUE NOT NULL     -- e.g. SUPER_ADMIN
name          TEXT          NOT NULL
description   TEXT
is_system     BOOLEAN       NOT NULL DEFAULT true   -- false for KemetRise-defined custom roles
status        record_status NOT NULL DEFAULT 'ACTIVE'
created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
```

### `identity.permissions`

```text
id             UUID          PK
permission_code TEXT         UNIQUE NOT NULL   -- e.g. projects.create
resource        TEXT         NOT NULL          -- e.g. projects
action          TEXT         NOT NULL          -- e.g. create
description     TEXT
created_at      TIMESTAMPTZ  NOT NULL DEFAULT now()

UNIQUE (resource, action)
```

### `identity.role_permissions`

```text
role_id         UUID  REFERENCES identity.roles(id)       ON DELETE CASCADE
permission_id   UUID  REFERENCES identity.permissions(id) ON DELETE CASCADE
PRIMARY KEY (role_id, permission_id)
```

### `identity.user_roles`

```text
user_id         UUID  REFERENCES identity.users(id) ON DELETE CASCADE
role_id         UUID  REFERENCES identity.roles(id) ON DELETE CASCADE
scope_project_id UUID REFERENCES core.projects(id) ON DELETE CASCADE NULL   -- NULL = global scope
granted_by      UUID  REFERENCES identity.users(id)
granted_at      TIMESTAMPTZ NOT NULL DEFAULT now()

PRIMARY KEY (user_id, role_id, COALESCE(scope_project_id, '00000000-0000-0000-0000-000000000000'))
Indexes: idx_user_roles_user, idx_user_roles_project
```

`scope_project_id` implements KEM-052 §47 Project-Scoped Access (USER A → PROJECT 001 → READ) directly at the assignment level, avoiding a separate project-access table.

---

## 7.2 CORE SCHEMA

### `core.projects`

```text
id              UUID              PK
project_code    TEXT              UNIQUE NOT NULL      -- PRJ-001+ for ordinary projects; PRJ-000 permanently reserved (Section 5.2, DECISION LOCKED)
name            TEXT              NOT NULL
slug            TEXT              UNIQUE NOT NULL
description     TEXT
category        TEXT              NOT NULL             -- FK-checked against lookup_values('PROJECT_CATEGORY')
status          project_status    NOT NULL DEFAULT 'IDEA'
criticality     project_criticality NOT NULL DEFAULT 'MEDIUM'
owner_type      identity_owner_type NOT NULL DEFAULT 'USER'
owner_id        UUID              NOT NULL             -- REFERENCES identity.users(id) when owner_type='USER'
is_system       BOOLEAN           NOT NULL DEFAULT false  -- true only for PRJ-000 (Control Tower itself)
created_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
updated_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
archived_at     TIMESTAMPTZ       NULL

Indexes: idx_projects_status, idx_projects_criticality, idx_projects_owner
Check:   chk_projects_category valid against lookup_values
```

### `core.environments`

```text
id                       UUID              PK
env_code                 TEXT              UNIQUE NOT NULL   -- ENV-001
project_id               UUID              NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
name                     TEXT              NOT NULL
environment_type         environment_type  NOT NULL
status                   record_status     NOT NULL DEFAULT 'ACTIVE'
configuration_reference  TEXT              NULL   -- secret:// pointer, never a raw value
created_at               TIMESTAMPTZ       NOT NULL DEFAULT now()
updated_at               TIMESTAMPTZ       NOT NULL DEFAULT now()

UNIQUE (project_id, environment_type)
Indexes: idx_environments_project
```

### `core.assets`

```text
id              UUID          PK
asset_code      TEXT          UNIQUE NOT NULL   -- AST-001
project_id      UUID          NULL REFERENCES core.projects(id) ON DELETE SET NULL
                                     -- NULL when asset is shared across projects (see asset_projects)
asset_type      TEXT          NOT NULL          -- FK-checked against lookup_values('ASSET_TYPE')
name            TEXT          NOT NULL
description     TEXT
status          record_status NOT NULL DEFAULT 'ACTIVE'
criticality     project_criticality NOT NULL DEFAULT 'MEDIUM'
environment_id  UUID          NULL REFERENCES core.environments(id)
owner_id        UUID          NULL REFERENCES identity.users(id)
metadata        JSONB         NOT NULL DEFAULT '{}'::jsonb
created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
archived_at     TIMESTAMPTZ   NULL

Indexes: idx_assets_project, idx_assets_type, idx_assets_status, idx_assets_environment
```

### `core.asset_projects`

Implements KEM-052 §52 (Shared Assets — an asset serving multiple projects).

```text
asset_id      UUID REFERENCES core.assets(id)   ON DELETE CASCADE
project_id    UUID REFERENCES core.projects(id) ON DELETE CASCADE
relationship  TEXT NOT NULL DEFAULT 'SHARED'    -- SHARED | PRIMARY
created_at    TIMESTAMPTZ NOT NULL DEFAULT now()

PRIMARY KEY (asset_id, project_id)
```

### `core.asset_dependencies`

```text
id                UUID              PK
source_asset_id   UUID              NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
target_asset_id   UUID              NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
dependency_type   dependency_type   NOT NULL
criticality       project_criticality NOT NULL DEFAULT 'MEDIUM'
status            record_status     NOT NULL DEFAULT 'ACTIVE'
created_at        TIMESTAMPTZ       NOT NULL DEFAULT now()

CHECK (source_asset_id <> target_asset_id)
UNIQUE (source_asset_id, target_asset_id, dependency_type)
Indexes: idx_asset_deps_source, idx_asset_deps_target
```

### `core.documents`

**DECISION LOCKED (2026-09-03):** documents use **Supabase Storage + database metadata**. The database never stores binary file content directly in PostgreSQL, unless a specific, individually-documented technical exception is raised and approved later. `storage_path` holds a Supabase Storage object path; the database row is metadata, ownership, classification, and relationships only.

```text
id              UUID          PK
document_code   TEXT          UNIQUE NOT NULL   -- DOC-001
project_id      UUID          NULL REFERENCES core.projects(id) ON DELETE CASCADE
title           TEXT          NOT NULL
doc_type        TEXT          NOT NULL
version         TEXT          NOT NULL DEFAULT '1.0.0'
storage_path    TEXT          NOT NULL   -- Supabase Storage object path, e.g. documents/prj-001/doc-001.pdf
                                          -- (NOT a raw external URL — governed Storage bucket only)
status          record_status NOT NULL DEFAULT 'ACTIVE'
classification  TEXT          NOT NULL DEFAULT 'INTERNAL'   -- see Section 18 item on data classification
owner_id        UUID          NULL REFERENCES identity.users(id)
updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_documents_project
```

Storage bucket access is governed by Supabase Storage RLS policies that mirror the exact same `identity.has_project_access()` logic used for table RLS (Section 9) — Storage access must never bypass the authorization model that protects the corresponding metadata row.

(MVP-secondary per KEM-052 §131.)

---

## 7.3 INFRASTRUCTURE SCHEMA

### `infrastructure.servers`

```text
id                 UUID          PK
server_code        TEXT          UNIQUE NOT NULL   -- SRV-001
asset_id           UUID          NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
provider           TEXT          NOT NULL          -- FK-checked lookup_values('SERVER_PROVIDER_TYPE')
hostname           TEXT          NOT NULL
ip_reference       TEXT          NULL   -- reference/label, never a bare exposed internal IP if sensitive
server_type        TEXT          NOT NULL   -- DEDICATED | SHARED
operating_system   TEXT          NULL
region             TEXT          NULL
status             record_status NOT NULL DEFAULT 'ACTIVE'
capacity_metadata  JSONB         NOT NULL DEFAULT '{}'::jsonb
created_at         TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at         TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_servers_asset, idx_servers_status
```
No credential columns exist on this table (KEM-052 §17, enforced by omission).

### `infrastructure.databases`

```text
id                       UUID          PK
database_code            TEXT          UNIQUE NOT NULL   -- DB-001
asset_id                 UUID          NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
project_id               UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
engine                   TEXT          NOT NULL   -- FK-checked lookup_values('DATABASE_ENGINE')
version                  TEXT          NULL
provider                 TEXT          NULL
host_reference           TEXT          NULL   -- reference/label only
database_name_reference  TEXT          NULL   -- reference/label only
environment_id           UUID          NULL REFERENCES core.environments(id)
status                   record_status NOT NULL DEFAULT 'ACTIVE'
created_at               TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at               TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_databases_project, idx_databases_asset
```

### `infrastructure.repositories`

```text
id                        UUID          PK
repository_code           TEXT          UNIQUE NOT NULL   -- REPO-001
asset_id                  UUID          NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
project_id                UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
provider                  TEXT          NOT NULL   -- GITHUB | GITLAB | BITBUCKET | OTHER
repository_name           TEXT          NOT NULL
repository_url_reference   TEXT         NOT NULL
default_branch             TEXT         NOT NULL DEFAULT 'main'
visibility                 TEXT         NOT NULL DEFAULT 'PRIVATE'
status                     record_status NOT NULL DEFAULT 'ACTIVE'
created_at                 TIMESTAMPTZ  NOT NULL DEFAULT now()
updated_at                 TIMESTAMPTZ  NOT NULL DEFAULT now()

Indexes: idx_repositories_project
```

### `infrastructure.domains`

```text
id                UUID          PK
domain_code       TEXT          UNIQUE NOT NULL   -- DOM-001
asset_id          UUID          NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
project_id        UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
domain_reference  TEXT          NOT NULL UNIQUE
provider          TEXT          NULL
status            record_status NOT NULL DEFAULT 'ACTIVE'
ssl_status        ssl_status    NOT NULL DEFAULT 'UNKNOWN'
expiration_date   DATE          NULL
created_at        TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at        TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_domains_project, idx_domains_expiration (for expiry-alert automation, KEM-052 §124)
```

### `infrastructure.services`

```text
id              UUID          PK
service_code    TEXT          UNIQUE NOT NULL   -- SVC-001
asset_id        UUID          NOT NULL REFERENCES core.assets(id) ON DELETE CASCADE
project_id      UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
name            TEXT          NOT NULL
service_type    TEXT          NOT NULL
version         TEXT          NULL
environment_id  UUID          NULL REFERENCES core.environments(id)
server_id       UUID          NULL REFERENCES infrastructure.servers(id)
status          record_status NOT NULL DEFAULT 'ACTIVE'
health_status   health_status NOT NULL DEFAULT 'UNKNOWN'
created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()
updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_services_project, idx_services_server, idx_services_health
```

### `infrastructure.certificates`

```text
id              UUID          PK
certificate_code TEXT         UNIQUE NOT NULL   -- CERT-001
domain_id       UUID          NOT NULL REFERENCES infrastructure.domains(id) ON DELETE CASCADE
issuer          TEXT          NULL
valid_from      DATE          NULL
valid_until     DATE          NULL
status          ssl_status    NOT NULL DEFAULT 'UNKNOWN'
created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_certificates_domain, idx_certificates_valid_until
```

(MVP-secondary per KEM-052 §131.)

---

## 7.4 OPERATIONS SCHEMA

### `operations.deployments`

```text
id                UUID              PK
deployment_code   TEXT              UNIQUE NOT NULL   -- DEP-001
project_id        UUID              NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
environment_id    UUID              NOT NULL REFERENCES core.environments(id)
repository_id     UUID              NULL REFERENCES infrastructure.repositories(id)
version           TEXT              NULL
status            deployment_status NOT NULL DEFAULT 'QUEUED'
triggered_by      UUID              NULL REFERENCES identity.users(id)
started_at        TIMESTAMPTZ       NULL
completed_at      TIMESTAMPTZ       NULL
rollback_available BOOLEAN          NOT NULL DEFAULT false
metadata          JSONB             NOT NULL DEFAULT '{}'::jsonb

Indexes: idx_deployments_project, idx_deployments_status, idx_deployments_environment
```

### `operations.incidents`

```text
id              UUID              PK
incident_code   TEXT              UNIQUE NOT NULL   -- INC-001
project_id      UUID              NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
asset_id        UUID              NULL REFERENCES core.assets(id)
severity        incident_severity NOT NULL
status          incident_status   NOT NULL DEFAULT 'OPEN'
title           TEXT              NOT NULL
description     TEXT              NULL
detected_at     TIMESTAMPTZ       NOT NULL DEFAULT now()
resolved_at     TIMESTAMPTZ       NULL
assigned_to     UUID              NULL REFERENCES identity.users(id)
root_cause      TEXT              NULL
resolution      TEXT              NULL

Indexes: idx_incidents_project, idx_incidents_status, idx_incidents_severity
```

### `operations.changes`

```text
id              UUID              PK
change_code     TEXT              UNIQUE NOT NULL   -- CHG-001
project_id      UUID              NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
asset_id        UUID              NULL REFERENCES core.assets(id)
change_type     TEXT              NOT NULL
description     TEXT              NOT NULL
reason          TEXT              NULL
risk_level      change_risk_level NOT NULL DEFAULT 'LOW'
requested_by    UUID              NOT NULL REFERENCES identity.users(id)
approved_by     UUID              NULL REFERENCES identity.users(id)
status          change_status     NOT NULL DEFAULT 'REQUESTED'
created_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
completed_at    TIMESTAMPTZ       NULL

Indexes: idx_changes_project, idx_changes_status
Check: chk_changes_high_risk_requires_approval
       (risk_level IN ('HIGH','CRITICAL') → approved_by IS NOT NULL before status='COMPLETED')
```

### `operations.backups`

```text
id                UUID          PK
backup_code       TEXT          UNIQUE NOT NULL   -- BKP-001
project_id        UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
asset_id          UUID          NOT NULL REFERENCES core.assets(id)
backup_type       TEXT          NOT NULL
provider          TEXT          NULL
schedule          TEXT          NULL   -- cron-like descriptor
retention         TEXT          NULL   -- e.g. '30d'
last_backup_at    TIMESTAMPTZ   NULL
last_verified_at  TIMESTAMPTZ   NULL
status            backup_status NOT NULL DEFAULT 'UNKNOWN'

Indexes: idx_backups_project, idx_backups_status, idx_backups_asset
```

### `operations.events`

```text
id             UUID          PK
event_type     TEXT          NOT NULL   -- FK-checked lookup_values('EVENT_TYPE')
project_id     UUID          NULL REFERENCES core.projects(id)
resource_type  TEXT          NOT NULL
resource_id    UUID          NOT NULL
payload        JSONB         NOT NULL DEFAULT '{}'::jsonb
status         TEXT          NOT NULL DEFAULT 'PENDING'   -- PENDING | PROCESSED | FAILED
created_at     TIMESTAMPTZ   NOT NULL DEFAULT now()
processed_at   TIMESTAMPTZ   NULL

Indexes: idx_events_project, idx_events_status, idx_events_created_at
```

(MVP-secondary per KEM-052 §131.)

### `operations.notifications`

```text
id            UUID          PK
recipient_id  UUID          NOT NULL REFERENCES identity.users(id)
channel       TEXT          NOT NULL   -- EMAIL | IN_APP | WEBHOOK
subject       TEXT          NOT NULL
body          TEXT          NULL
related_event_id UUID       NULL REFERENCES operations.events(id)
status        TEXT          NOT NULL DEFAULT 'PENDING'   -- PENDING | SENT | FAILED
created_at    TIMESTAMPTZ   NOT NULL DEFAULT now()
sent_at       TIMESTAMPTZ   NULL

Indexes: idx_notifications_recipient, idx_notifications_status
```

(MVP-secondary per KEM-052 §131.)

---

## 7.5 AUTOMATION SCHEMA

### `automation.workflows`

```text
id             UUID          PK
workflow_code  TEXT          UNIQUE NOT NULL   -- WF-001
project_id     UUID          NULL REFERENCES core.projects(id) ON DELETE CASCADE
name           TEXT          NOT NULL
engine         TEXT          NOT NULL DEFAULT 'N8N'
trigger_type   TEXT          NOT NULL
purpose        TEXT          NULL
status         record_status NOT NULL DEFAULT 'ACTIVE'
version         TEXT         NOT NULL DEFAULT '1.0.0'
owner_id        UUID         NULL REFERENCES identity.users(id)
n8n_reference    TEXT        NULL   -- external n8n workflow ID; full definition not duplicated (KEM-052 §29)
created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()

Indexes: idx_workflows_project, idx_workflows_status
```

---

## 7.6 AI SCHEMA

### `ai.models`

```text
id              UUID          PK
provider        TEXT          NOT NULL
model_name      TEXT          NOT NULL
model_version   TEXT          NULL
capabilities    JSONB         NOT NULL DEFAULT '[]'::jsonb
status          record_status NOT NULL DEFAULT 'ACTIVE'
metadata        JSONB         NOT NULL DEFAULT '{}'::jsonb

UNIQUE (provider, model_name, model_version)
```

### `ai.agents`

```text
id              UUID              PK
agent_code      TEXT              UNIQUE NOT NULL   -- AGT-001
project_id      UUID              NULL REFERENCES core.projects(id) ON DELETE CASCADE
name            TEXT              NOT NULL
role            TEXT              NOT NULL
status          record_status     NOT NULL DEFAULT 'ACTIVE'
model_id        UUID              NULL REFERENCES ai.models(id)
autonomy_level  ai_autonomy_level NOT NULL DEFAULT 'L0_OBSERVE'
owner_id        UUID              NULL REFERENCES identity.users(id)
service_account_user_id UUID      NULL REFERENCES identity.users(id)
                                    -- KEM-052 §108: AI agents operate under scoped service identities
created_at      TIMESTAMPTZ       NOT NULL DEFAULT now()
updated_at      TIMESTAMPTZ       NOT NULL DEFAULT now()

Indexes: idx_agents_project, idx_agents_status
Check: chk_agents_l3_l4_require_owner (autonomy_level IN ('L3_APPROVAL_REQUIRED','L4_GUARDED_AUTONOMY') → owner_id IS NOT NULL)
```

---

## 7.7 FINANCE SCHEMA

### `finance.costs`

```text
id              UUID          PK
cost_code       TEXT          UNIQUE NOT NULL   -- COST-001 (optional; may be omitted per row at high volume)
project_id      UUID          NOT NULL REFERENCES core.projects(id) ON DELETE CASCADE
asset_id        UUID          NULL REFERENCES core.assets(id)
provider        TEXT          NULL
cost_type       TEXT          NOT NULL   -- FK-checked lookup_values('COST_TYPE')
amount          NUMERIC(14,2) NOT NULL
currency        CHAR(3)       NOT NULL DEFAULT 'USD'
billing_period  DATERANGE     NOT NULL
status          TEXT          NOT NULL DEFAULT 'RECORDED'
created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_costs_project, idx_costs_billing_period (GiST)
Check: chk_costs_amount_nonnegative (amount >= 0)
```

Note: this table intentionally stores **cost records**, not payment credentials or billing account secrets (out of scope, references KEM-032 governance).

---

## 7.8 AUDIT SCHEMA

### `audit.audit_events`

```text
id             UUID          PK
actor_id       UUID          NULL REFERENCES identity.users(id)   -- NULL for system/trigger-originated events
action         TEXT          NOT NULL   -- CREATE | UPDATE | DELETE | ARCHIVE | DEPLOY | ROLLBACK |
                                          -- LOGIN | LOGOUT | PERMISSION_CHANGE | CONFIGURATION_CHANGE
resource_type  TEXT          NOT NULL
resource_id    UUID          NOT NULL
project_id     UUID          NULL REFERENCES core.projects(id)
timestamp      TIMESTAMPTZ   NOT NULL DEFAULT now()
result         TEXT          NOT NULL DEFAULT 'SUCCESS'   -- SUCCESS | FAILURE
metadata        JSONB        NOT NULL DEFAULT '{}'::jsonb   -- column-level diff / context

Indexes: idx_audit_resource, idx_audit_project, idx_audit_timestamp, idx_audit_actor
```

This table is **append-only**: no `UPDATE` or `DELETE` grants exist for any role, including `SUPER_ADMIN`, at the database level (enforced by RLS + REVOKE, Section 9.6).

---

## 7.9 SECURITY SCHEMA

### `security.secret_references`

**DECISION LOCKED (2026-09-03):** this table's shape is approved as the governed home for every `secret://`-style pointer in the schema (previously flagged REQUIRES DECISION in Section 16 — now closed).

```text
id              UUID          PK
reference_key   TEXT          UNIQUE NOT NULL   -- secret://project-001/prod/database
project_id      UUID          NULL REFERENCES core.projects(id)
environment_id  UUID          NULL REFERENCES core.environments(id)
description     TEXT          NULL
managed_by      TEXT          NOT NULL DEFAULT 'EXTERNAL'   -- vault system name; value itself never stored
status          record_status NOT NULL DEFAULT 'ACTIVE'
created_at      TIMESTAMPTZ   NOT NULL DEFAULT now()

Indexes: idx_secret_refs_project
```

**Hard rule (non-negotiable, applies to this table and every other table in this database):** this schema never stores, in any column, in any table:

```text
API keys
Passwords
Access tokens
Private keys
Credentials of any kind
Raw secret values of any kind
```

The database stores only a *reference* — a `secret://...`-style pointer — to where the actual secret lives. The secret value itself is held exclusively in an external secrets-management mechanism (vault/KMS/environment-injection system), entirely outside this database. This is consistent with, and does not weaken, KEM-052 §61.

---

# 8. RELATIONSHIP MODEL & CARDINALITY

```text
core.projects (1) ──< core.environments (N)
core.projects (1) ──< core.assets (N)                [nullable FK; shared assets via asset_projects]
core.assets   (M) ──< core.asset_projects >── (N) core.projects
core.assets   (1) ──< infrastructure.servers (1)      [1:1 via asset_id]
core.assets   (1) ──< infrastructure.databases (1)
core.assets   (1) ──< infrastructure.repositories (1)
core.assets   (1) ──< infrastructure.domains (1)
core.assets   (1) ──< infrastructure.services (1)
core.assets   (M) ──< core.asset_dependencies >── (N) core.assets   [self-referential graph]
core.projects (1) ──< operations.deployments (N)
core.projects (1) ──< operations.incidents (N)
core.projects (1) ──< operations.changes (N)
core.projects (1) ──< operations.backups (N)
core.projects (1) ──< automation.workflows (N)
core.projects (1) ──< ai.agents (N)
core.projects (1) ──< finance.costs (N)
identity.users (1) ──< identity.user_roles (N) >── (1) identity.roles
identity.roles (1) ──< identity.role_permissions (N) >── (1) identity.permissions
identity.users (1) ──< audit.audit_events (N)          [as actor]
infrastructure.domains (1) ──< infrastructure.certificates (N)
infrastructure.servers (1) ──< infrastructure.services (N)
```

Every table listed in Section 7 traces back to `core.projects` directly or transitively, matching KEM-052 §48's Relationship Model, with the deliberate exception of shared/global entities (`identity.*`, `ai.models`, `core.lookup_values`, `security.secret_references` when `project_id IS NULL`).

---

# 9. ROW LEVEL SECURITY (RLS) STRATEGY

RLS is **enabled on every table in every schema** except `core.lookup_values` (public read reference data) and native enum-backed tables with no rows containing sensitive data. This satisfies KEM-052 §70/§71 and the default-deny principle of KEM-052 §104.

## 9.1 Authentication Relationship

```text
auth.users (Supabase Auth)  →  identity.users.auth_user_id  →  application identity
```

All RLS policies resolve the current request's identity via:

```sql
identity.current_user_id() → SELECT id FROM identity.users WHERE auth_user_id = auth.uid()
```

## 9.2 Role Resolution Helper

```sql
identity.has_role(role_code TEXT) RETURNS BOOLEAN
identity.has_permission(permission_code TEXT) RETURNS BOOLEAN
identity.has_project_access(project_id UUID, min_role TEXT DEFAULT NULL) RETURNS BOOLEAN
```

These are `SECURITY DEFINER` functions used inside every RLS policy so policy logic stays in one auditable place rather than duplicated per table.

## 9.3 Baseline Policy Pattern (project-scoped tables)

```sql
-- SELECT
USING ( identity.has_role('SUPER_ADMIN')
        OR identity.has_role('ADMIN')
        OR identity.has_project_access(project_id) )

-- INSERT/UPDATE
WITH CHECK ( identity.has_role('SUPER_ADMIN')
             OR identity.has_role('ADMIN')
             OR identity.has_project_access(project_id, 'WRITE') )

-- DELETE (governed hard-delete path only — see 12.6)
USING ( identity.has_role('SUPER_ADMIN') )
```

## 9.4 Role-to-Access Baseline (resolves the KEM-003 / KEM-020 / KEM-052 role-list conflict — Section 15, Conflict #3)

The **KEM-052 role list is authoritative** for database-level RLS role checks:

```text
SUPER_ADMIN       → full read/write on all schemas, only role with hard-delete + audit-table bypass (read-only even here)
ADMIN             → full read/write on all schemas except identity.role_permissions (role design)
PROJECT_MANAGER    → read/write scoped to assigned projects via user_roles.scope_project_id
DEVELOPER          → read on assigned projects; write on assets/deployments/repositories in assigned projects
DEVOPS             → read/write on infrastructure.* + operations.* for assigned projects
SECURITY            → read all; write on security.secret_references, audit read-only
VIEWER               → read-only, scoped to assigned projects
AI_AGENT             → scoped exactly like DEVELOPER but gated additionally by ai.agents.autonomy_level
                        (L0/L1 = read-only regardless of role; L2+ required for any write)
SERVICE_ACCOUNT       → scoped narrowly per integration, defined per service account row, default deny-all
```

Roles named only in KEM-003/KEM-020 (`EXECUTIVE`, `FINANCE`, `TECH_LEAD`, `DATABASE_ADMIN`, `CONTENT_MANAGER`, `MARKETING`, `PROJECT_OWNER`) are **not created** in this schema at MVP. `identity.roles.is_system = false` allows KemetRise to add any of them later as custom roles without a schema change.

## 9.5 Service-Role / Admin API Boundary

```text
anon key           → no table access (all RLS default-deny; used only for public, unauthenticated endpoints if any)
authenticated role  → subject to full RLS policy set above
service_role key    → bypasses RLS entirely; used ONLY by trusted backend/n8n server-side processes,
                       never exposed to any frontend or AI agent directly
```

Per KEM-052 §107–109, AI agents never receive the `service_role` key. They authenticate as `identity.users` rows with `is_service_account = true`, subject to full RLS like any other user.

## 9.6 Audit Table Boundary

`audit.audit_events`: `INSERT` only, via `SECURITY DEFINER` trigger functions. No role — including `SUPER_ADMIN` — has direct `UPDATE`/`DELETE` grants. This is enforced both by RLS policy and by PostgreSQL `REVOKE UPDATE, DELETE ON audit.audit_events FROM PUBLIC`.

---

# 10. MIGRATION DESIGN

Migration order follows and expands KEM-052 §150 (Implementation Order) and §186 (Bootstrap Sequence). Each numbered item below is one migration file.

```text
001  Extensions            pgcrypto / uuid-ossp for gen_random_uuid()
002  Enum types             all types in Section 6.1
003  Schemas                 core, identity, infrastructure, operations,
                              automation, ai, finance, security, audit
004  identity.users
005  identity.roles, identity.permissions, identity.role_permissions
006  identity.user_roles
007  identity.helper functions (current_user_id, has_role, has_permission, has_project_access)
008  core.lookup_values      + seed (Section 13.1)
009  core.projects
010  core.environments
011  core.assets
012  core.asset_projects
013  core.asset_dependencies
014  core.documents
015  infrastructure.servers
016  infrastructure.databases
017  infrastructure.repositories
018  infrastructure.domains
019  infrastructure.certificates
020  infrastructure.services
021  operations.deployments
022  operations.incidents
023  operations.changes
024  operations.backups
025  operations.events
026  operations.notifications
027  automation.workflows
028  ai.models
029  ai.agents
030  finance.costs
031  security.secret_references
032  audit.audit_events + audit trigger functions on all governed tables
033  RLS enablement + policies (all tables, per Section 9)
034  updated_at / archived_at maintenance triggers (all tables, Section 5.4/5.6)
035  Seed data (Section 13) — roles, permissions, system admin, PRJ-000
```

**Migration dependency rule (KEM-052 §113):** no migration may be applied to a production Supabase project without being version-controlled and reviewed; this document does not authorize running any of the above yet (see Section 11 of the reconciliation directive — SPECIFICATION ONLY phase).

---

# 11. SUPABASE-SPECIFIC IMPLEMENTATION NOTES

```text
Auth:      Supabase Auth manages auth.users; identity.users mirrors it via auth_user_id
                 with a trigger (handle_new_user) that auto-creates an identity.users row
                 on auth.users INSERT, defaulting to no roles (deny-all until granted).
RLS:       Enabled table-by-table in migration 033, never via a blanket ALTER.
Storage:   DECISION LOCKED — core.documents.storage_path points to a Supabase Storage object
                 path. The Storage bucket's own RLS policies mirror identity.has_project_access()
                 exactly, so a user who cannot read a project's documents row also cannot read
                 the underlying file object. Binary content is never stored in PostgreSQL itself.
Realtime:   May be enabled selectively on operations.incidents and operations.deployments
                 for live dashboard updates (KEM-052 §83). Not required for MVP.
Functions:  SECURITY DEFINER functions (Section 9.2) are the only privileged code path;
                 all other application access goes through RLS-scoped queries.
```

---

# 12. DATA GOVERNANCE

## 12.1 Naming Conventions
Per Section 5.3 — snake_case tables/columns, `<TYPE>-###` human codes, `idx_/fk_/uq_/chk_` prefixes.

## 12.2 ID Conventions
UUID primary keys everywhere; human-readable codes are a parallel unique identifier, never the primary key, never reused after archival (KEM-002 §9, retained).

## 12.3 Timestamp Conventions
UTC `TIMESTAMPTZ` everywhere; `created_at`/`updated_at` mandatory on every operational table; `updated_at` maintained by trigger, never trusted from application input.

## 12.4 Status / Enum Conventions
Closed sets → native PostgreSQL enum. Open/extensible sets → `core.lookup_values` + `CHECK`. No table stores a free-text status column without one of these two mechanisms.

## 12.5 Foreign-Key Behavior

```text
ON DELETE CASCADE    → strictly ownership relationships (project → environments/deployments/etc.)
ON DELETE SET NULL    → optional/soft relationships (assets.project_id when asset is shared)
ON DELETE RESTRICT     → default for any FK not explicitly listed above (identity.roles referenced
                          by user_roles, etc. — prevents silent orphaning of security-relevant rows)
```

## 12.6 Delete / Update Behavior — Soft Delete Governance

Per KEM-052 §65 and KEM-000 §47 (Non-Destructive Development), **archival is the default deletion mechanism**:

```text
Normal path:    status → 'ARCHIVED'   (trigger sets archived_at, row remains, all FKs intact)
Governed hard delete:  requires SUPER_ADMIN role + explicit audit.audit_events entry with
                        action='DELETE' + a completed operations.changes record referencing it.
                        deleted_at is set for record-keeping only; the row may then be physically
                        removed by a separate, manually-invoked retention job — never by application code.
```

## 12.7 Audit Requirements
Every `CREATE`, `UPDATE` of status/ownership/security fields, `ARCHIVE`, `DEPLOY`, `ROLLBACK`, `LOGIN`, `LOGOUT`, `PERMISSION_CHANGE`, and `CONFIGURATION_CHANGE` is captured in `audit.audit_events` (KEM-052 §43, verbatim).

## 12.8 Data Retention

**DECISION LOCKED (2026-09-03):** retention is defined explicitly per category — 7-year retention applies **only** to the business/security/audit-critical category, not to every table by default. This is a starting policy, not a permanent one, and remains subject to future legal/compliance review.

```text
CATEGORY: BUSINESS / SECURITY / AUDIT-CRITICAL
  Tables:    audit.audit_events (all rows)
             operations.changes (change/approval records)
             operations.incidents (SEV-1/SEV-2 rows specifically)
             identity.user_roles (role-grant history, via audit trail)
  Retention: 7 YEARS from creation, then eligible for archival/deletion review
             (not automatic deletion — requires a governed hard-delete pass, Section 12.6)

CATEGORY: OPERATIONAL / TRANSIENT
  Tables:    operations.events
  Retention: 90 days rolling — safe to prune automatically, not audit-critical

CATEGORY: NOTIFICATION / DELIVERY
  Tables:    operations.notifications
  Retention: 180 days rolling — safe to prune automatically

CATEGORY: OPERATIONAL / LOW SEVERITY
  Tables:    operations.incidents (SEV-3/SEV-4 rows), operations.deployments,
             operations.backups (superseded/historical rows)
  Retention: 2 years rolling — reviewed on the same 7-year compliance cycle, but
             not held to the full 7-year bar unless escalated
```

The 7-year figure is **not** license to retain every category of data indefinitely — only the explicitly-named business/security/audit-critical category carries it. Any table not listed above defaults to the OPERATIONAL/TRANSIENT category (90 days) until explicitly reclassified.

## 12.9 Immutable Records
`audit.audit_events` rows are immutable once written (Section 9.6). `identity.user_roles.granted_at` and `core.projects.project_code` are immutable after creation (no `UPDATE` grant on these specific columns).

---

# 13. SEED DATA

## 13.1 Required Seed Data

```text
core.lookup_values         → all category/value pairs listed in Section 6.2
identity.roles              → the 9 KEM-052 roles listed in Section 9.4
identity.permissions         → baseline CRUD permission set per resource:
                                 projects.{read,create,update,archive}
                                 assets.{read,create,update,archive}
                                 environments.{read,create,update}
                                 deployments.{read,create,execute,rollback}
                                 incidents.{read,create,update,assign,resolve,close}
                                 changes.{read,create,approve,reject}
                                 backups.{read,create}
                                 automations.{read,create,update,execute}
                                 ai.{read,create,update}
                                 finance.{read,create}
                                 audit.{read}
                                 identity.{read,create,update}
identity.role_permissions    → SUPER_ADMIN gets every permission; other roles per Section 9.4 intent
core.projects (PRJ-000)      → the Control Tower's own system project record (KEM-052 §184), is_system=true
identity.users (bootstrap admin) → created by the Supabase Auth signup flow + trigger, then manually
                                     assigned SUPER_ADMIN in identity.user_roles (KEM-052 §186 step 2)
```

## 13.2 Optional Seed Data

```text
ai.models    → one placeholder row per known provider (e.g. Anthropic, OpenAI) with status='INACTIVE'
              until an actual AI Agent is configured (KEM-052 §135 — AI is not required to launch)
```

## 13.3 Development / Test Data (never applied to production)

```text
core.projects (PRJ-001)      → one sample non-system project, category='INTERNAL'
core.environments             → DEV + STAGE rows for PRJ-001
core.assets, infrastructure.* → a small fabricated dependency graph (1 server, 1 database,
                                  1 repository) for exercising asset_dependencies and RLS end-to-end
```

---

# 14. IMPLEMENTATION MAPPING

`KEM-052 Entity → KEM-053 Table → Primary Key → Foreign Keys → Important Indexes → RLS Strategy`

```text
Project            → core.projects                  → id → owner_id                                → idx_projects_status/criticality/owner       → project-scoped + role baseline (9.3/9.4)
Asset               → core.assets                    → id → project_id, environment_id, owner_id       → idx_assets_project/type/status/environment  → project-scoped (nullable project_id → shared via asset_projects)
Server               → infrastructure.servers          → id → asset_id                                    → idx_servers_asset/status                     → inherits via asset_id → assets.project_id
Database              → infrastructure.databases        → id → asset_id, project_id, environment_id        → idx_databases_project/asset                  → project-scoped
Repository             → infrastructure.repositories     → id → asset_id, project_id                        → idx_repositories_project                     → project-scoped
Domain                  → infrastructure.domains          → id → asset_id, project_id                        → idx_domains_project/expiration                → project-scoped
Service                  → infrastructure.services         → id → asset_id, project_id, environment_id, server_id → idx_services_project/server/health        → project-scoped
Environment                → core.environments              → id → project_id                                  → idx_environments_project                     → project-scoped
Deployment                   → operations.deployments         → id → project_id, environment_id, repository_id  → idx_deployments_project/status/environment    → project-scoped, DEVOPS+ write
Automation (Workflow)         → automation.workflows           → id → project_id, owner_id                       → idx_workflows_project/status                  → project-scoped
AI Agent                       → ai.agents                      → id → project_id, model_id, owner_id, service_account_user_id → idx_agents_project/status         → project-scoped + autonomy-level gate (9.4)
AI Model                        → ai.models                      → id → (none — global)                          → UNIQUE(provider,model_name,model_version)     → global read; write = SUPER_ADMIN/ADMIN
Incident                          → operations.incidents            → id → project_id, asset_id, assigned_to        → idx_incidents_project/status/severity          → project-scoped
Change                              → operations.changes              → id → project_id, asset_id, requested_by, approved_by → idx_changes_project/status               → project-scoped, high-risk requires approver
Backup                                → operations.backups              → id → project_id, asset_id                    → idx_backups_project/status/asset               → project-scoped
Cost                                    → finance.costs                    → id → project_id, asset_id                → idx_costs_project/billing_period                → project-scoped, SECURITY/ADMIN read-heavy
Audit                                     → audit.audit_events               → id → actor_id, project_id               → idx_audit_resource/project/timestamp/actor      → append-only, all-role read scoped to project, no U/D
Dependency Graph                            → core.asset_dependencies           → id → source_asset_id, target_asset_id → idx_asset_deps_source/target                   → inherits via assets
Registry (Project/Asset/Infra/Service/AI/Automation/Repository) → the tables above collectively → — → — → — → each table is its own registry; no separate "registry" table exists
```

---

# 15. SPECIFICATION CONFLICTS & RESOLUTIONS

| # | Conflict | Sources | Resolution |
|---|---|---|---|
| 1 | Human-readable code width: `PRJ-001` (3-digit) vs `PRJ-0007` (4-digit) | KEM-002 §10 vs KEM-016 §39 | Adopt KEM-002's 3-digit minimum, zero-padded, unbounded — sequence-generated, not fixed-width (Section 5.2). |
| 2 | Soft-delete mechanism: status-enum (`ARCHIVED`) vs `deleted_at` timestamp | KEM-052 §65–66 vs KEM-016 §42 | Hybrid: `status` is authoritative, `archived_at` auto-set on archive, `deleted_at` reserved for governed hard-delete audit only (Section 5.6). |
| 3 | Role list: 9 roles (SUPER_ADMIN…SERVICE_ACCOUNT) vs 10 roles (…EXECUTIVE, FINANCE) vs 10 different roles (…TECH_LEAD, DATABASE_ADMIN, CONTENT_MANAGER, MARKETING, PROJECT_OWNER) | KEM-052 §45 vs KEM-003 §19 vs KEM-020 §22 | KEM-052's 9-role list is authoritative for schema/RLS. Non-adopted roles remain available as custom roles (`is_system=false`) without a migration (Section 9.4). |
| 4 | Database naming pattern `kemetrise_<project>_<environment>` specified for *project* databases | KEM-016 §23 | Out of scope for this document — KEM-053 governs the **Control Tower's own** database only, not individual project databases (consistent with KEM-052 §3/§4.2: project databases are owned by projects, only referenced via `infrastructure.databases`). No conflict in practice, but flagged so a future project-database-provisioning spec doesn't silently assume KEM-053 covers it. |
| 5 | `organizations` / `project_organization` tables exist as first-class entities | KEM-002 §29–30 | Not adopted at MVP. KEM-052 has no organization entity, only `owner_type ENUM('USER','TEAM','ORGANIZATION')` on `core.projects` (§14) and explicitly defers multi-tenancy (§53). `core.projects.owner_type='ORGANIZATION'` is schema-ready but no `organizations` table is created yet — logged as **NOT YET SPECIFIED**, Section 16. |
| 6 | Schema-per-domain (`core.`, `identity.`, …) vs everything in `public` | KEM-052 §8 (recommends schemas, allows public for MVP simplicity) | **RESOLVED (2026-09-03):** schema-per-domain locked as final. See Section 4. |
| 7 | Table ID registry (`TBL-0001`) for every production table | KEM-016 §31 | Not adopted — adds bookkeeping overhead with no consuming feature defined anywhere in KEM-051/052. Logged as intentionally dropped, not silently ignored. |
| 8 | Full temporal/history tables per entity vs single `audit.audit_events` with JSONB diff | KEM-009 §87 implies richer per-domain audit logging; KEM-052 §42 specifies one `audit.events` table | KEM-052's single-table model adopted for MVP; per-table temporal history logged as a **future / NOT YET SPECIFIED** enhancement (Section 16). |

No conflict above was resolved by silent omission — each older-spec position is named here even where not adopted.

---

# 16. DATABASE IMPLEMENTATION READINESS CHECKLIST

## ✅ READY FOR MIGRATION
```text
Schema organization — schema-per-domain LOCKED (Section 4)
All enum types (Section 6.1)
core.lookup_values + seed categories (Section 6.2, 13.1)
identity.* (users, roles, permissions, role_permissions, user_roles)
core.projects (PRJ-000 reservation LOCKED), core.environments, core.assets,
        core.asset_projects, core.asset_dependencies
core.documents — Supabase Storage + metadata model LOCKED (Section 7.2)
infrastructure.* (servers, databases, repositories, domains, services, certificates)
operations.* (deployments, incidents, changes, backups, events, notifications)
automation.workflows
ai.models, ai.agents
finance.costs
audit.audit_events — 7-year retention for business/security/audit-critical category LOCKED (Section 12.8)
security.secret_references — references/metadata-only shape LOCKED (Section 7.9)
RLS policy pattern + role-to-access baseline (Section 9)
Migration ordering (Section 10)
Required seed data (Section 13.1)
```

## ⚠️ REQUIRES DECISION (Mr. Ess / MR.ESS sign-off needed before migration-writing phase)

All five originally-listed architectural items here are **LOCKED** (2026-09-03) — see the Revision Note at the top of this document and Sections 4, 7.2, 7.9, 12.8, and 5.2/7.2 respectively. The five Section 18 POTENTIALLY MISSING items are now **DEFERRED** (v1.2.0, 2026-09-03), not pending — see Section 18, items L-01, L-03, L-05, L-09, L-12. This category is **CLOSED** — no open decisions remain that block migration-writing for the READY-FOR-MIGRATION scope.

## ❓ REQUIRES CLARIFICATION (from KEM-052 or Mr. Ess directly)
```text
Whether AI_AGENT and SERVICE_ACCOUNT roles map to real Supabase Auth users (service accounts)
        or a separate non-auth.users identity path
Exact cardinality of infrastructure.servers ↔ core.assets — currently modeled 1:1 via asset_id;
        confirm no server ever needs to map to zero or multiple asset records
Whether operations.events should ever be promoted to a durable audit-grade table vs. its
        current 90-day rolling retention (Section 12.8)
```

## 🚫 NOT YET SPECIFIED (explicitly out of scope for KEM-053, needs its own future KEM document)
```text
organizations / multi-tenancy table structure — see Section 18, item L-01
        (per the reconciliation rule, this is classified POTENTIALLY MISSING, not superseded)
Per-project business databases (schema, provisioning, isolation) — KEM-053 governs only the
        Control Tower's own database, not the databases individual KemetRise projects will run
Full temporal/history tables per entity (Conflict #8)
n8n workflow definition storage/versioning beyond the n8n_reference pointer (KEM-052 §29)
Supabase project-level configuration (compute tier, connection pooling, PITR settings)
Actual SQL migration files (explicitly deferred per this phase's directive, Section 11 rule)
```

---

# 17. RECONCILIATION RULE

Per explicit directive, the absence of an entity, field, relationship, or rule from KEM-052 is **never** treated as automatic supersession of an equivalent item in an older KEM specification (KEM-000 through KEM-050). Every material legacy requirement found while producing this document is tracked in Section 18 below with one of the following classifications:

```text
RETAINED               → the legacy requirement is already present in KEM-053, unchanged in substance
SUPERSEDED              → KEM-052/053 deliberately and explicitly replaces the legacy requirement
                           with a documented, reasoned alternative
MERGED                    → the legacy requirement's intent survives, folded into a broader
                             KEM-053 mechanism, with some structural detail simplified away
INTENTIONALLY EXCLUDED     → considered and consciously left out of MVP scope, with a stated reason
POTENTIALLY MISSING          → KEM-052 is silent on it, no KEM-053 equivalent exists, and it is
                                 NOT yet decided whether this is acceptable — flagged for Mr. Ess
REQUIRES FUTURE DECISION       → the requirement is real but the right home for it (KEM-053 now,
                                   or a later KEM-054+/other document) has not been chosen yet
```

Nothing in this list is discarded silently. Items not yet resolved remain open until Mr. Ess or a future KEM document closes them explicitly.

---

# 18. LEGACY REQUIREMENTS REQUIRING FUTURE RECONCILIATION

| # | Source KEM | Legacy Requirement | Current KEM-052 Status | Classification | Decision | Rationale | Affects DB Design? |
|---|---|---|---|---|---|---|---|
| L-01 | KEM-002 §29–30 | `organizations` / `project_organization` tables as first-class multi-tenant entities | Silent — only `owner_type ENUM('USER','TEAM','ORGANIZATION')` exists on `core.projects`, and §53 explicitly defers multi-tenancy | **POTENTIALLY MISSING** | **DEFERRED (2026-09-03).** Not part of the approved MVP database scope. Requires a future, explicit multi-tenancy decision before an `organizations` table is created. `owner_type='ORGANIZATION'` remains schema-ready but unbacked until that decision is made. | KEM-052 defers multi-tenancy on purpose, but a *project* can already claim `owner_type='ORGANIZATION'` with nothing to reference — that's an inconsistency, not a clean deferral. | **YES** — if approved, requires a new `identity.organizations` table + FK from `core.projects.owner_id` when `owner_type='ORGANIZATION'`. |
| L-02 | KEM-002 §28 | `project_members` — explicit team-membership table (distinct from role assignment) | Silent — KEM-052/053 only has `identity.user_roles.scope_project_id` for project-scoped access | **MERGED** | Project membership is expressed today via a project-scoped row in `identity.user_roles` rather than a separate membership table. | A user with any role scoped to a project is, in effect, a project member — a dedicated membership table would duplicate this without adding information at MVP scale. | NO — current model already covers the access-control need; a separate table would only matter if "member but no role yet" becomes a real state. |
| L-03 | KEM-002 §58–59 | `alerts` table + `alert_severity` — a first-class alert entity distinct from incidents | KEM-052 only discusses notification channels (§79–80) and health status fields; no `alerts` table | **POTENTIALLY MISSING** | **DEFERRED (2026-09-03).** Not part of the approved MVP database scope. The current `operations.events` + `operations.notifications` model is sufficient for the MVP; a dedicated `alerts` table is not created at this stage. | Losing a dedicated alert entity risks conflating "signal that something might be wrong" with "confirmed incident," which were deliberately distinct in KEM-002. | **YES** — if approved later, requires an `operations.alerts` table sitting between raw `operations.events` and formal `operations.incidents`. |
| L-04 | KEM-002 §50–51 | `tools` table + `ai_agent_tools` — registry of tools an AI agent is permitted to invoke | Silent — KEM-052 defines `ai_autonomy_level` but not a tool-permission registry | **REQUIRES FUTURE DECISION** | Not adopted in KEM-053 v1.1.0. | This is a real governance gap for any AI agent above `L1_RECOMMEND` — autonomy level alone doesn't say *which* tools/actions are permitted. | **YES** — likely needed before any `L2+` AI agent goes live; natural fit for a `KEM-054`-scope addition once AI agents move past design. |
| L-05 | KEM-002 §54 | `workflow_executions` — per-run execution history for automation workflows | Silent — `automation.workflows` stores only the workflow definition/reference, not run history | **POTENTIALLY MISSING** | **DEFERRED (2026-09-03).** Not part of the approved MVP database scope. n8n remains the initial source of execution history for the MVP; the Control Tower database does not duplicate it yet. | Operational visibility into automation reliability (KEM-052 §124-adjacent monitoring intent) is weaker without a queryable execution-history table inside the Control Tower's own database. | **YES** — if approved later, requires `automation.workflow_executions` (workflow_id, status, started_at, completed_at, error). |
| L-06 | KEM-002 §61 | `incident_events` — sub-timeline of discrete events within a single incident | KEM-052 treats an incident as one row with `root_cause`/`resolution` text fields | **MERGED** | Incident timeline detail is currently expected to live in `audit.audit_events` (`resource_type='incident'`) rather than a dedicated sub-table. | Functionally similar, but audit events are not purpose-built for a human-readable incident timeline (no "message"/actor-facing narrative field). | Possibly — acceptable at MVP; revisit if incident response tooling needs a purpose-built timeline view. |
| L-07 | KEM-002 §63 | `document_versions` — full version history per document | KEM-052/053 `core.documents` has a single `version` text field, no history table | **INTENTIONALLY EXCLUDED** | Excluded from MVP scope. Supabase Storage itself may retain object versioning at the bucket level, which can substitute at MVP. | Adding a full version-history table before any document workflow exists would be premature structure with no consuming feature yet. | NO at MVP — revisit if formal document approval/versioning workflows are built. |
| L-08 | KEM-002 §64 (and KEM-047 wave) | `project_knowledge` — structured knowledge-base entity per project | Silent in KEM-052 | **REQUIRES FUTURE DECISION** | Not adopted in KEM-053 v1.1.0. | This spans both a data-model question (KEM-053) and a product-feature question (a whole KEM-047-scope wave) — too broad to resolve inside a database-only document. | Possibly — depends on whether "project knowledge" ends up structured (own table) or unstructured (a `core.documents` classification). |
| L-09 | KEM-002 §65–66 | `integrations` + `integration_synchronization` — registry of third-party integrations distinct from internal automation workflows | Silent — `automation.workflows` only covers n8n-style internal automations | **POTENTIALLY MISSING** | **DEFERRED (2026-09-03).** Not part of the approved MVP database scope. Requires a dedicated integration architecture before a table is created. | A registered third-party integration (e.g. a payment provider, an email service) is conceptually different from an internal workflow and currently has no home at all — not even as an asset. | **YES** — if approved later, either a new `infrastructure.integrations` table or an extension of `core.assets.asset_type`. |
| L-10 | KEM-002 §72–73 | `project_tags` + `tag_relationships` — free-form tagging system across entities | Silent in KEM-052 | **INTENTIONALLY EXCLUDED** | Excluded from MVP scope. `core.lookup_values` covers closed/governed categorization; open free-form tagging is a UX-layer nicety, not a governance necessity. | Tags add cross-cutting query flexibility but no structural capability the MVP entity model lacks. | NO at MVP — a generic `taggable_type`/`taggable_id` polymorphic table can be added later without disrupting existing tables. |
| L-11 | KEM-002 §75–76 | `financial_transactions` + explicit `financial_security` rules (richer than a flat cost record) | KEM-052/053 has only `finance.costs`, a single flat cost-record table | **MERGED** | Detail is intentionally simplified — `finance.costs` captures amount/type/period but not transaction-level ledger detail (debits/credits, transaction status, reconciliation state). | KEM-002's finance domain reads as ledger-grade; KEM-052's is dashboard-grade. The gap is real if KemetRise ever needs actual bookkeeping rather than cost visibility. | **YES** — if real financial ledger behavior is needed, `finance.costs` is not sufficient and a proper transactions table is required. |
| L-12 | KEM-002 §77–78 | `system_settings` + `feature_flags` — runtime-configurable system behavior stored in the database | Silent in KEM-052 | **POTENTIALLY MISSING** | **DEFERRED (2026-09-03).** Not part of the approved MVP database scope. To be introduced when configuration/feature-management architecture is defined. | Every KEM-052 table assumes fixed behavior; there is currently no governed place to toggle a feature or store a runtime setting without a migration. | **YES** — if approved later, a small `core.system_settings` (key/value) and/or `core.feature_flags` table would be low-cost to add. |
| L-13 | KEM-002 §71 | `api_request_log` — access-log-style table distinct from `audit.audit_events` | Silent — KEM-052/053 unifies everything into `audit.audit_events` | **INTENTIONALLY EXCLUDED** | Excluded from the database layer. High-volume request logging is expected to live in infrastructure-level logging (reverse proxy / API gateway / Supabase logs), not in application tables. | Putting raw request logs in PostgreSQL at scale is a performance anti-pattern; this is a deliberate architectural choice, not an oversight. | NO — explicitly kept out of this database by design. |
| L-14 | KEM-016 §31 | `TBL-####` — a table-identifier registry, assigning a human code to every production table itself (meta-level, not row-level) | Silent in KEM-052 | **INTENTIONALLY EXCLUDED** | Already logged as Conflict #7 (Section 15) — carried forward here for completeness. No consuming feature has been defined anywhere in KEM-051/052 that would read this registry. | Adds bookkeeping overhead with zero identified downstream use. | NO. |
| L-15 | KEM-016 §44 (and referenced elsewhere in the governance waves) | Formal **data classification** labels (`PUBLIC / INTERNAL / CONFIDENTIAL / RESTRICTED / CRITICAL`) applied per record or per table | KEM-052 does not define a classification enum; KEM-053 v1.0.0 used an ad-hoc `classification` text default on `core.documents` only | **REQUIRES FUTURE DECISION** | Partially addressed — `core.documents.classification` exists (Section 7.2) but the same concept is not applied consistently to `core.assets`, `infrastructure.databases`, or other sensitive tables. | Data classification is a real governance requirement referenced across multiple legacy waves (KEM-016, KEM-031/KEM-015 security waves), and applying it to one table only is inconsistent. | **YES** — likely needs a shared `data_classification` enum applied across every table holding sensitive metadata, not just documents. |

**Summary:** 15 legacy items reviewed. 0 silently discarded. 2 RETAINED-equivalent/MERGED-without-loss, 3 MERGED-with-simplification, 4 INTENTIONALLY EXCLUDED (each with a stated reason), 5 POTENTIALLY MISSING — all 5 now formally **DEFERRED** (v1.2.0, 2026-09-03) rather than adopted or deleted, 3 REQUIRES FUTURE DECISION (L-08 and L-15 span two categories and are counted under their primary classification above). None of the 15 change any item in the READY FOR MIGRATION list (Section 16) — they are additive, not corrective.

---

# 19. END OF SPECIFICATION

**KemetRise — Legacy Nexus**

**MR.ESS Project Operating System**

**SUPABASE DATABASE IMPLEMENTATION SPECIFICATION**

**Version:** 1.2.0

**STATUS:** APPROVED — AUTHORITATIVE DATABASE IMPLEMENTATION SPECIFICATION (for currently defined implementation scope)

No production code, frontend code, backend code, Supabase migrations, or n8n workflows were created in producing this document. No existing KEM file (KEM-000 through KEM-052) was modified, deleted, or renamed. Only KEM-053 itself was updated, as authorized.
