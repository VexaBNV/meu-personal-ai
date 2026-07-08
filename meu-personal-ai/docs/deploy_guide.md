# Guia de Deploy — Meu Personal AI
## Do zero ao servidor em produção

---

## Pré-requisitos

Instale as ferramentas necessárias antes de começar:

```bash
# Node.js 20+
brew install node

# Flutter 3.22+
# https://docs.flutter.dev/get-started/install

# Fly.io CLI
brew install flyctl

# Docker (para build local)
brew install --cask docker

# Stripe CLI (para testar webhooks)
brew install stripe/stripe-cli/stripe
```

---

## 1. Banco de dados — Supabase

### 1.1 Criar projeto
1. Acesse https://supabase.com/dashboard → **New project**
2. Nome: `meu-personal-ai-prod`
3. Região: **South America (São Paulo)** — `sa-east-1`
4. Senha forte → copiar e guardar no 1Password/Bitwarden

### 1.2 Rodar migrations
Na aba **SQL Editor** do Supabase, cole e execute os arquivos **na ordem**:

```
migrations/001_initial.sql
migrations/002_exercises.sql
migrations/003_social.sql
migrations/004_analytics.sql
migrations/005_lgpd.sql
migrations/006_payments.sql
```

### 1.3 Rodar seed de exercícios
```bash
# Exportar a DATABASE_URL do Supabase (Settings → Database → Connection String → URI)
export DATABASE_URL="postgresql://postgres:[senha]@db.[ref].supabase.co:5432/postgres"

# Rodar o seed
cd backend
npx ts-node scripts/generate-exercise-bank.ts
# Saída esperada: "127 exercícios inseridos · 340+ substituições"
```

### 1.4 Copiar variáveis
Do painel do Supabase, copie:
```env
DATABASE_URL=postgresql://postgres:[senha]@db.[ref].supabase.co:5432/postgres
```

---

## 2. Redis — Upstash

1. Acesse https://console.upstash.com → **Create database**
2. Nome: `meu-personal-ai`
3. Região: **São Paulo**
4. Type: **Redis** | Plan: **Pay as you go**
5. Copie a **REDIS_URL** (começa com `rediss://`)

```env
REDIS_URL=rediss://default:[token]@[host].upstash.io:6379
```

---

## 3. Firebase

### 3.1 Criar projeto
1. https://console.firebase.google.com → **Add project**
2. Nome: `meu-personal-ai`
3. Desabilitar Google Analytics (pode ativar depois)

### 3.2 Habilitar Authentication
- **Build → Authentication → Get started**
- Habilitar: **Email/Password** e **Google**
- Adicionar domínio autorizado: `api.meupersonalai.com.br`

### 3.3 Firebase Messaging (FCM)
- **Project Settings → Cloud Messaging**
- Copiar **Server key** (para o backend)

### 3.4 Service Account para o backend
- **Project Settings → Service accounts → Generate new private key**
- Salvar o JSON — será usado como `FIREBASE_SERVICE_ACCOUNT`

### 3.5 Variáveis Firebase
```env
FIREBASE_PROJECT_ID=meu-personal-ai
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@meu-personal-ai.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**Atenção:** No Fly.io, defina `FIREBASE_PRIVATE_KEY` entre aspas simples e com `\n` literal:
```bash
flyctl secrets set FIREBASE_PRIVATE_KEY='-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n'
```

---

## 4. Cloudflare R2

1. https://dash.cloudflare.com → **R2 Object Storage → Create bucket**
2. Nome: `meu-personal-ai-photos`
3. Região: automático (Cloudflare seleciona mais próximo)
4. **Manage R2 API tokens → Create API token**
   - Permission: **Object Read & Write**
   - Copiar: Account ID, Access Key ID, Secret Access Key

```env
R2_ACCOUNT_ID=xxxxxxxxxx
R2_ACCESS_KEY_ID=xxxxxxxxxx
R2_SECRET_ACCESS_KEY=xxxxxxxxxx
R2_BUCKET_NAME=meu-personal-ai-photos
R2_PUBLIC_URL=https://pub.meupersonalai.com.br
```

Para o `R2_PUBLIC_URL`, configure um Custom Domain no R2 bucket.

---

## 5. Fly.io — Deploy do backend

### 5.1 Criar app
```bash
# Login
flyctl auth login

# Criar app na região São Paulo
flyctl apps create meu-personal-ai --region gru

# Verificar
flyctl apps list
```

### 5.2 Configurar volumes (se necessário)
```bash
# O app usa banco externo (Supabase) e cache externo (Upstash)
# Não precisa de volume persistente no Fly.io
```

### 5.3 Configurar secrets
```bash
# Defina um por um ou use o script abaixo

flyctl secrets set \
  DATABASE_URL="postgresql://..." \
  REDIS_URL="rediss://..." \
  JWT_SECRET="$(openssl rand -base64 64)" \
  JWT_REFRESH_SECRET="$(openssl rand -base64 64)" \
  LLM_API_KEY="sk-ant-..." \
  FIREBASE_PROJECT_ID="meu-personal-ai" \
  FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxx@..." \
  FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n" \
  R2_ACCOUNT_ID="..." \
  R2_ACCESS_KEY_ID="..." \
  R2_SECRET_ACCESS_KEY="..." \
  R2_BUCKET_NAME="meu-personal-ai-photos" \
  R2_PUBLIC_URL="https://pub.meupersonalai.com.br" \
  STRIPE_SECRET_KEY="sk_live_..." \
  STRIPE_WEBHOOK_SECRET="whsec_..." \
  STRIPE_PRICE_PRO_MONTHLY="price_..." \
  STRIPE_PRICE_PRO_ANNUAL="price_..." \
  STRIPE_PRICE_ELITE_MONTHLY="price_..." \
  STRIPE_PRICE_ELITE_ANNUAL="price_..." \
  REVENUECAT_WEBHOOK_SECRET="..." \
  NODE_ENV="production" \
  PORT="3000"

# Verificar
flyctl secrets list
```

### 5.4 fly.toml (já configurado no repo)
```toml
app = "meu-personal-ai"
primary_region = "gru"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "3000"
  NODE_ENV = "production"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "requests"
    hard_limit = 200
    soft_limit = 100

[[vm]]
  memory = "1gb"
  cpu_kind = "shared"
  cpus = 1
```

### 5.5 Primeiro deploy
```bash
cd backend

# Build e deploy
flyctl deploy

# Acompanhar logs
flyctl logs -a meu-personal-ai

# Verificar saúde
curl https://meu-personal-ai.fly.dev/health
# Esperado: {"status":"ok","db":"ok","redis":"ok"}
```

### 5.6 Configurar domínio customizado
```bash
# Adicionar certificado SSL
flyctl certs create api.meupersonalai.com.br

# No DNS do seu domínio, adicionar:
# CNAME api → meu-personal-ai.fly.dev
```

---

## 6. Build do app Flutter

### 6.1 Configurar variáveis
Crie o arquivo `flutter_env.sh`:
```bash
#!/bin/bash
export REVENUECAT_API_KEY_IOS="appl_xxxx"
export REVENUECAT_API_KEY_ANDROID="goog_xxxx"
export API_BASE_URL="https://api.meupersonalai.com.br"
```

### 6.2 Build iOS (requer macOS + Xcode)
```bash
source flutter_env.sh

flutter build ipa \
  --dart-define=REVENUECAT_API_KEY_IOS=$REVENUECAT_API_KEY_IOS \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --release

# Abrir no Transporter para upload à App Store Connect
open build/ios/ipa/*.ipa
```

### 6.3 Build Android
```bash
source flutter_env.sh

flutter build appbundle \
  --dart-define=REVENUECAT_API_KEY_ANDROID=$REVENUECAT_API_KEY_ANDROID \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --release

# Assinar com keystore de produção (configurar no build.gradle)
# Upload para Google Play Console
```

### 6.4 Configurar API_BASE_URL no app
Em `lib/core/config/app_config.dart`:
```dart
static const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000', // desenvolvimento
);
```

---

## 7. CI/CD — GitHub Actions

O pipeline está configurado em `.github/workflows/`. Para ativar:

### 7.1 Adicionar secrets no GitHub
**Settings → Secrets → Actions → New repository secret:**

```
FLY_API_TOKEN          → flyctl auth token
APPLE_ID               → seu Apple ID
APPLE_APP_SPECIFIC_PWD → senha específica de app (appleid.apple.com)
GOOGLE_PLAY_JSON_KEY   → JSON da service account do Google Play
REVENUECAT_API_KEY_IOS
REVENUECAT_API_KEY_ANDROID
API_BASE_URL
```

### 7.2 Fluxo do pipeline
```
Push para main
    ↓
flutter test (58 testes)
    ↓
nestjs test
    ↓
flyctl deploy (backend)
    ↓
[apenas em git tag v*]
    ↓
flutter build ipa → Testflight
flutter build appbundle → Play Internal
```

### 7.3 Deploy manual
```bash
# Forçar deploy sem CI
flyctl deploy --force-machines

# Rollback para versão anterior
flyctl releases list
flyctl deploy --image [image-id-anterior]
```

---

## 8. Monitoramento pós-deploy

### 8.1 Logs em tempo real
```bash
flyctl logs -a meu-personal-ai --follow
```

### 8.2 Métricas
```bash
# Status das máquinas
flyctl status -a meu-personal-ai

# Uso de CPU/memória
flyctl metrics -a meu-personal-ai
```

### 8.3 Alertas recomendados
Configure no Fly.io ou via Uptime Robot (gratuito):
- `/health` a cada 1 minuto
- Alerta por e-mail/Slack se downtime > 2 minutos
- Alerta se erro 5xx > 1% por 5 minutos

### 8.4 Checklist pós-deploy
```bash
# 1. Saúde do servidor
curl https://api.meupersonalai.com.br/health

# 2. Banco de dados
curl https://api.meupersonalai.com.br/health/db

# 3. Redis
curl https://api.meupersonalai.com.br/health/redis

# 4. Fluxo de autenticação
curl -X POST https://api.meupersonalai.com.br/auth/test

# 5. Seed de exercícios
curl https://api.meupersonalai.com.br/exercises | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{len(d)} exercícios')"

# 6. Webhook Stripe (testar localmente primeiro)
stripe listen --forward-to https://api.meupersonalai.com.br/webhooks/stripe
```

---

## 9. Variáveis de ambiente — referência completa

```env
# ── Banco ──────────────────────────────────────────────────
DATABASE_URL=postgresql://postgres:[senha]@db.[ref].supabase.co:5432/postgres

# ── Cache ──────────────────────────────────────────────────
REDIS_URL=rediss://default:[token]@[host].upstash.io:6379

# ── Auth ───────────────────────────────────────────────────
JWT_SECRET=[string aleatória 64 chars]
JWT_REFRESH_SECRET=[string aleatória 64 chars]

# ── Firebase ───────────────────────────────────────────────
FIREBASE_PROJECT_ID=meu-personal-ai
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@meu-personal-ai.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# ── IA ─────────────────────────────────────────────────────
LLM_API_KEY=sk-ant-api03-xxxx

# ── Storage ────────────────────────────────────────────────
R2_ACCOUNT_ID=xxxx
R2_ACCESS_KEY_ID=xxxx
R2_SECRET_ACCESS_KEY=xxxx
R2_BUCKET_NAME=meu-personal-ai-photos
R2_PUBLIC_URL=https://pub.meupersonalai.com.br

# ── Pagamentos ─────────────────────────────────────────────
STRIPE_SECRET_KEY=sk_live_xxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxx
STRIPE_PRICE_PRO_MONTHLY=price_xxxx
STRIPE_PRICE_PRO_ANNUAL=price_xxxx
STRIPE_PRICE_ELITE_MONTHLY=price_xxxx
STRIPE_PRICE_ELITE_ANNUAL=price_xxxx
REVENUECAT_WEBHOOK_SECRET=xxxx

# ── App ────────────────────────────────────────────────────
APP_DEEP_LINK_BASE=meupersonalai://
NODE_ENV=production
PORT=3000
```

---

## 10. Checklist final antes do launch público

- [ ] Smoke tests passando em produção (`/health`, `/health/db`, `/health/redis`)
- [ ] 127 exercícios no banco de produção (`GET /exercises` retorna a lista)
- [ ] Fluxo de cadastro + anamnese + primeiro treino funcionando
- [ ] Compra RevenueCat sandbox funcionando (iOS + Android)
- [ ] Webhook Stripe recebendo e processando eventos
- [ ] Notificações push chegando no device físico
- [ ] App Store — status "Ready for Sale"
- [ ] Google Play — status "Published"
- [ ] Privacy Policy e Terms hospedados em URL pública
- [ ] Domínio configurado com SSL válido
- [ ] Painel admin acessível e exibindo métricas reais
- [ ] Uptime monitor configurado (Uptime Robot ou similar)
- [ ] Backup automático do banco ativado no Supabase
- [ ] Rate limiting testado (não deixa abusar da API de IA)
