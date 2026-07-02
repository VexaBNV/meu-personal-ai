-- ══════════════════════════════════════════════════════════════
-- 004_social.sql — Ranking, desafios e features sociais
-- ══════════════════════════════════════════════════════════════

CREATE TYPE challenge_type AS ENUM ('daily', 'weekly', 'monthly');

-- ── Pontos e ranking ──────────────────────────────────────────

CREATE TABLE user_points (
  user_id     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  total       INTEGER NOT NULL DEFAULT 0,
  this_week   INTEGER NOT NULL DEFAULT 0,
  this_month  INTEGER NOT NULL DEFAULT 0,
  streak_days INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE point_events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  points      INTEGER NOT NULL,
  reason      TEXT NOT NULL,  -- 'workout_completed' | 'streak_7d' | etc
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_point_events_user ON point_events(user_id, created_at DESC);

-- View de ranking semanal
CREATE OR REPLACE VIEW v_weekly_ranking AS
SELECT
  u.id,
  u.name,
  u.avatar_url,
  up.this_week AS points,
  up.streak_days,
  RANK() OVER (ORDER BY up.this_week DESC) AS rank
FROM users u
JOIN user_points up ON up.user_id = u.id
WHERE u.deleted_at IS NULL
ORDER BY up.this_week DESC
LIMIT 100;

-- ── Desafios ──────────────────────────────────────────────────

CREATE TABLE challenges (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  type         challenge_type NOT NULL DEFAULT 'weekly',
  target_count INTEGER NOT NULL DEFAULT 1,
  points_reward INTEGER NOT NULL DEFAULT 50,
  starts_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ends_at      TIMESTAMPTZ,
  is_active    BOOLEAN NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE challenge_progress (
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  progress     INTEGER NOT NULL DEFAULT 0,
  completed    BOOLEAN NOT NULL DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, challenge_id)
);

CREATE INDEX idx_challenge_progress_user ON challenge_progress(user_id);

-- Desafios padrão
INSERT INTO challenges (title, description, type, target_count, points_reward) VALUES
  ('Semana completa',    'Faça todos os treinos planejados esta semana',  'weekly',  1,  100),
  ('3 treinos na semana','Complete 3 treinos esta semana',                'weekly',  3,   50),
  ('Treino diário',      'Faça pelo menos 1 treino hoje',                 'daily',   1,   20),
  ('Mês de ferro',       'Complete 12 treinos este mês',                  'monthly', 12, 300),
  ('Sequência de 7 dias','Treine 7 dias consecutivos',                    'weekly',  7,  200);
