-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

-- Enumerated types for stronger data integrity
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_login_type') THEN
    CREATE TYPE user_login_type AS ENUM ('manual','google','facebook');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'provider_role') THEN
    CREATE TYPE provider_role AS ENUM ('owner','editor','viewer');
  END IF;
END$$;

-- Lookup tables
CREATE TABLE data_source_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE aggregation_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(20) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Core reference tables
CREATE TABLE data_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Components with description column
CREATE TABLE components (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Users table (removed updated_at)
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email CITEXT UNIQUE NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  login_type user_login_type NOT NULL,
  external_id VARCHAR(255),
  password_hash TEXT,
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  current_data_provider_id UUID
    REFERENCES data_providers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_login_fields CHECK (
    (login_type = 'manual'    AND password_hash IS NOT NULL AND external_id IS NULL)
    OR
    (login_type <> 'manual'   AND password_hash IS NULL    AND external_id IS NOT NULL)
  ),
  UNIQUE (login_type, external_id)
);

-- Data sources (prevent delete when sources exist)
CREATE TABLE data_sources (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  data_provider_id UUID NOT NULL
    REFERENCES data_providers(id) ON DELETE RESTRICT,
  data_source_type_id UUID NOT NULL
    REFERENCES data_source_types(id) ON DELETE RESTRICT,
  component_id UUID NOT NULL
    REFERENCES components(id) ON DELETE RESTRICT,
  client_id VARCHAR(255) NOT NULL,
  client_secret_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Many-to-many linking with RESTRICT
CREATE TABLE data_source_aggregations (
  data_source_id UUID NOT NULL
    REFERENCES data_sources(id) ON DELETE CASCADE,
  aggregation_type_id UUID NOT NULL
    REFERENCES aggregation_types(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (data_source_id, aggregation_type_id)
);

-- Mapping users ⇆ providers; allow provider deletion cascading for user links
CREATE TABLE data_provider_users (
  user_id UUID NOT NULL
    REFERENCES users(id) ON DELETE RESTRICT,
  data_provider_id UUID NOT NULL
    REFERENCES data_providers(id) ON DELETE CASCADE,
  role provider_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, data_provider_id)
);

-- Seed admin user
INSERT INTO users (
  email, first_name, last_name, login_type, password_hash, is_admin, is_verified, created_at
)
VALUES (
  'admin@example.com',
  'Admin',
  'User',
  'manual',
  '$2b$12$k5Q1ogfLB8C7gaJABurYlezVFR2YD3CsF.qZ7t0bYsWTpATFVbrwi',
  TRUE,
  TRUE,
  now()
)
ON CONFLICT (email) DO NOTHING;

-- Seed lookup data
INSERT INTO data_source_types (name, description)
VALUES
  ('Raw',       'Unmodified/raw sensor values'),
  ('Processed', 'Values after enrichment or cleaning')
ON CONFLICT (name) DO NOTHING;

INSERT INTO aggregation_types (name, description)
VALUES
  ('Hour', 'Aggregate by hour'),
  ('Day',  'Aggregate by day'),
  ('Year', 'Aggregate by year')
ON CONFLICT (name) DO NOTHING;

-- Seed components with descriptions
INSERT INTO components (name, description)
VALUES
  ('PM10', 'Particulate matter with diameter ≤ 10 micrometers'),
  ('PM2.5', 'Particulate matter with diameter ≤ 2.5 micrometers'),
  ('NO', 'Nitric oxide'),
  ('NO2', 'Nitrogen dioxide'),
  ('NOX', 'Nitrogen oxides (NO and NO2 collectively)'),
  ('CO', 'Carbon monoxide'),
  ('SO2', 'Sulfur dioxide'),
  ('O3', 'Ozone')
ON CONFLICT (name) DO NOTHING;
