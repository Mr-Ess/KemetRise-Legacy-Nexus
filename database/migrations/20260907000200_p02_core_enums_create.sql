-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P02 — Enum Types (schema-qualified, per domain — never in `public`)
-- Source of truth: KEM-055 §5, KEM-054 §7.2
-- Depends on: P01 (every target schema must already exist)
-- Depended on by: P03, P06, P07, P09, P10, P13 (every table with an enum-typed column)
-- =============================================================================

-- core schema (shared/core + core-domain-specific)
CREATE TYPE core.record_status AS ENUM ('ACTIVE','INACTIVE','ARCHIVED');
-- dependent tables: identity.users, identity.roles, core.environments, core.assets,
--   infrastructure.servers, infrastructure.databases, infrastructure.repositories,
--   infrastructure.domains, infrastructure.services, automation.workflows,
--   ai.models, ai.agents, security.secret_references

CREATE TYPE core.project_status AS ENUM (
  'IDEA','PLANNING','APPROVED','BUILDING','TESTING',
  'STAGING','LIVE','MAINTENANCE','SUSPENDED','RETIRED','ARCHIVED');
-- dependent tables: core.projects

CREATE TYPE core.project_criticality AS ENUM ('LOW','MEDIUM','HIGH','CRITICAL');
-- dependent tables: core.projects, core.assets, core.asset_dependencies

CREATE TYPE core.environment_type AS ENUM ('DEV','TEST','STAGE','PROD','DR');
-- dependent tables: core.environments

CREATE TYPE core.dependency_type AS ENUM (
  'REQUIRES','DEPENDS_ON','HOSTED_ON','CONNECTS_TO',
  'DEPLOYS_TO','READS_FROM','WRITES_TO','AUTHENTICATES_WITH');
-- dependent tables: core.asset_dependencies

-- identity schema
CREATE TYPE identity.identity_owner_type AS ENUM ('USER','TEAM','ORGANIZATION');
-- dependent tables: core.projects (owner_type)

-- infrastructure schema
CREATE TYPE infrastructure.health_status AS ENUM ('HEALTHY','WARNING','CRITICAL','UNKNOWN');
-- dependent tables: infrastructure.services

CREATE TYPE infrastructure.ssl_status AS ENUM ('VALID','EXPIRING','EXPIRED','NOT_CONFIGURED','UNKNOWN');
-- dependent tables: infrastructure.domains, infrastructure.certificates

-- operations schema
CREATE TYPE operations.deployment_status AS ENUM (
  'QUEUED','RUNNING','SUCCESS','FAILED','ROLLED_BACK','CANCELLED');
-- dependent tables: operations.deployments

CREATE TYPE operations.incident_severity AS ENUM ('SEV-1','SEV-2','SEV-3','SEV-4');
-- dependent tables: operations.incidents

CREATE TYPE operations.incident_status AS ENUM (
  'OPEN','INVESTIGATING','MITIGATED','RESOLVED','CLOSED');
-- dependent tables: operations.incidents

CREATE TYPE operations.change_status AS ENUM (
  'REQUESTED','APPROVED','REJECTED','SCHEDULED',
  'IMPLEMENTING','COMPLETED','ROLLED_BACK');
-- dependent tables: operations.changes

CREATE TYPE operations.change_risk_level AS ENUM ('LOW','MEDIUM','HIGH','CRITICAL');
-- dependent tables: operations.changes

CREATE TYPE operations.backup_status AS ENUM ('HEALTHY','WARNING','FAILED','UNKNOWN');
-- dependent tables: operations.backups

-- ai schema
CREATE TYPE ai.ai_autonomy_level AS ENUM (
  'L0_OBSERVE','L1_RECOMMEND','L2_LOW_RISK_AUTOMATION',
  'L3_APPROVAL_REQUIRED','L4_GUARDED_AUTONOMY');
-- dependent tables: ai.agents

-- 15 enums total. Zero enums placed in `public`. Zero duplicates.
-- automation / finance / security / audit schemas intentionally have no dedicated enum
-- (KEM-054 §7.2 — those tables use TEXT + core.lookup_values, or no enum at all).
