-- ══════════════════════════════════════════════════════════════
-- 002_workout.sql — Programas, sessões e execução de treino
-- ══════════════════════════════════════════════════════════════

CREATE TYPE stimulus_type AS ENUM ('compound', 'isolation', 'cardio', 'mobility');
CREATE TYPE difficulty AS ENUM ('beginner', 'intermediate', 'advanced');
CREATE TYPE set_outcome AS ENUM ('success', 'partial', 'failed', 'skipped');
CREATE TYPE week_day_status AS ENUM ('done', 'missed', 'rest', 'future');

-- ── Banco de exercícios ───────────────────────────────────────

CREATE TABLE exercises (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name             TEXT NOT NULL,
  muscle_group     TEXT NOT NULL,
  primary_muscles  TEXT[] NOT NULL DEFAULT '{}',
  stimulus_type    stimulus_type NOT NULL DEFAULT 'compound',
  equipment        TEXT[] NOT NULL DEFAULT '{}',
  difficulty       difficulty NOT NULL DEFAULT 'intermediate',
  instructions     TEXT[] NOT NULL DEFAULT '{}',
  coaching_cues    TEXT[] NOT NULL DEFAULT '{}',
  common_errors    TEXT[] NOT NULL DEFAULT '{}',
  video_url        TEXT,
  image_url        TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exercises_muscle_group ON exercises(muscle_group);
CREATE INDEX idx_exercises_difficulty ON exercises(difficulty);
CREATE INDEX idx_exercises_name ON exercises USING gin(name gin_trgm_ops);

-- Substitutos de exercícios (grafo de equivalência)
CREATE TABLE exercise_substitutes (
  exercise_id   UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  substitute_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
  score         SMALLINT NOT NULL DEFAULT 80 CHECK (score BETWEEN 0 AND 100),
  PRIMARY KEY (exercise_id, substitute_id),
  CHECK (exercise_id != substitute_id)
);

-- ── Programas de treino ───────────────────────────────────────

CREATE TABLE workout_programs (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  weekly_frequency SMALLINT NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT TRUE,
  ai_prompt_used   TEXT,           -- prompt enviado para a IA (auditoria)
  generated_at     TIMESTAMPTZ,
  starts_at        DATE,
  ends_at          DATE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_programs_user_id ON workout_programs(user_id);
CREATE INDEX idx_programs_active ON workout_programs(user_id, is_active);

CREATE TRIGGER trg_programs_updated_at
  BEFORE UPDATE ON workout_programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── Sessões planejadas ────────────────────────────────────────

CREATE TABLE workout_sessions (
  id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id         UUID NOT NULL REFERENCES workout_programs(id) ON DELETE CASCADE,
  name               TEXT NOT NULL,
  focus              TEXT,
  day_of_week        SMALLINT CHECK (day_of_week BETWEEN 1 AND 7), -- 1=seg
  estimated_duration SMALLINT,    -- minutos
  sort_order         SMALLINT NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_program_id ON workout_sessions(program_id);

-- ── Exercícios dentro da sessão ───────────────────────────────

CREATE TABLE session_exercises (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id   UUID NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
  exercise_id  UUID NOT NULL REFERENCES exercises(id),
  sets         SMALLINT NOT NULL DEFAULT 3,
  reps_min     SMALLINT NOT NULL DEFAULT 8,
  reps_max     SMALLINT NOT NULL DEFAULT 12,
  load_kg      NUMERIC(6,2),
  rest_seconds SMALLINT NOT NULL DEFAULT 90,
  rpe_target   NUMERIC(3,1),
  notes        TEXT,
  sort_order   SMALLINT NOT NULL DEFAULT 0
);

CREATE INDEX idx_session_exercises_session ON session_exercises(session_id);

-- ── Log de execução ───────────────────────────────────────────

CREATE TABLE session_logs (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id            UUID REFERENCES workout_sessions(id),
  exercise_id           UUID NOT NULL REFERENCES exercises(id),
  set_number            SMALLINT NOT NULL,
  load_kg               NUMERIC(6,2),
  reps_done             SMALLINT,
  rpe_actual            NUMERIC(3,1),
  outcome               set_outcome NOT NULL DEFAULT 'success',
  pain_reported         BOOLEAN NOT NULL DEFAULT FALSE,
  pain_region           TEXT,
  notes                 TEXT,
  logged_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_session_logs_user_id ON session_logs(user_id);
CREATE INDEX idx_session_logs_exercise ON session_logs(user_id, exercise_id);
CREATE INDEX idx_session_logs_date ON session_logs(user_id, logged_at DESC);

-- ── Sessões completadas (resumo por dia) ─────────────────────

CREATE TABLE completed_sessions (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id        UUID REFERENCES workout_sessions(id),
  started_at        TIMESTAMPTZ NOT NULL,
  finished_at       TIMESTAMPTZ,
  duration_seconds  INTEGER,
  exercises_done    SMALLINT NOT NULL DEFAULT 0,
  sets_done         SMALLINT NOT NULL DEFAULT 0,
  ai_feedback       TEXT,         -- feedback gerado pela IA
  feedback_generated_at TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_completed_user_id ON completed_sessions(user_id);
CREATE INDEX idx_completed_date ON completed_sessions(user_id, started_at DESC);

-- ── View: streak e aderência ──────────────────────────────────

CREATE OR REPLACE VIEW v_user_stats AS
SELECT
  u.id AS user_id,
  COUNT(DISTINCT DATE(cs.started_at)) FILTER (
    WHERE cs.started_at >= NOW() - INTERVAL '90 days'
  ) AS sessions_last_90d,
  -- streak calculado via função abaixo
  0 AS streak_days,  -- atualizado via trigger
  ROUND(
    COUNT(DISTINCT DATE(cs.started_at)) FILTER (
      WHERE cs.started_at >= DATE_TRUNC('week', NOW())
    )::NUMERIC /
    NULLIF(
      (SELECT weekly_frequency FROM user_profiles WHERE user_id = u.id), 0
    ) * 100, 1
  ) AS weekly_adherence_pct
FROM users u
LEFT JOIN completed_sessions cs ON cs.user_id = u.id
GROUP BY u.id;
