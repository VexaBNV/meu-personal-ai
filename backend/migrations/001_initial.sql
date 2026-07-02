-- ══════════════════════════════════════════════════════════════
-- 001_initial.sql — Schema inicial
-- Usuários, perfis, sessões auth
-- ══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- busca por texto

-- ── Enum types ────────────────────────────────────────────────

CREATE TYPE user_plan AS ENUM ('free', 'pro', 'elite');
CREATE TYPE user_goal AS ENUM ('hypertrophy', 'weight_loss', 'strength', 'health');
CREATE TYPE user_level AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE training_env AS ENUM ('gym', 'home', 'outdoor', 'mixed');
CREATE TYPE time_of_day AS ENUM ('morning', 'afternoon', 'evening', 'flexible');
CREATE TYPE coach_tone AS ENUM ('motivational', 'technical', 'friendly', 'strict');
CREATE TYPE sex_type AS ENUM ('male', 'female', 'other');

-- ── Tabela de usuários ────────────────────────────────────────

CREATE TABLE users (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  firebase_uid          TEXT UNIQUE NOT NULL,
  email                 TEXT UNIQUE NOT NULL,
  name                  TEXT NOT NULL,
  avatar_url            TEXT,
  plan                  user_plan NOT NULL DEFAULT 'free',
  trial_ends_at         TIMESTAMPTZ,
  anamnesis_completed   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at            TIMESTAMPTZ  -- soft delete para LGPD
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_plan ON users(plan);

-- ── Perfil de treino ──────────────────────────────────────────

CREATE TABLE user_profiles (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Objetivos
  primary_goal          user_goal NOT NULL DEFAULT 'hypertrophy',
  level                 user_level NOT NULL DEFAULT 'beginner',
  weekly_frequency      SMALLINT NOT NULL DEFAULT 3 CHECK (weekly_frequency BETWEEN 2 AND 7),

  -- Físico
  weight_kg             NUMERIC(5,2),
  height_cm             NUMERIC(5,1),
  age                   SMALLINT CHECK (age BETWEEN 16 AND 100),
  sex                   sex_type,

  -- Saúde
  injuries              TEXT[] NOT NULL DEFAULT '{}',
  medical_conditions    TEXT[] NOT NULL DEFAULT '{}',
  has_cardio_issue      BOOLEAN NOT NULL DEFAULT FALSE,
  has_doctor_clearance  BOOLEAN NOT NULL DEFAULT FALSE,

  -- Estilo
  environment           training_env NOT NULL DEFAULT 'gym',
  equipment             TEXT[] NOT NULL DEFAULT '{}',
  session_duration_min  SMALLINT NOT NULL DEFAULT 60,
  time_of_day           time_of_day NOT NULL DEFAULT 'flexible',

  -- AI Coach
  coach_tone            coach_tone NOT NULL DEFAULT 'motivational',
  coach_preset          TEXT NOT NULL DEFAULT 'personal1',
  coach_name            TEXT NOT NULL DEFAULT 'Alex',

  -- Consentimentos LGPD
  accepted_terms        BOOLEAN NOT NULL DEFAULT FALSE,
  accepted_health_data  BOOLEAN NOT NULL DEFAULT FALSE,
  accepted_marketing    BOOLEAN NOT NULL DEFAULT FALSE,
  terms_accepted_at     TIMESTAMPTZ,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE(user_id)
);

-- ── Sessões JWT (refresh tokens) ──────────────────────────────

CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  device_info TEXT,
  ip_address  INET,
  expires_at  TIMESTAMPTZ NOT NULL,
  revoked_at  TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_token_hash ON refresh_tokens(token_hash);

-- ── Trigger: updated_at automático ───────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
