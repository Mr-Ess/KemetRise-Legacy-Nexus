# POST-BOOTSTRAP OPERATIONS — NOT MIGRATIONS

**This directory is intentionally separate from `/database/migrations/`.**

Nothing in this directory is a migration. Nothing here is picked up by a migration
runner (Supabase CLI or otherwise), and nothing here should ever be numbered `Pxx` or
run automatically as part of the `P00 → P21` sequence. Files here are invoked exactly
once, manually or by an explicit application bootstrap step, and only after specific
real-world preconditions are met (a real human System Admin must already exist).

---

## Why this exists

`core.projects.owner_id` is `NOT NULL` with no default (KEM-053 §7.2 — **unchanged**,
KEM-053 was **not modified** to accommodate this). `PRJ-000` (the Control Tower system
project) cannot be created by a pure SQL migration, because no real `identity.users`
row exists yet at migration time — nobody has signed up. Per **KEM-052 §186**
(the existing, authoritative bootstrap sequence, also unmodified), `CREATE SYSTEM
ADMIN` must happen **before** `CREATE CONTROL TOWER SYSTEM RECORD`.

This directory documents and operationalizes that exact sequence. Full narrative is in
**KEM-055 §17 — Bootstrap Lifecycle**. This README is the operational summary.

---

## The three phases

```text
Phase 1 — Database Migration Bootstrap   (P00–P21, /database/migrations/)
    Roles, permissions, lookup values, and all other seed data that does NOT
    depend on any real user existing. Fully automated, deterministic, idempotent.
    PRJ-000 is explicitly NOT created here (P21a).

Phase 2 — Identity Bootstrap              (application layer + Supabase Auth)
    1. A real person signs up through Supabase Auth (application UI/API).
    2. auth.users gets a row. The existing trg_handle_new_user trigger (P03)
       fires automatically and creates the matching identity.users row.
    3. A trusted backend process, authenticated with the Supabase service_role
       key (which bypasses RLS entirely — KEM-053 §9.5, unchanged), inserts one
       row into identity.user_roles granting that identity.users.id the
       SUPER_ADMIN role (identity.roles.role_code = 'SUPER_ADMIN', seeded in
       Phase 1 / P21a). This is the ONLY step in this entire lifecycle that
       uses a privileged, RLS-bypassing credential — and it must never be
       exposed to a frontend or any untrusted caller.

Phase 3 — Control Tower Bootstrap          (this directory)
    Once Phase 2 is complete, the now-authenticated System Admin's own session
    (a normal Supabase client session, NOT service_role) calls:

        SELECT core.bootstrap_control_tower_project();

    This function (defined in migration P06C) is the entire mechanism. See
    `001_control_tower_bootstrap_invoke.sql` in this directory for the exact
    invocation and verification queries.
```

---

## Contract between database and application

```text
Database provides:  core.bootstrap_control_tower_project() — SECURITY DEFINER,
                     RETURNS UUID, idempotent, self-authorizing.
Application must:   invoke it under an authenticated session belonging to a user
                     who already holds SUPER_ADMIN (Phase 2 must be complete first).
                     The application does NOT pass an owner_id, a project row, or
                     any other argument — the function derives everything itself
                     from the calling session (identity.current_user_id()) and from
                     the already-seeded identity.roles/user_roles state.
Application must NOT: call this function using the service_role key. Doing so would
                     make identity.current_user_id() resolve to NULL (service_role
                     has no corresponding auth.uid()), which the function already
                     rejects (Test A behavior) — so this is enforced by the function
                     itself, not merely a convention.
```

See `001_control_tower_bootstrap_invoke.sql` for the literal invocation and the
verification query to run immediately after.
