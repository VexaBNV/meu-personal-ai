-- ══════════════════════════════════════════════════════════════
-- 005_analytics.sql — Eventos de analytics e LGPD
-- ══════════════════════════════════════════════════════════════

-- ── Eventos de analytics ──────────────────────────────────────

CREATE TABLE analytics_events (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
  event       TEXT NOT NULL,
  properties  JSONB NOT NULL DEFAULT '{}',
  platform    TEXT,    -- 'ios' | 'android'
  app_version TEXT,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_analytics_user ON analytics_events(user_id, occurred_at DESC);
CREATE INDEX idx_analytics_event ON analytics_events(event, occurred_at DESC);
CREATE INDEX idx_analytics_props ON analytics_events USING gin(properties);

-- Particionamento por mês (produção) — simplificado para dev
-- Em produção, criar tabelas particionadas por mês para performance

-- ── Views de funil ────────────────────────────────────────────

CREATE OR REPLACE VIEW v_funnel_daily AS
SELECT
  DATE(occurred_at) AS day,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'app_open') AS dau,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'onboarding_started') AS onboarding_started,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'onboarding_completed') AS onboarding_completed,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'workout_started') AS workout_started,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'workout_completed') AS workout_completed,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'paywall_viewed') AS paywall_views,
  COUNT(DISTINCT user_id) FILTER (WHERE event = 'subscription_started') AS conversions
FROM analytics_events
WHERE occurred_at >= NOW() - INTERVAL '90 days'
GROUP BY DATE(occurred_at)
ORDER BY day DESC;

-- ── LGPD ──────────────────────────────────────────────────────

CREATE TYPE lgpd_request_type AS ENUM ('export', 'deletion', 'correction');
CREATE TYPE lgpd_request_status AS ENUM ('pending', 'processing', 'completed', 'failed');

CREATE TABLE lgpd_requests (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type          lgpd_request_type NOT NULL,
  status        lgpd_request_status NOT NULL DEFAULT 'pending',
  requested_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at  TIMESTAMPTZ,
  export_url    TEXT,    -- URL assinada para download do arquivo de exportação
  notes         TEXT
);

CREATE INDEX idx_lgpd_user ON lgpd_requests(user_id);

-- Política de retenção: apaga dados de usuários deletados após 30 dias
CREATE OR REPLACE FUNCTION purge_deleted_users() RETURNS void AS $$
BEGIN
  -- Remove dados de usuários com deleted_at > 30 dias
  -- Os dados são anonimizados, não deletados (mantém integridade referencial)
  UPDATE users
  SET
    email = 'deleted_' || id || '@deleted.com',
    name  = 'Usuário Deletado',
    firebase_uid = 'deleted_' || id,
    avatar_url = NULL
  WHERE
    deleted_at IS NOT NULL
    AND deleted_at < NOW() - INTERVAL '30 days'
    AND email NOT LIKE 'deleted_%';
END;
$$ LANGUAGE plpgsql;

-- ── Seed: eventos de exemplo para desenvolvimento ─────────────
-- Descomente para popular analytics no ambiente de dev:
-- INSERT INTO analytics_events (event, properties) VALUES
--   ('app_open', '{"platform":"android"}'),
--   ('onboarding_started', '{}'),
--   ('onboarding_completed', '{"duration_seconds":180}');
