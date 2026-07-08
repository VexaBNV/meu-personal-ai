-- migrations/006_payments.sql
-- Adiciona colunas de integração Stripe + RevenueCat na tabela users

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS stripe_customer_id      TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS stripe_subscription_id  TEXT,
  ADD COLUMN IF NOT EXISTS revenuecat_user_id       TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS subscription_status      TEXT NOT NULL DEFAULT 'inactive'
    CHECK (subscription_status IN ('inactive','trialing','active','past_due','canceled')),
  ADD COLUMN IF NOT EXISTS subscription_period_end  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS subscription_product_id  TEXT; -- ex: 'com.meupersonalai.pro.monthly'

-- Índices para lookup rápido nos webhooks
CREATE INDEX IF NOT EXISTS idx_users_stripe_customer    ON users(stripe_customer_id);
CREATE INDEX IF NOT EXISTS idx_users_stripe_sub         ON users(stripe_subscription_id);
CREATE INDEX IF NOT EXISTS idx_users_revenuecat         ON users(revenuecat_user_id);

-- Tabela de eventos de pagamento (auditoria completa)
CREATE TABLE IF NOT EXISTS payment_events (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source        TEXT NOT NULL CHECK (source IN ('stripe','revenuecat','manual')),
  event_type    TEXT NOT NULL,   -- ex: 'subscription.created', 'INITIAL_PURCHASE'
  plan_id       TEXT NOT NULL,   -- 'free' | 'pro' | 'elite'
  amount_cents  INTEGER,         -- valor em centavos (nullable para eventos sem cobrança)
  currency      TEXT DEFAULT 'BRL',
  product_id    TEXT,            -- ID do produto na store
  raw_payload   JSONB,           -- payload completo do webhook (para reprocessamento)
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_events_user    ON payment_events(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_events_created ON payment_events(created_at DESC);

-- View para billing do mês atual
CREATE OR REPLACE VIEW mv_monthly_revenue AS
SELECT
  date_trunc('month', created_at) AS month,
  plan_id,
  COUNT(*)                        AS events,
  SUM(amount_cents) / 100.0       AS total_brl
FROM payment_events
WHERE event_type IN ('subscription.created','RENEWAL','INITIAL_PURCHASE')
  AND amount_cents IS NOT NULL
GROUP BY 1, 2
ORDER BY 1 DESC, 2;

-- Função para criar customer Stripe quando usuário se registra
-- (chamada via PlansService.createStripeCustomer)
CREATE OR REPLACE FUNCTION set_stripe_customer(
  p_user_id   UUID,
  p_stripe_id TEXT
) RETURNS VOID AS $$
  UPDATE users
  SET stripe_customer_id = p_stripe_id
  WHERE id = p_user_id;
$$ LANGUAGE SQL;

-- ── Colunas adicionais em users (adicionadas junto com pagamentos) ──
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS stripe_customer_id       TEXT,
  ADD COLUMN IF NOT EXISTS subscription_status      TEXT,
  ADD COLUMN IF NOT EXISTS subscription_period_end  TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS had_trial                BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS revenuecat_app_user_id   TEXT;
