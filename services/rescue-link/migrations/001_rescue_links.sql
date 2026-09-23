CREATE TABLE IF NOT EXISTS rescue_links (
    id TEXT PRIMARY KEY,
    owner_subject TEXT NOT NULL,
    token_hash BYTEA NOT NULL UNIQUE,
    encrypted_location BYTEA NOT NULL,
    accuracy_meters DOUBLE PRECISION NOT NULL CHECK (accuracy_meters >= 0 AND accuracy_meters <= 5000),
    emergency_type TEXT NOT NULL CHECK (emergency_type IN ('accident','lost','medical','fire','wildlife','weather','pet','unableToSpeak','other')),
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ NULL,
    accepted_at TIMESTAMPTZ NULL
);

CREATE INDEX IF NOT EXISTS rescue_links_owner_idx
    ON rescue_links (owner_subject, created_at DESC);
CREATE INDEX IF NOT EXISTS rescue_links_expiry_idx
    ON rescue_links (expires_at);
CREATE INDEX IF NOT EXISTS rescue_links_token_hash_idx
    ON rescue_links (token_hash);

CREATE TABLE IF NOT EXISTS rescue_link_responders (
    link_id TEXT NOT NULL REFERENCES rescue_links(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('officialService','verifiedProfessional','trustedContact','volunteer')),
    capability_hash BYTEA NOT NULL,
    capability_expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (link_id, subject),
    UNIQUE (capability_hash)
);

CREATE INDEX IF NOT EXISTS rescue_link_responders_capability_idx
    ON rescue_link_responders (capability_hash);