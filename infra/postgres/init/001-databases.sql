CREATE DATABASE keycloak;

\connect espana_outdoor

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE SCHEMA IF NOT EXISTS outdoor;

CREATE TABLE IF NOT EXISTS outdoor.source_registry (
  id bigserial PRIMARY KEY,
  source_key text NOT NULL UNIQUE,
  authority text NOT NULL,
  endpoint text,
  license text,
  attribution text,
  update_interval_seconds integer,
  last_success_at timestamptz,
  last_seen_at timestamptz,
  status text NOT NULL DEFAULT 'unknown',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS source_registry_status_idx
  ON outdoor.source_registry(status);

CREATE TABLE IF NOT EXISTS outdoor.route_reports (
  id uuid PRIMARY KEY,
  category text NOT NULL,
  status text NOT NULL DEFAULT 'community',
  confidence numeric(4,3),
  observed_at timestamptz NOT NULL,
  expires_at timestamptz,
  geom geometry(Point, 4326),
  source_id bigint REFERENCES outdoor.source_registry(id),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS route_reports_geom_gix
  ON outdoor.route_reports USING gist (geom);

CREATE INDEX IF NOT EXISTS route_reports_expiry_idx
  ON outdoor.route_reports(expires_at);
