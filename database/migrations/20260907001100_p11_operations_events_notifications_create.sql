-- =============================================================================
-- KemetRise — Legacy Nexus — MR-ESS Control Tower Database
-- Migration: P11 — Operations Events & Notifications
-- Source of truth: KEM-055 §6.4, §7, §8, §9
-- Depends on: P03, P05, P06, P10
-- Depended on by: none (leaf phase)
-- =============================================================================

CREATE TABLE operations.events (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type     TEXT NOT NULL,   -- trigger-validated: lookup_values('EVENT_TYPE')
    project_id     UUID REFERENCES core.projects(id),
    resource_type  TEXT NOT NULL,
    resource_id    UUID NOT NULL,
    payload        JSONB NOT NULL DEFAULT '{}'::jsonb,
    status         TEXT NOT NULL DEFAULT 'PENDING',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at   TIMESTAMPTZ
);

CREATE TABLE operations.notifications (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id       UUID NOT NULL REFERENCES identity.users(id),
    channel            TEXT NOT NULL,
    subject            TEXT NOT NULL,
    body               TEXT,
    related_event_id   UUID REFERENCES operations.events(id),
    status             TEXT NOT NULL DEFAULT 'PENDING',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    sent_at            TIMESTAMPTZ
);

-- Explicit indexes (KEM-055 §7)
CREATE INDEX idx_events_project ON operations.events (project_id);
CREATE INDEX idx_events_status ON operations.events (status);
CREATE INDEX idx_events_created_at ON operations.events (created_at);
CREATE INDEX idx_notifications_recipient ON operations.notifications (recipient_id);
CREATE INDEX idx_notifications_status ON operations.notifications (status);

-- Lookup-validation trigger attachment
CREATE TRIGGER trg_lookup_events_type
    BEFORE INSERT OR UPDATE OF event_type ON operations.events
    FOR EACH ROW
    EXECUTE FUNCTION core.trigger_validate_lookup('EVENT_TYPE', 'event_type');
