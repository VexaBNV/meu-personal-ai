# Meu Personal AI

> Seu personal trainer com inteligência artificial — iOS e Android

[![Flutter](https://img.shields.io/badge/Flutter-3.22-02569B?logo=flutter)](https://flutter.dev)
[![NestJS](https://img.shields.io/badge/NestJS-10-E0234E?logo=nestjs)](https://nestjs.com)
[![Claude](https://img.shields.io/badge/Anthropic-Claude-orange)](https://anthropic.com)
[![Tests](https://img.shields.io/badge/tests-58%2B-green)](./test)

**Meu Personal AI** é um app mobile que oferece um personal trainer com IA. O app gera programas de treino personalizados, ajusta cargas automaticamente e mantém o usuário consistente com um AI Coach disponível 24/7.

---

## Stack

| Camada | Tecnologia |
|--------|-----------|
| Mobile | Flutter 3.22 · Riverpod · GoRouter · Hive |
| Backend | NestJS 10 · TypeORM · PostgreSQL · Redis |
| IA | Anthropic Claude (Sonnet para chat, Haiku para notificações) |
| Auth | Firebase Auth + JWT (15min access / 30d refresh) |
| Storage | Cloudflare R2 (fotos de progresso) |
| Pagamentos | RevenueCat (in-app) + Stripe (web) |
| Infra | Fly.io (região GRU) · Supabase · Upstash · GitHub Actions |

---

## Estrutura do repositório

```
meu-personal-ai/
├── backend/                 # API NestJS
│   ├── src/
│   │   ├── auth/            # Firebase + JWT
│   │   ├── workout/         # Programas e execução
│   │   ├── plans/           # Planos Free/Pro/Elite
│   │   ├── payments/        # Webhooks Stripe + RevenueCat
│   │   ├── progress/        # Métricas e fotos
│   │   ├── social/          # Ranking e desafios
│   │   ├── notifications/   # FCM + Bull Queue
│   │   ├── analytics/       # Eventos e funil
│   │   ├── lgpd/            # Exportação e exclusão
│   │   ├── llm/             # Anthropic SDK
│   │   └── exercises/       # Banco de 127 exercícios
│   ├── migrations/          # SQL 001–006
│   └── scripts/             # Seed de exercícios
│
├── mobile/                  # App Flutter
│   ├── lib/
│   │   ├── core/
│   │   │   ├── config/      # app_config.dart
│   │   │   ├── theme/       # AppTheme + dark mode
│   │   │   ├── router/      # GoRouter
│   │   │   └── network/     # ApiClient (Dio)
│   │   └── features/
│   │       ├── auth/
│   │       ├── onboarding/  # Anamnese 6 passos
│   │       ├── home/
│   │       ├── workout/     # Execução + progressão
│   │       ├── coach/       # AI Chat + avatar
│   │       ├── progress/    # Gráficos + fotos
│   │       ├── social/
│   │       ├── exercises/   # Biblioteca + Express
│   │       ├── health/      # Apple Health / Google Fit
│   │       ├── payments/    # RevenueCat + Paywall
│   │       └── profile/     # Conta + LGPD
│   └── test/
│
└── docs/
    ├── PAYMENTS_SETUP.md
    ├── HEALTH_SETUP.md
    └── deploy_guide.md
```

---

## Primeiros passos

### Pré-requisitos

- Flutter 3.22+
- Node.js 20+
- Docker (opcional, para rodar o backend localmente)
- Contas: Firebase, Supabase, Upstash, Anthropic API

### Backend

```bash
cd backend

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas chaves (ver docs/deploy_guide.md)

# Rodar migrations
npm run migration:run

# Seed de exercícios
npx ts-node scripts/generate-exercise-bank.ts

# Desenvolvimento
npm run start:dev

# Produção
npm run build
npm run start:prod
```

### Mobile

```bash
cd mobile

# Instalar dependências
flutter pub get

# Desenvolvimento (emulador/device)
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  --dart-define=REVENUECAT_API_KEY_IOS=your_key

# Build iOS
flutter build ipa \
  --dart-define=API_BASE_URL=https://api.meupersonalai.com.br \
  --dart-define=REVENUECAT_API_KEY_IOS=appl_xxx

# Build Android
flutter build appbundle \
  --dart-define=API_BASE_URL=https://api.meupersonalai.com.br \
  --dart-define=REVENUECAT_API_KEY_ANDROID=goog_xxx
```

### Testes

```bash
# Flutter — todos os testes
cd mobile && flutter test

# Flutter — somente unit tests
flutter test test/unit/

# Flutter — somente widget tests
flutter test test/widget/

# Flutter — integration tests (requer device/emulador)
flutter test integration_test/

# Backend
cd backend && npm test
npm run test:e2e
npm run test:cov
```

---

## Variáveis de ambiente

Crie `backend/.env` baseado em `.env.example`. As variáveis obrigatórias são:

```env
DATABASE_URL=          # Supabase PostgreSQL
REDIS_URL=             # Upstash Redis
JWT_SECRET=            # string aleatória 64 chars
JWT_REFRESH_SECRET=    # string aleatória 64 chars
LLM_API_KEY=           # sk-ant-...
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
REVENUECAT_WEBHOOK_SECRET=
```

Ver `docs/deploy_guide.md` para instruções completas.

---

## Deploy

O deploy é feito via **Fly.io** com GitHub Actions.

```bash
# Deploy manual
cd backend && flyctl deploy

# O CI/CD executa automaticamente em push para main
# Build mobile é acionado por git tag (ex: v1.0.0)
```

Ver `docs/deploy_guide.md` para o passo a passo completo.

---

## Planos

| | Free | Pro | Elite |
|--|------|-----|-------|
| Preço | Grátis | R$39/mês | R$89/mês |
| Programas | 1 | Ilimitado | Ilimitado |
| AI Coach | 5 msgs/dia | Ilimitado | Ilimitado |
| Analytics | ❌ | ✅ | ✅ |
| Fotos progresso | ❌ | ✅ | ✅ |
| Treino express | ❌ | ✅ | ✅ |
| Perfis | 1 | 1 | Até 10 |
| Health Sync | ❌ | ❌ | ✅ |
| Painel trainer | ❌ | ❌ | ✅ |

---

## Licença

Proprietário · Todos os direitos reservados · Meu Personal AI Tecnologia Ltda.
