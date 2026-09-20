-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P00 — Preflight & Extensions
-- Source of truth: KEM-055 §4, KEM-054 §6, KEM-053 §5.1
-- Depends on: none (first migration)
-- Depended on by: every subsequent migration (gen_random_uuid() used in every table)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- NOTE: pg_trgm is intentionally NOT enabled here.
-- Status: DEFERRED — SEARCH-DEPENDENT EXTENSION (KEM-054 §6, KEM-055 §4).
-- It is not required by any table, constraint, index, or query in this migration set.
