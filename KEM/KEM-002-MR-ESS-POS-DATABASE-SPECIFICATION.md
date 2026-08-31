# KEM-002-MR-ESS-POS-DATABASE-SPECIFICATION.md

# KemetRise — Legacy Nexus

## MR.ESS Project Operating System

### CONTROL TOWER DATABASE SPECIFICATION

**Document ID:** KEM-002
**System ID:** MR-ESS-POS
**Parent Specification:** KEM-000
**Architecture Specification:** KEM-001
**Organization:** KemetRise — Legacy Nexus
**Owner:** MR.ESS
**Version:** 1.0.0
**Status:** FOUNDATION
**Classification:** INTERNAL — KEMETRISE
**Date:** 2026-08-31

---

# 1. PURPOSE

This specification defines the database architecture of the:

**KemetRise — Legacy Nexus / MR.ESS Project Operating System**

The database defined here is the **Control Tower Database**.

Its primary responsibility is to maintain the central registry and operational intelligence of all KemetRise projects.

It does NOT automatically replace the operational databases belonging to individual projects.

---

# 2. CORE PRINCIPLE

The Control Tower Database answers:

> **What exists?**

> **Where does it exist?**

> **Who owns it?**

> **Which project does it belong to?**

> **What is its current state?**

> **How is it connected?**

> **Who changed it?**

> **What happened?**

It is therefore a:

# SYSTEM OF RECORD FOR CONTROL-TOWER METADATA

---

# 3. DATABASE PHILOSOPHY

The database must be:

* Relational
* Strongly structured
* Extensible
* Auditable
* Project-aware
* Security-aware
* Integration-ready
* AI-ready
* Automation-ready
* Migration-friendly
* Non-destructive

---

# 4. RECOMMENDED DATABASE ENGINE

Primary database:

# PostgreSQL

Recommended baseline:

```text
PostgreSQL 16+
```

The architecture must remain portable enough to avoid unnecessary vendor lock-in.

---

# 5. DATABASE IDENTIFICATION

The Control Tower database receives:

```text
Database ID:
DB-MR-ESS-POS

Database Type:
CONTROL_TOWER

System:
SYS-MR-ESS-POS

Owner:
KemetRise — Legacy Nexus
```

---

# 6. DATABASE LOGICAL DOMAINS

The database is divided conceptually into:

```text
01. Identity
02. Organizations
03. Projects
04. Infrastructure
05. Applications
06. Domains
07. Repositories
08. Environments
09. Deployments
10. AI
11. Automation
12. Monitoring
13. Alerts
14. Incidents
15. Documentation
16. Finance
17. Integrations
18. Notifications
19. Audit
20. System Configuration
```

---

# 7. GLOBAL ID PRINCIPLE

Every major entity must have an immutable internal ID.

Recommended format:

```text
UUID
```

Human-readable identifiers may additionally exist.

Example:

```text
id:
550e8400-e29b-41d4-a716-446655440000

code:
PRJ-001
```

The UUID is the immutable primary identity.

The human-readable code is an operational identifier.

---

# 8. COMMON ENTITY FIELDS

Major entities should generally contain:

```text
id
code
name
description
status
created_at
updated_at
created_by
updated_by
```

Project-scoped entities should additionally contain:

```text
project_id
```

where applicable.

---

# 9. UUID POLICY

UUIDs must never be recycled.

When an entity is deleted or archived, its original UUID remains permanently associated with its historical record.

---

# 10. PROJECT CODE FORMAT

Projects use:

```text
PRJ-001
PRJ-002
PRJ-003
```

The numeric portion must be unique.

---

# 11. SERVER CODE FORMAT

Servers use:

```text
SRV-001
SRV-002
SRV-003
```

---

# 12. DATABASE CODE FORMAT

Registered databases use:

```text
DB-001
DB-002
DB-003
```

---

# 13. APPLICATION CODE FORMAT

Applications use:

```text
APP-001
APP-002
APP-003
```

---

# 14. AGENT CODE FORMAT

AI Agents use:

```text
AGT-001
AGT-002
AGT-003
```

---

# 15. WORKFLOW CODE FORMAT

Automation workflows use:

```text
WF-001
WF-002
WF-003
```

---

# 16. DEPLOYMENT CODE FORMAT

Deployments use:

```text
DEP-001
DEP-002
DEP-003
```

---

# 17. ALERT CODE FORMAT

Alerts use:

```text
ALT-001
ALT-002
ALT-003
```

---

# 18. INCIDENT CODE FORMAT

Incidents use:

```text
INC-001
INC-002
INC-003
```

---

# 19. USERS TABLE

Table:

```text
users
```

Purpose:

Stores Control Tower user identities.

Core fields:

```text
id UUID PK
email VARCHAR UNIQUE
full_name VARCHAR
display_name VARCHAR
avatar_url TEXT
status VARCHAR
last_login_at TIMESTAMPTZ
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Authentication credentials should preferably be managed by a dedicated authentication subsystem.

---

# 20. USER ROLES

Table:

```text
roles
```

Fields:

```text
id UUID PK
name VARCHAR UNIQUE
description TEXT
system_role BOOLEAN
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Examples:

```text
SUPER_ADMIN
ADMIN
EXECUTIVE
PROJECT_MANAGER
DEVELOPER
DEVOPS
FINANCE
VIEWER
AI_OPERATOR
```

---

# 21. PERMISSIONS TABLE

Table:

```text
permissions
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
name VARCHAR
description TEXT
resource VARCHAR
action VARCHAR
created_at TIMESTAMPTZ
```

Example:

```text
project.read
project.create
project.update
project.archive

server.read
server.restart

deployment.create
deployment.approve

database.read
database.backup

agent.execute
workflow.execute
```

---

# 22. USER ROLE ASSIGNMENT

Table:

```text
user_roles
```

Fields:

```text
id UUID PK
user_id UUID FK
role_id UUID FK
scope_type VARCHAR
scope_id UUID NULL
created_at TIMESTAMPTZ
created_by UUID
```

Scope may be:

```text
GLOBAL
PROJECT
ENVIRONMENT
```

---

# 23. ROLE PERMISSIONS

Table:

```text
role_permissions
```

Fields:

```text
id UUID PK
role_id UUID FK
permission_id UUID FK
created_at TIMESTAMPTZ
```

---

# 24. PROJECTS TABLE

Table:

```text
projects
```

This is the central entity of the ecosystem.

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
name VARCHAR
slug VARCHAR UNIQUE
description TEXT
project_type VARCHAR
status VARCHAR
priority VARCHAR
owner_user_id UUID FK
start_date DATE
target_date DATE
repository_url TEXT
production_url TEXT
documentation_url TEXT
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
created_by UUID
updated_by UUID
archived_at TIMESTAMPTZ NULL
```

---

# 25. PROJECT TYPES

Examples:

```text
INTERNAL
CLIENT
PRODUCT
SAAS
EXPERIMENT
INFRASTRUCTURE
AI
AUTOMATION
DIGITAL_MALL
EDUCATION
HEALTHCARE
REAL_ESTATE
MEDIA
OTHER
```

---

# 26. PROJECT STATUS

Recommended values:

```text
PLANNING
ACTIVE
PAUSED
MAINTENANCE
COMPLETED
ARCHIVED
CANCELLED
```

---

# 27. PROJECT METADATA

Flexible project-specific data may exist in:

```text
metadata JSONB
```

However, important queryable fields must receive dedicated database columns.

JSONB must not become a replacement for proper schema design.

---

# 28. PROJECT MEMBERS

Table:

```text
project_members
```

Fields:

```text
id UUID PK
project_id UUID FK
user_id UUID FK
role_id UUID FK
status VARCHAR
joined_at TIMESTAMPTZ
created_at TIMESTAMPTZ
```

---

# 29. ORGANIZATIONS

Future-ready table:

```text
organizations
```

Fields:

```text
id UUID PK
name VARCHAR
slug VARCHAR UNIQUE
type VARCHAR
status VARCHAR
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Initial system may contain:

```text
KemetRise — Legacy Nexus
```

---

# 30. PROJECT ORGANIZATION

Table:

```text
organization_projects
```

Fields:

```text
id UUID PK
organization_id UUID FK
project_id UUID FK
relationship_type VARCHAR
created_at TIMESTAMPTZ
```

---

# 31. SERVERS TABLE

Table:

```text
servers
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
name VARCHAR
provider VARCHAR
server_type VARCHAR
hostname VARCHAR
ip_address INET NULL
operating_system VARCHAR
region VARCHAR
datacenter VARCHAR
status VARCHAR
environment_id UUID FK NULL
project_id UUID FK NULL
cpu_cores INTEGER
memory_gb NUMERIC
storage_gb NUMERIC
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 32. SERVER SECURITY

Sensitive credentials must NOT be stored in:

```text
servers
```

The server record may contain:

```text
credential_reference
```

but not the actual secret.

---

# 33. SERVER-PROJECT RELATIONSHIP

A server may be:

```text
DEDICATED
SHARED
CONTROL_TOWER
CLIENT
TEMPORARY
```

If a server hosts multiple projects, the relationship should be modeled explicitly.

---

# 34. PROJECT-SERVER RELATIONSHIP

Table:

```text
project_servers
```

Fields:

```text
id UUID PK
project_id UUID FK
server_id UUID FK
relationship_type VARCHAR
environment_id UUID FK NULL
is_primary BOOLEAN
created_at TIMESTAMPTZ
```

---

# 35. DATABASE REGISTRY

Table:

```text
databases
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
name VARCHAR
database_type VARCHAR
engine VARCHAR
version VARCHAR
provider VARCHAR
host_reference TEXT
port INTEGER
database_name VARCHAR
status VARCHAR
environment_id UUID FK NULL
project_id UUID FK NULL
server_id UUID FK NULL
credential_reference TEXT NULL
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 36. DATABASE TYPES

Examples:

```text
POSTGRESQL
MYSQL
MONGODB
SQLITE
REDIS
SUPABASE
OTHER
```

---

# 37. DATABASE CONNECTION SECURITY

The following must NEVER be stored as plaintext:

```text
password
private key
API secret
access token
service role key
```

Use:

```text
credential_reference
```

to reference external secret storage.

---

# 38. DATABASE RELATIONSHIP GRAPH

A database may be hosted by:

```text
Server
Cloud Provider
Managed Service
```

The architecture must support all three.

---

# 39. APPLICATIONS TABLE

Table:

```text
applications
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK
name VARCHAR
application_type VARCHAR
repository_id UUID FK NULL
status VARCHAR
technology_stack JSONB
description TEXT
production_url TEXT
staging_url TEXT
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 40. APPLICATION TYPES

Examples:

```text
WEB
API
MOBILE
DESKTOP
SERVICE
WORKER
AI
AUTOMATION
CLI
OTHER
```

---

# 41. ENVIRONMENTS TABLE

Table:

```text
environments
```

Fields:

```text
id UUID PK
project_id UUID FK
name VARCHAR
environment_type VARCHAR
status VARCHAR
description TEXT
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

Standard:

```text
DEVELOPMENT
STAGING
PRODUCTION
```

---

# 42. APPLICATION ENVIRONMENTS

Table:

```text
application_environments
```

Fields:

```text
id UUID PK
application_id UUID FK
environment_id UUID FK
deployment_target_id UUID NULL
url TEXT
status VARCHAR
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 43. DOMAINS TABLE

Table:

```text
domains
```

Fields:

```text
id UUID PK
project_id UUID FK
domain VARCHAR
provider VARCHAR
status VARCHAR
ssl_status VARCHAR
expires_at TIMESTAMPTZ NULL
auto_renew BOOLEAN
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 44. REPOSITORIES TABLE

Table:

```text
repositories
```

Fields:

```text
id UUID PK
project_id UUID FK
provider VARCHAR
external_id VARCHAR
name VARCHAR
full_name VARCHAR
url TEXT
default_branch VARCHAR
visibility VARCHAR
status VARCHAR
last_commit_hash VARCHAR
last_sync_at TIMESTAMPTZ
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 45. REPOSITORY PROVIDERS

Examples:

```text
GITHUB
GITLAB
BITBUCKET
SELF_HOSTED_GIT
OTHER
```

---

# 46. DEPLOYMENTS TABLE

Table:

```text
deployments
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK
application_id UUID FK
environment_id UUID FK
repository_id UUID FK NULL
commit_hash VARCHAR NULL
version VARCHAR NULL
status VARCHAR
triggered_by UUID FK NULL
started_at TIMESTAMPTZ
completed_at TIMESTAMPTZ NULL
deployment_log_reference TEXT
rollback_available BOOLEAN
metadata JSONB
created_at TIMESTAMPTZ
```

---

# 47. DEPLOYMENT STATUS

```text
QUEUED
RUNNING
SUCCESS
FAILED
CANCELLED
ROLLED_BACK
```

---

# 48. AI AGENTS TABLE

Table:

```text
ai_agents
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK NULL
name VARCHAR
description TEXT
role VARCHAR
status VARCHAR
model_id UUID FK
system_prompt_reference TEXT
memory_strategy VARCHAR
autonomy_level VARCHAR
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 49. AI MODELS TABLE

Table:

```text
ai_models
```

Fields:

```text
id UUID PK
provider VARCHAR
model_name VARCHAR
model_version VARCHAR NULL
context_window INTEGER NULL
capabilities JSONB
pricing JSONB
status VARCHAR
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 50. AI AGENT TOOLS

Table:

```text
ai_agent_tools
```

Fields:

```text
id UUID PK
agent_id UUID FK
tool_id UUID FK
enabled BOOLEAN
created_at TIMESTAMPTZ
```

---

# 51. TOOLS TABLE

Table:

```text
tools
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
name VARCHAR
description TEXT
tool_type VARCHAR
risk_level VARCHAR
permission_required VARCHAR
execution_provider VARCHAR
status VARCHAR
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 52. AI AUTONOMY LEVEL

Recommended levels:

```text
L0 = OBSERVE
L1 = RECOMMEND
L2 = ASSIST
L3 = EXECUTE_LOW_RISK
L4 = EXECUTE_WITH_APPROVAL
L5 = CONTROLLED_AUTONOMY
```

---

# 53. AUTOMATION WORKFLOWS

Table:

```text
workflows
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK NULL
name VARCHAR
provider VARCHAR
external_id VARCHAR
description TEXT
trigger_type VARCHAR
status VARCHAR
last_execution_at TIMESTAMPTZ NULL
last_execution_status VARCHAR NULL
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 54. WORKFLOW EXECUTIONS

Table:

```text
workflow_executions
```

Fields:

```text
id UUID PK
workflow_id UUID FK
project_id UUID FK NULL
external_execution_id VARCHAR
status VARCHAR
started_at TIMESTAMPTZ
completed_at TIMESTAMPTZ NULL
duration_ms BIGINT NULL
error_message TEXT NULL
metadata JSONB
```

---

# 55. AUTOMATION TRIGGERS

Table:

```text
automation_triggers
```

Fields:

```text
id UUID PK
workflow_id UUID FK
trigger_type VARCHAR
event_type VARCHAR NULL
schedule_expression TEXT NULL
enabled BOOLEAN
configuration JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 56. MONITORED RESOURCES

Table:

```text
monitored_resources
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
resource_type VARCHAR
resource_id UUID
monitor_type VARCHAR
status VARCHAR
health_score NUMERIC
last_checked_at TIMESTAMPTZ
response_time_ms INTEGER NULL
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 57. HEALTH CHECKS

Table:

```text
health_checks
```

Fields:

```text
id UUID PK
monitored_resource_id UUID FK
status VARCHAR
response_time_ms INTEGER NULL
error_code VARCHAR NULL
error_message TEXT NULL
checked_at TIMESTAMPTZ
metadata JSONB
```

---

# 58. ALERTS TABLE

Table:

```text
alerts
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK NULL
resource_type VARCHAR NULL
resource_id UUID NULL
severity VARCHAR
status VARCHAR
title VARCHAR
message TEXT
trigger_source VARCHAR
triggered_at TIMESTAMPTZ
acknowledged_at TIMESTAMPTZ NULL
resolved_at TIMESTAMPTZ NULL
acknowledged_by UUID FK NULL
resolved_by UUID FK NULL
metadata JSONB
```

---

# 59. ALERT SEVERITY

```text
INFO
LOW
MEDIUM
HIGH
CRITICAL
```

---

# 60. INCIDENTS TABLE

Table:

```text
incidents
```

Fields:

```text
id UUID PK
code VARCHAR UNIQUE
project_id UUID FK NULL
title VARCHAR
description TEXT
severity VARCHAR
status VARCHAR
detected_at TIMESTAMPTZ
started_at TIMESTAMPTZ NULL
resolved_at TIMESTAMPTZ NULL
owner_user_id UUID FK NULL
root_cause TEXT NULL
resolution TEXT NULL
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 61. INCIDENT EVENTS

Table:

```text
incident_events
```

Fields:

```text
id UUID PK
incident_id UUID FK
event_type VARCHAR
message TEXT
actor_type VARCHAR
actor_id UUID NULL
created_at TIMESTAMPTZ
metadata JSONB
```

---

# 62. DOCUMENTS TABLE

Table:

```text
documents
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
name VARCHAR
document_type VARCHAR
version VARCHAR
storage_reference TEXT
mime_type VARCHAR
file_size BIGINT
checksum VARCHAR
status VARCHAR
owner_user_id UUID FK NULL
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 63. DOCUMENT VERSIONS

Table:

```text
document_versions
```

Fields:

```text
id UUID PK
document_id UUID FK
version VARCHAR
storage_reference TEXT
checksum VARCHAR
created_by UUID FK
created_at TIMESTAMPTZ
```

Documents must be versionable.

---

# 64. PROJECT KNOWLEDGE

Table:

```text
knowledge_items
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
title VARCHAR
content TEXT
content_type VARCHAR
source_type VARCHAR
source_reference TEXT
status VARCHAR
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

This may later support AI retrieval.

---

# 65. INTEGRATIONS

Table:

```text
integrations
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
provider VARCHAR
integration_type VARCHAR
name VARCHAR
status VARCHAR
credential_reference TEXT NULL
configuration JSONB
last_sync_at TIMESTAMPTZ NULL
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 66. INTEGRATION SYNCHRONIZATION

Table:

```text
integration_syncs
```

Fields:

```text
id UUID PK
integration_id UUID FK
sync_type VARCHAR
status VARCHAR
started_at TIMESTAMPTZ
completed_at TIMESTAMPTZ NULL
records_processed INTEGER
records_created INTEGER
records_updated INTEGER
records_failed INTEGER
error_message TEXT NULL
metadata JSONB
```

---

# 67. NOTIFICATIONS

Table:

```text
notifications
```

Fields:

```text
id UUID PK
user_id UUID FK
project_id UUID FK NULL
notification_type VARCHAR
channel VARCHAR
title VARCHAR
message TEXT
status VARCHAR
sent_at TIMESTAMPTZ NULL
read_at TIMESTAMPTZ NULL
metadata JSONB
created_at TIMESTAMPTZ
```

---

# 68. AUDIT LOG

Table:

```text
audit_logs
```

Fields:

```text
id UUID PK
actor_type VARCHAR
actor_id UUID NULL
action VARCHAR
entity_type VARCHAR
entity_id UUID NULL
project_id UUID NULL
request_id VARCHAR NULL
before_state JSONB NULL
after_state JSONB NULL
ip_address INET NULL
user_agent TEXT NULL
created_at TIMESTAMPTZ
```

---

# 69. AUDIT PRINCIPLE

Critical operations must create audit records.

Examples:

```text
PROJECT_CREATED
PROJECT_UPDATED
PROJECT_ARCHIVED

SERVER_ADDED
SERVER_UPDATED

DATABASE_REGISTERED

DEPLOYMENT_STARTED
DEPLOYMENT_APPROVED
DEPLOYMENT_COMPLETED

AGENT_EXECUTED

WORKFLOW_EXECUTED

PERMISSION_CHANGED

CREDENTIAL_REFERENCE_CHANGED
```

---

# 70. SYSTEM EVENTS

Table:

```text
system_events
```

Fields:

```text
id UUID PK
event_type VARCHAR
project_id UUID NULL
entity_type VARCHAR NULL
entity_id UUID NULL
source VARCHAR
payload JSONB
occurred_at TIMESTAMPTZ
processed_at TIMESTAMPTZ NULL
status VARCHAR
```

---

# 71. API REQUEST LOG

Table:

```text
api_requests
```

Fields:

```text
id UUID PK
request_id VARCHAR UNIQUE
user_id UUID NULL
method VARCHAR
path TEXT
status_code INTEGER
duration_ms INTEGER
ip_address INET NULL
created_at TIMESTAMPTZ
metadata JSONB
```

Sensitive request payloads must not be stored indiscriminately.

---

# 72. PROJECT TAGS

Table:

```text
tags
```

Fields:

```text
id UUID PK
name VARCHAR UNIQUE
color VARCHAR NULL
created_at TIMESTAMPTZ
```

---

# 73. TAG RELATIONSHIPS

Table:

```text
entity_tags
```

Fields:

```text
id UUID PK
tag_id UUID FK
entity_type VARCHAR
entity_id UUID
created_at TIMESTAMPTZ
```

---

# 74. FINANCE DOMAIN

The initial Control Tower may maintain high-level financial metadata.

Table:

```text
financial_accounts
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
name VARCHAR
account_type VARCHAR
currency CHAR(3)
status VARCHAR
metadata JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 75. FINANCIAL TRANSACTIONS

Table:

```text
financial_transactions
```

Fields:

```text
id UUID PK
project_id UUID FK NULL
account_id UUID FK
transaction_type VARCHAR
amount NUMERIC(18,2)
currency CHAR(3)
description TEXT
transaction_date DATE
status VARCHAR
reference VARCHAR NULL
metadata JSONB
created_at TIMESTAMPTZ
```

---

# 76. FINANCIAL SECURITY

Financial records require elevated permissions.

Sensitive financial data must never be exposed to unauthorized AI agents.

---

# 77. SYSTEM SETTINGS

Table:

```text
system_settings
```

Fields:

```text
id UUID PK
key VARCHAR UNIQUE
value JSONB
category VARCHAR
is_sensitive BOOLEAN
updated_by UUID FK
updated_at TIMESTAMPTZ
```

Sensitive settings must reference external secrets where appropriate.

---

# 78. FEATURE FLAGS

Table:

```text
feature_flags
```

Fields:

```text
id UUID PK
key VARCHAR UNIQUE
enabled BOOLEAN
environment VARCHAR
project_id UUID NULL
configuration JSONB
created_at TIMESTAMPTZ
updated_at TIMESTAMPTZ
```

---

# 79. DATABASE CONSTRAINTS

All major foreign keys must enforce referential integrity.

Examples:

```text
project_members.project_id
→ projects.id

applications.project_id
→ projects.id

repositories.project_id
→ projects.id

deployments.application_id
→ applications.id

deployments.environment_id
→ environments.id

ai_agents.model_id
→ ai_models.id
```

---

# 80. CASCADE POLICY

Blind cascading deletes are prohibited for critical entities.

Prefer:

```text
RESTRICT
```

or controlled soft deletion.

This prevents accidental destruction of historical data.

---

# 81. SOFT DELETE

Entities that require historical retention should use:

```text
deleted_at
deleted_by
```

rather than immediate physical deletion.

---

# 82. STATUS VALUES

Status fields should use controlled values.

Possible implementation:

```text
CHECK constraints
```

or lookup tables.

Arbitrary status strings must not proliferate.

---

# 83. TIMESTAMPS

All timestamps should use:

```text
TIMESTAMPTZ
```

and be stored in UTC.

The UI may convert timestamps to the user's local timezone.

---

# 84. MONEY

Financial amounts should use:

```text
NUMERIC
```

Never use floating-point types for monetary values.

---

# 85. CURRENCY

Currencies should use:

```text
ISO 4217
```

Example:

```text
USD
EUR
EGP
JOD
```

---

# 86. INDEXING STRATEGY

Indexes should exist on:

```text
project_id
status
created_at
updated_at
external_id
code
```

where query patterns justify them.

---

# 87. COMPOSITE INDEXES

Project-scoped queries should use composite indexes where appropriate.

Example:

```text
(project_id, status)

(project_id, created_at)

(project_id, environment_id)
```

---

# 88. UNIQUE CONSTRAINTS

Examples:

```text
projects.code
projects.slug
repositories(provider, external_id)
```

must be unique where logically required.

---

# 89. JSONB POLICY

JSONB is allowed for:

* Provider-specific metadata
* Flexible configuration
* AI model capabilities
* Integration configuration
* External API metadata

JSONB must not be used to avoid defining a stable relational field.

---

# 90. ROW LEVEL SECURITY

Where PostgreSQL RLS is used, project-scoped records should be protected using project context.

Conceptually:

```text
CURRENT USER
     ↓
AUTHORIZED PROJECTS
     ↓
PROJECT-SCOPED DATA
```

---

# 91. GLOBAL DATA

Certain tables may contain global records:

```text
users
roles
permissions
ai_models
tools
system_settings
```

These require separate authorization rules.

---

# 92. PROJECT DATA

Examples:

```text
applications
servers relationships
databases relationships
domains
repositories
workflows
agents
documents
incidents
```

should be project-aware where applicable.

---

# 93. CONTROL TOWER PROJECT

The Control Tower itself should have a project/system representation:

```text
Project Code:
PRJ-MR-ESS-POS
```

This permits self-monitoring and self-documentation.

---

# 94. RELATIONSHIP MODEL

Core relationship:

```text
PROJECT
 │
 ├── ENVIRONMENTS
 │
 ├── APPLICATIONS
 │      └── DEPLOYMENTS
 │
 ├── SERVERS
 │
 ├── DATABASES
 │
 ├── DOMAINS
 │
 ├── REPOSITORIES
 │
 ├── WORKFLOWS
 │
 ├── AI AGENTS
 │
 ├── DOCUMENTS
 │
 ├── ALERTS
 │
 └── INCIDENTS
```

---

# 95. INFRASTRUCTURE GRAPH

The database must support relationships such as:

```text
Project
 ↓
Application
 ↓
Environment
 ↓
Server
 ↓
Database
```

and:

```text
Project
 ↓
Repository
 ↓
Deployment
 ↓
Application
 ↓
Server
```

---

# 96. AI GRAPH

The AI model:

```text
Project
 ↓
Agent
 ↓
Model
 ↓
Tools
 ↓
Permissions
 ↓
Execution
 ↓
Audit
```

must be traceable.

---

# 97. AUTOMATION GRAPH

Automation:

```text
Project
 ↓
Workflow
 ↓
Trigger
 ↓
Execution
 ↓
Result
 ↓
Event
```

must be traceable.

---

# 98. INCIDENT GRAPH

Incident:

```text
Resource
 ↓
Health Check
 ↓
Alert
 ↓
Incident
 ↓
Actions
 ↓
Resolution
```

must be traceable.

---

# 99. DATABASE MIGRATIONS

All schema changes must use version-controlled migrations.

Example:

```text
001_initial_schema
002_projects
003_infrastructure
004_ai
005_automation
006_monitoring
```

Migrations must be immutable after deployment.

---

# 100. MIGRATION RULE

Never manually alter production schema without recording the change through the migration system.

Emergency changes must be backfilled into the migration history.

---

# 101. SEED DATA

Seed data may include:

```text
Default roles
Default permissions
System project
Initial system settings
Default environments
Core AI models
Core tool definitions
```

Seed scripts must be idempotent.

---

# 102. BACKUP

The Control Tower database requires:

* Automated backups
* Backup verification
* Restore testing
* Retention policy
* Off-site copy where appropriate

---

# 103. DATABASE MONITORING

Monitor:

```text
CPU
Memory
Connections
Storage
Query latency
Locks
Deadlocks
Replication where applicable
Backup status
Failed queries
```

---

# 104. DATABASE PERFORMANCE

Queries must be reviewed for:

* Index utilization
* Query planning
* Sequential scans
* N+1 access
* Unbounded results
* Lock contention

---

# 105. PAGINATION

Large datasets must use pagination.

Preferred approaches:

```text
Cursor-based pagination
```

where appropriate.

Offset pagination may be used for small datasets.

---

# 106. DATA VALIDATION

Validation must occur at multiple levels:

```text
Frontend
API
Application
Database
```

The database remains the final integrity boundary.

---

# 107. IMMUTABLE RECORDS

Certain records should be append-only or effectively immutable:

```text
audit_logs
system_events
financial_transactions
workflow_executions
health_checks
```

Corrections should create new records rather than silently rewriting history.

---

# 108. AUDIT RETENTION

Audit retention must be longer than ordinary application logs where operationally and legally appropriate.

---

# 109. SECURITY PRINCIPLE

Database access follows:

```text
IDENTITY
 ↓
AUTHORIZATION
 ↓
PROJECT SCOPE
 ↓
RESOURCE SCOPE
 ↓
ACTION
```

No application component should receive unrestricted database access unnecessarily.

---

# 110. APPLICATION DATABASE ACCESS

The application should use dedicated database access roles.

Conceptually:

```text
READ_ONLY
APPLICATION
MIGRATION
ADMIN
```

Production application credentials should not have unnecessary schema-management privileges.

---

# 111. AI DATABASE ACCESS

AI agents must never receive unrestricted SQL access by default.

Preferred model:

```text
AI
 ↓
Approved Tool
 ↓
Validated Query / Operation
 ↓
Authorization
 ↓
Database
```

---

# 112. BACKUP DATABASE ACCESS

Backup systems must use dedicated credentials and minimal required permissions.

---

# 113. DATA CLASSIFICATION

Data should eventually be classified as:

```text
PUBLIC
INTERNAL
CONFIDENTIAL
SENSITIVE
CRITICAL
```

The classification must influence:

* Access
* Logging
* AI availability
* Export
* Retention

---

# 114. DATA OWNERSHIP

Every critical dataset should have an owner.

Possible ownership:

```text
SYSTEM
PROJECT
USER
DEPARTMENT
CLIENT
```

---

# 115. DATA LINEAGE

Future architecture should track:

```text
Source
 ↓
Transformation
 ↓
Stored Data
 ↓
AI Processing
 ↓
Output
```

This is especially important for AI-generated operational decisions.

---

# 116. AI MEMORY STORAGE

AI memory must be isolated from ordinary project data.

Possible architecture:

```text
agent_memory
agent_memory_items
agent_memory_embeddings
```

These are future extensions.

---

# 117. VECTOR SEARCH

The database may eventually support vector search.

Possible implementation:

```text
pgvector
```

Potential uses:

* Project knowledge
* Documentation retrieval
* AI memory
* Semantic search

This is optional and should not be activated without a concrete use case.

---

# 118. KNOWLEDGE SECURITY

AI retrieval must respect:

```text
User Permissions
Project Permissions
Document Permissions
Data Classification
```

AI must never retrieve information merely because it exists in the database.

---

# 119. CROSS-PROJECT DATA ACCESS

Cross-project queries require explicit authorization.

Default:

```text
DENY
```

unless the user or agent has global privileges.

---

# 120. PROJECT ARCHIVAL

When a project becomes archived:

```text
ACTIVE
 ↓
ARCHIVED
```

Operational resources may remain active or be decommissioned separately.

Archiving the project must not automatically delete:

* repositories
* databases
* documents
* audit history
* financial history

---

# 121. PROJECT DECOMMISSIONING

Decommissioning is a controlled workflow:

```text
PROJECT
 ↓
DECOMMISSION PLAN
 ↓
BACKUP
 ↓
RESOURCE INVENTORY
 ↓
DEPENDENCY CHECK
 ↓
RESOURCE SHUTDOWN
 ↓
ARCHIVE
 ↓
FINAL AUDIT
```

---

# 122. DEPENDENCY CHECK

Before decommissioning:

```text
Search dependencies
 ↓
Identify consumers
 ↓
Identify integrations
 ↓
Identify domains
 ↓
Identify workflows
 ↓
Identify agents
```

No critical dependency should remain undiscovered.

---

# 123. DATABASE HEALTH SCORE

Future database health may combine:

```text
Availability
Performance
Storage
Backup
Security
Replication
Errors
```

---

# 124. CONTROL TOWER DASHBOARD DATA

The database must support dashboards such as:

### Executive Dashboard

```text
Total Projects
Active Projects
Critical Alerts
Open Incidents
Server Health
Database Health
Deployment Status
AI Agent Status
Automation Status
Financial Summary
```

---

# 125. PROJECT DASHBOARD

Each project should expose:

```text
Overview
Infrastructure
Applications
Databases
Domains
Repositories
Deployments
AI
Automation
Monitoring
Incidents
Documents
Finance
```

---

# 126. INFRASTRUCTURE DASHBOARD

Should support:

```text
Servers
Databases
Domains
Resources
Health
Alerts
```

---

# 127. AI DASHBOARD

Should support:

```text
Agents
Models
Tools
Executions
Costs
Failures
Autonomy Levels
Approvals
```

---

# 128. AUTOMATION DASHBOARD

Should support:

```text
Workflows
Executions
Failures
Success Rate
Last Run
Schedules
```

---

# 129. INCIDENT DASHBOARD

Should support:

```text
Open Incidents
Critical Incidents
Mean Time To Resolve
Affected Projects
Affected Resources
Root Causes
```

---

# 130. DATABASE ARCHITECTURE DIAGRAM

Conceptual:

```text
                         CONTROL TOWER
                              │
                              ▼
                      PostgreSQL Database
                              │
        ┌─────────────┬───────┼────────┬──────────────┐
        ▼             ▼       ▼        ▼              ▼
     IDENTITY      PROJECTS   INFRA   AI          AUTOMATION
        │             │       │        │              │
        │             │       │        │              │
        └─────────────┴───────┼────────┴──────────────┘
                              │
                         OPERATIONS
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
           MONITORING      INCIDENTS        AUDIT
```

---

# 131. PROJECT DATA MODEL

```text
PROJECT
 │
 ├── PROJECT MEMBERS
 ├── ENVIRONMENTS
 ├── APPLICATIONS
 ├── SERVERS
 ├── DATABASES
 ├── DOMAINS
 ├── REPOSITORIES
 ├── DEPLOYMENTS
 ├── WORKFLOWS
 ├── AI AGENTS
 ├── DOCUMENTS
 ├── ALERTS
 ├── INCIDENTS
 └── FINANCE
```

---

# 132. DATABASE GOVERNANCE

Schema changes must be:

* Documented
* Version controlled
* Reviewed
* Tested
* Migrated
* Audited

---

# 133. NO DIRECT MANUAL PRODUCTION CHANGES

Production database changes should normally occur through:

```text
Migration
```

rather than ad-hoc SQL.

Emergency intervention is permitted only under controlled procedures.

---

# 134. DATABASE DOCUMENTATION

Every major table must eventually have:

```text
Purpose
Owner
Columns
Relationships
Indexes
Security
Retention
Data Classification
```

---

# 135. API / DATABASE SEPARATION

Frontend:

```text
NO DIRECT DATABASE ACCESS
```

Backend:

```text
AUTHORIZED DATABASE ACCESS
```

AI:

```text
CONTROLLED TOOL ACCESS
```

External systems:

```text
API / INTEGRATION ACCESS
```

---

# 136. DATABASE OBSERVABILITY

Every production database must expose enough operational information for the Control Tower to determine:

```text
Is it alive?
Is it reachable?
Is it healthy?
Is it overloaded?
Is backup working?
Is storage sufficient?
Are errors increasing?
```

---

# 137. DATABASE REGISTRY VS DATABASE ITSELF

Important distinction:

```text
CONTROL TOWER DB
        │
        └── Registry Record
               │
               └── DB-007
                      │
                      ▼
              Actual Project Database
```

The registry record does not contain the entire project database.

---

# 138. EXAMPLE MULTI-PROJECT MODEL

Suppose KemetRise operates:

```text
PRJ-001 — Digital Mall
PRJ-002 — Smart Clinic
PRJ-003 — AI Employee
PRJ-004 — Message Bank
```

Each may have:

```text
Different Server
Different Database
Different Repository
Different n8n Workflows
Different AI Agents
Different Domains
```

The Control Tower connects them through metadata.

---

# 139. EXAMPLE

```text
PRJ-002
Smart Clinic

Server:
SRV-012

Database:
DB-008

Repository:
REP-014

Application:
APP-021

Workflow:
WF-044

AI Agent:
AGT-009

Domain:
clinic.example
```

The Control Tower knows the relationships without owning every underlying resource.

---

# 140. DATABASE EXTENSIBILITY

New entity domains may be added without restructuring existing core tables.

Future domains may include:

```text
CRM
HR
LEGAL
CONTRACTS
PROCUREMENT
INVENTORY
MARKETING
SALES
CUSTOMERS
BILLING
ANALYTICS
```

---

# 141. SCHEMA VERSION

Current:

```text
Schema Version:
1.0.0
```

Every schema migration must increment the schema version.

---

# 142. MIGRATION SAFETY

Migrations must:

1. Be tested in development.
2. Be tested in staging.
3. Have rollback or recovery strategy.
4. Be backed up before risky changes.
5. Be logged.
6. Avoid destructive operations unless explicitly approved.

---

# 143. PRODUCTION DATABASE SAFETY LEVELS

```text
LEVEL 0
Read-only

LEVEL 1
Non-destructive write

LEVEL 2
Controlled structural change

LEVEL 3
Destructive change

LEVEL 4
Critical database operation
```

Levels 3 and 4 require elevated authorization.

---

# 144. DATABASE ACCESS AUDITING

The system should eventually record:

```text
Who accessed what
When
From where
For what operation
Against which project
```

---

# 145. FINAL DATABASE PRINCIPLE

The Control Tower database must become:

# THE CENTRAL MAP OF THE KEMETRISE ECOSYSTEM

It must answer, quickly and reliably:

```text
WHAT DO WE HAVE?
WHERE IS IT?
WHO OWNS IT?
WHAT PROJECT DOES IT BELONG TO?
WHAT IS ITS STATUS?
WHAT DEPENDS ON IT?
WHAT HAPPENED TO IT?
WHO CHANGED IT?
WHAT IS CURRENTLY WRONG?
```

---

# 146. IMPLEMENTATION PRIORITY

The first implementation should prioritize:

```text
1. Users
2. Roles
3. Permissions
4. Projects
5. Project Members
6. Environments
7. Servers
8. Databases
9. Applications
10. Repositories
11. Domains
12. Deployments
13. Workflows
14. AI Agents
15. Monitoring
16. Alerts
17. Incidents
18. Documents
19. Integrations
20. Audit
```

Finance and advanced AI memory may be implemented in subsequent phases.

---

# 147. DEFINITION OF DONE

KEM-002 is considered implemented when:

* PostgreSQL database exists.
* Migration system exists.
* Core tables exist.
* Primary/foreign keys exist.
* Project relationships exist.
* Project isolation exists.
* Roles exist.
* Permissions exist.
* Audit exists.
* Infrastructure registry exists.
* Application registry exists.
* AI registry exists.
* Automation registry exists.
* Monitoring registry exists.
* Incident management data exists.
* Integration registry exists.
* Backup strategy exists.
* Seed data exists.
* Database documentation exists.

---

# 148. DEPENDENCIES

This specification depends on:

```text
KEM-000
KEM-001
```

It provides database foundations for:

```text
KEM-003
SECURITY & RBAC

KEM-004
CONTROL TOWER UI/UX

KEM-005
PROJECT FACTORY

KEM-006
INFRASTRUCTURE & DEVOPS

KEM-007
AI ARCHITECTURE

KEM-008
AUTOMATION

KEM-009
OPERATIONS & INTELLIGENCE
```

---

# 149. FINAL ARCHITECTURAL STATEMENT

The database must never become a chaotic collection of unrelated tables.

Every entity must answer:

```text
WHO AM I?
WHAT DO I BELONG TO?
WHAT DO I CONNECT TO?
WHO CAN ACCESS ME?
WHAT IS MY CURRENT STATE?
WHAT IS MY HISTORY?
```

The database is therefore not merely storage.

It is the:

# STRUCTURAL MEMORY OF THE MR.ESS CONTROL TOWER.

---

# END OF KEM-002

**KemetRise — Legacy Nexus**

**MR.ESS Project Operating System**

**CONTROL TOWER DATABASE SPECIFICATION**

**Version:** 1.0.0

**STATUS:** FOUNDATION
