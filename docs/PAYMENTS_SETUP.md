# Guia de configuração: RevenueCat + Stripe
## Meu Personal AI — Pagamentos

Tempo estimado: **2-3 horas** para configurar tudo do zero.

---

## 1. Stripe

### 1.1 Criar conta
1. Acesse https://dashboard.stripe.com/register
2. Complete a verificação da empresa (CNPJ, conta bancária brasileira)
3. Habilite o **modo teste** para desenvolvimento

### 1.2 Criar os produtos
No Stripe Dashboard → **Produtos** → **Adicionar produto**:

| Produto      | Preço mensal | Preço anual | Identificador sugerido               |
|-------------|--------------|-------------|---------------------------------------|
| Pro         | R$39,00      | R$348,00    | `prod_pro`                            |
| Elite       | R$89,00      | R$828,00    | `prod_elite`                          |

Para cada produto, copie o **Price ID** (começa com `price_`) e adicione ao `.env`:

```env
STRIPE_PRICE_PRO_MONTHLY=price_xxxx
STRIPE_PRICE_PRO_ANNUAL=price_xxxx
STRIPE_PRICE_ELITE_MONTHLY=price_xxxx
STRIPE_PRICE_ELITE_ANNUAL=price_xxxx
```

### 1.3 Configurar webhook
1. Stripe Dashboard → **Desenvolvedores** → **Webhooks** → **Adicionar endpoint**
2. URL: `https://api.meupersonalai.com.br/webhooks/stripe`
3. Eventos a escutar:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
4. Copie o **Signing Secret** (começa com `whsec_`):

```env
STRIPE_WEBHOOK_SECRET=whsec_xxxx
```

### 1.4 Portal do cliente (para gerenciar assinatura)
1. Stripe Dashboard → **Configurações** → **Portal do cliente**
2. Ative "Permitir cancelamento"
3. Ative "Permitir atualização de método de pagamento"
4. URL de retorno: `meupersonalai://profile` (deep link do app)

### 1.5 Variáveis finais do Stripe
```env
STRIPE_SECRET_KEY=sk_live_xxxx        # sk_test_xxxx em desenvolvimento
STRIPE_PUBLISHABLE_KEY=pk_live_xxxx   # para o frontend, se necessário
STRIPE_WEBHOOK_SECRET=whsec_xxxx
STRIPE_PRICE_PRO_MONTHLY=price_xxxx
STRIPE_PRICE_PRO_ANNUAL=price_xxxx
STRIPE_PRICE_ELITE_MONTHLY=price_xxxx
STRIPE_PRICE_ELITE_ANNUAL=price_xxxx
```

---

## 2. RevenueCat

### 2.1 Criar conta
1. Acesse https://app.revenuecat.com/signup
2. Crie um projeto chamado `meu-personal-ai`

### 2.2 Configurar apps
Em **Project Settings** → **Apps**, adicione:

**iOS App:**
- Platform: App Store
- App Bundle ID: `br.com.meupersonalai` (ou o seu)
- Shared Secret: gerado no App Store Connect (ver seção 3)

**Android App:**
- Platform: Google Play
- Package Name: `br.com.meupersonalai`
- Service Credentials JSON: gerado no Google Play Console (ver seção 4)

### 2.3 Criar entitlements
Em **Entitlements** → **New**:
- `pro` — descrição: "Acesso ao plano Pro"
- `elite` — descrição: "Acesso ao plano Elite"

### 2.4 Criar produtos
Em **Products** → **New**:

| Product ID                              | Store    | Entitlement |
|-----------------------------------------|----------|-------------|
| `com.meupersonalai.pro.monthly`         | iOS + Android | `pro` |
| `com.meupersonalai.pro.annual`          | iOS + Android | `pro` |
| `com.meupersonalai.elite.monthly`       | iOS + Android | `elite` |
| `com.meupersonalai.elite.annual`        | iOS + Android | `elite` |

### 2.5 Criar offering
Em **Offerings** → **New** → nome: `default`

Adicione os packages:
- `$rc_monthly` → produto Pro Mensal
- `$rc_annual`  → produto Pro Anual
- Package custom `elite_monthly` → produto Elite Mensal

### 2.6 Configurar webhook para o backend
Em **Project Settings** → **Integrations** → **Webhooks**:
- URL: `https://api.meupersonalai.com.br/webhooks/revenuecat`
- Authorization header: `Bearer SEU_SEGREDO_AQUI`

```env
REVENUECAT_WEBHOOK_SECRET=seu_segredo_forte_aqui
```

### 2.7 Chaves da API
Em **Project Settings** → **API Keys**:

```env
REVENUECAT_API_KEY_IOS=appl_xxxx      # para o Flutter
REVENUECAT_API_KEY_ANDROID=goog_xxxx  # para o Flutter
```

---

## 3. App Store Connect (iOS)

### 3.1 Criar app
1. https://appstoreconnect.apple.com → **Apps** → **+**
2. Plataforma: iOS
3. Nome: Meu Personal AI
4. Bundle ID: `br.com.meupersonalai` (criar em Certificates, IDs & Profiles)
5. SKU: `meu-personal-ai`

### 3.2 Criar In-App Purchases
Em **App** → **Features** → **In-App Purchases** → **+**:

| Tipo               | Product ID                          | Preço    |
|--------------------|-------------------------------------|----------|
| Auto-renovável     | `com.meupersonalai.pro.monthly`     | R$39,90  |
| Auto-renovável     | `com.meupersonalai.pro.annual`      | R$348,90 |
| Auto-renovável     | `com.meupersonalai.elite.monthly`   | R$89,90  |
| Auto-renovável     | `com.meupersonalai.elite.annual`    | R$828,90 |

**Importante:** Use preços com `.90` centavos — a Apple exige preços da tabela pré-aprovada.

### 3.3 Shared Secret para RevenueCat
Em **Users and Access** → **Shared Secret** → **Generate** → copiar para RevenueCat.

### 3.4 Sandbox para testes
Em **Users and Access** → **Sandbox Testers** → criar conta de teste.

---

## 4. Google Play Console (Android)

### 4.1 Criar app
1. https://play.google.com/console → **Criar app**
2. Tipo: App | Gratuito | Não é para crianças

### 4.2 Criar assinaturas
Em **Monetização** → **Assinaturas** → **Criar assinatura**:

Mesmos Product IDs da tabela acima, com preços equivalentes em BRL.

### 4.3 Service Account para RevenueCat
1. Acesse https://console.cloud.google.com
2. Crie um Service Account com permissão `Android Publisher`
3. Gere uma chave JSON
4. No Google Play Console → **Configuração** → **Contas de serviço** → vincular
5. Envie o JSON para o RevenueCat

---

## 5. Variáveis de ambiente completas

Arquivo `.env` do backend (Fly.io → Secrets):

```env
# Banco
DATABASE_URL=postgresql://user:pass@host:5432/db

# Auth
JWT_SECRET=string_aleatoria_64_chars
JWT_REFRESH_SECRET=outra_string_aleatoria_64_chars

# Firebase
FIREBASE_PROJECT_ID=meu-personal-ai
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@xxx.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"

# Anthropic
LLM_API_KEY=sk-ant-xxxx

# Cloudflare R2
R2_ACCOUNT_ID=xxxx
R2_ACCESS_KEY_ID=xxxx
R2_SECRET_ACCESS_KEY=xxxx
R2_BUCKET_NAME=meu-personal-ai-photos
R2_PUBLIC_URL=https://pub.meupersonalai.com.br

# Redis (Upstash)
REDIS_URL=rediss://default:xxxx@xxxx.upstash.io:6379

# ── PAGAMENTOS ──────────────────────────
STRIPE_SECRET_KEY=sk_live_xxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxx
STRIPE_PRICE_PRO_MONTHLY=price_xxxx
STRIPE_PRICE_PRO_ANNUAL=price_xxxx
STRIPE_PRICE_ELITE_MONTHLY=price_xxxx
STRIPE_PRICE_ELITE_ANNUAL=price_xxxx
REVENUECAT_WEBHOOK_SECRET=xxxx

# App
APP_DEEP_LINK_BASE=meupersonalai://
PORT=3000
NODE_ENV=production
```

Variáveis do Flutter (via `--dart-define` no build):

```bash
flutter build ios \
  --dart-define=REVENUECAT_API_KEY_IOS=appl_xxxx

flutter build apk \
  --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxxx
```

---

## 6. Testando localmente

### 6.1 Stripe (webhook local)
```bash
# Instalar Stripe CLI
brew install stripe/stripe-cli/stripe

# Login
stripe login

# Redirecionar webhooks para localhost
stripe listen --forward-to localhost:3000/webhooks/stripe
```

### 6.2 RevenueCat (sandbox iOS)
1. No device físico ou simulador
2. Usar a conta de Sandbox Tester criada na App Store
3. As compras são gratuitas no sandbox

### 6.3 Fluxo de teste completo
1. Abrir o app como usuário Free
2. Tentar acessar Analytics → FeatureGate abre PaywallSheet
3. Tocar "Iniciar 7 dias grátis" → RevenueCat processa
4. Webhook RevenueCat → backend → plan atualizado para 'pro'
5. App atualiza em tempo real via `customerInfoStream`
6. Analytics desbloqueado ✅

---

## 7. Checklist final antes do launch

- [ ] Produtos criados na App Store Connect e Google Play
- [ ] Entitlements e offerings configurados no RevenueCat
- [ ] Webhooks de ambos apontando para a URL de produção
- [ ] `stripe listen` substituído pelo webhook real
- [ ] Testar compra completa no sandbox (iOS + Android)
- [ ] Testar restauração de compras
- [ ] Testar cancelamento e downgrade automático
- [ ] Testar expiração do trial (pode usar período curto no sandbox)
- [ ] Portal Stripe funcionando (gerenciar assinatura)
- [ ] Variáveis de ambiente configuradas no Fly.io
