-- ══════════════════════════════════════════════════════════════
-- 003_progress.sql — Fotos de progresso, métricas e notificações
-- ══════════════════════════════════════════════════════════════

-- ── Fotos de progresso ────────────────────────────────────────

CREATE TABLE progress_photos (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  url         TEXT NOT NULL,       -- URL no Cloudflare R2
  r2_key      TEXT NOT NULL,       -- chave interna no bucket
  taken_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  weight_kg   NUMERIC(5,2),
  note        TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_photos_user_id ON progress_photos(user_id);
CREATE INDEX idx_photos_taken_at ON progress_photos(user_id, taken_at DESC);

-- ── Métricas corporais ────────────────────────────────────────

CREATE TABLE body_metrics (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  weight_kg   NUMERIC(5,2),
  body_fat_pct NUMERIC(4,1),
  muscle_mass_kg NUMERIC(5,2),
  source      TEXT NOT NULL DEFAULT 'manual', -- manual | health_kit | google_fit
  measured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_metrics_user_id ON body_metrics(user_id, measured_at DESC);

-- ── Notificações ──────────────────────────────────────────────

CREATE TYPE notif_type AS ENUM (
  'daily_reminder', 'streak_alert', 'weekly_report',
  'workout_complete', 'marketing', 'system'
);

CREATE TABLE notification_settings (
  user_id               UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  daily_reminder        BOOLEAN NOT NULL DEFAULT TRUE,
  daily_reminder_time   TIME NOT NULL DEFAULT '07:00',
  streak_alerts         BOOLEAN NOT NULL DEFAULT TRUE,
  weekly_report         BOOLEAN NOT NULL DEFAULT TRUE,
  workout_complete      BOOLEAN NOT NULL DEFAULT TRUE,
  marketing             BOOLEAN NOT NULL DEFAULT FALSE,
  fcm_token             TEXT,
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notification_logs (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        notif_type NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT NOT NULL,
  sent_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  opened_at   TIMESTAMPTZ,
  fcm_message_id TEXT
);

CREATE INDEX idx_notif_logs_user ON notification_logs(user_id, sent_at DESC);

-- ── Mensagens do AI Coach ─────────────────────────────────────

CREATE TABLE coach_messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content     TEXT NOT NULL,
  tokens_used INTEGER,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_coach_messages_user ON coach_messages(user_id, created_at DESC);

-- Limpa mensagens antigas automaticamente (mantém 30 dias)
CREATE OR REPLACE FUNCTION cleanup_old_messages() RETURNS void AS $$
BEGIN
  DELETE FROM coach_messages
  WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;
