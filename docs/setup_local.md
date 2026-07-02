# Guia de Setup Local — Meu Personal AI
### Do zero até o app rodando no seu celular

> Tempo estimado: **2–3 horas** na primeira vez  
> Pré-requisito: Mac (para testar iOS) ou qualquer sistema (para testar Android)

---

## Visão geral do que você vai fazer

```
Seu celular
    ↕ (USB ou Wi-Fi)
Seu computador
    ├── App Flutter (roda no celular via flutter run)
    └── Backend NestJS (roda no Docker, porta 3000)
            ├── PostgreSQL (Docker)
            └── Redis (Docker)
```

Os únicos serviços externos necessários para testar são:
- **Firebase** — autenticação (conta gratuita)
- **Anthropic** — IA do coach (paga, ~R$0,10 por conversa de teste)

Todos os outros (Stripe, RevenueCat, R2, Supabase) são opcionais para testar as funcionalidades principais.

---

## PARTE 1 — Preparar o computador

### 1.1 Instalar dependências do sistema

**macOS:**
```bash
# Instala o Homebrew (se não tiver)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instala Node.js 20
brew install node@20
echo 'export PATH="/opt/homebrew/opt/node@20/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Instala Docker Desktop
# Baixe em: https://www.docker.com/products/docker-desktop/
# (abra o .dmg e arraste para Applications)

# Instala Flutter
brew install --cask flutter

# Instala Xcode (para iOS) — pelo Mac App Store
# Depois de instalar, rode:
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

**Windows/Linux (somente Android):**
```bash
# Node.js 20 — https://nodejs.org/en/download
# Docker Desktop — https://www.docker.com/products/docker-desktop/
# Flutter — https://docs.flutter.dev/get-started/install
```

**Verifica instalações:**
```bash
node --version      # deve mostrar v20.x.x
docker --version    # deve mostrar Docker version 24+
flutter --version   # deve mostrar Flutter 3.22+
flutter doctor      # lista o que ainda falta instalar
```

### 1.2 Instalar Android Studio (para Android)

1. Baixe em: https://developer.android.com/studio
2. Durante a instalação, marque **Android SDK** e **Android Virtual Device**
3. Após instalar, abra o Android Studio → More Actions → SDK Manager
4. Em **SDK Platforms**, marque Android 14 (API 34)
5. Em **SDK Tools**, marque **Android SDK Build-Tools** e **Android Emulator**

Crie um emulador:
- More Actions → Virtual Device Manager → Create Device
- Escolha **Pixel 8** → Next → **API 34** → Finish

---

## PARTE 2 — Baixar o código

```bash
# Clone o repositório (substitua pela URL real do seu repo)
git clone https://github.com/seu-usuario/meu-personal-ai.git
cd meu-personal-ai

# Estrutura esperada após clonar:
# meu-personal-ai/
# ├── backend/          ← código NestJS
# ├── mobile/           ← código Flutter
# └── ...
```

Se você ainda não tem um repositório Git, crie a estrutura manualmente juntando todos os arquivos entregues nas sessões anteriores. A estrutura está documentada no `README.md`.

---

## PARTE 3 — Configurar o Firebase (obrigatório)

O Firebase é necessário para o login funcionar.

### 3.1 Criar projeto Firebase

1. Acesse https://console.firebase.google.com
2. Clique em **Adicionar projeto** → nome: `meu-personal-ai-dev`
3. Desative o Google Analytics (não precisa para dev) → **Criar projeto**

### 3.2 Ativar autenticação

1. No painel do Firebase, clique em **Authentication** → **Começar**
2. Aba **Sign-in method** → ative **E-mail/senha** → Salvar
3. (Opcional) Ative **Google** se quiser testar login social

### 3.3 Adicionar o app Android

1. No Firebase, clique no ícone Android (`</>`)
2. **Nome do pacote Android:** `br.com.meupersonalai`
3. Clique em **Registrar app**
4. Baixe o arquivo `google-services.json`
5. Coloque em `mobile/android/app/google-services.json`

### 3.4 Adicionar o app iOS (somente Mac)

1. No Firebase, clique em **Adicionar app** → ícone iOS
2. **Bundle ID:** `br.com.meupersonalai`
3. Baixe o arquivo `GoogleService-Info.plist`
4. Abra o Xcode: `open mobile/ios/Runner.xcworkspace`
5. Na árvore de arquivos, arraste o `GoogleService-Info.plist` para dentro da pasta `Runner`
6. Marque **Copy items if needed** → Finish

### 3.5 Gerar credenciais do servidor

1. No Firebase, clique em ⚙️ → **Configurações do projeto** → aba **Contas de serviço**
2. Clique em **Gerar nova chave privada** → confirme
3. Salve o arquivo JSON baixado — você vai precisar dos valores dele para o `.env`

---

## PARTE 4 — Configurar o backend

### 4.1 Criar o arquivo .env

```bash
cd backend
cp ../.env.example .env
```

Abra o `.env` e preencha os campos obrigatórios para desenvolvimento local:

```env
# Estes são os únicos campos obrigatórios para testar localmente:

NODE_ENV=development
PORT=3000

# Banco local (Docker — não precisa mudar)
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/meupersonalai

# Redis local (Docker — não precisa mudar)
REDIS_URL=redis://localhost:6379

# Gere com: openssl rand -hex 64
JWT_SECRET=cole_aqui_resultado_do_openssl
JWT_REFRESH_SECRET=cole_aqui_outro_resultado_do_openssl

# Firebase — do arquivo JSON baixado na etapa 3.5
FIREBASE_PROJECT_ID=meu-personal-ai-dev
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@meu-personal-ai-dev.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nXXXXX\n-----END PRIVATE KEY-----\n"

# Anthropic — console.anthropic.com → API Keys
LLM_API_KEY=sk-ant-api03-xxxxxxxx

# Stripe — deixe valores fake para não travar o boot
STRIPE_SECRET_KEY=sk_test_fake_para_desenvolvimento
STRIPE_WEBHOOK_SECRET=whsec_fake_para_desenvolvimento

# R2 — deixe vazio (upload de foto não vai funcionar, mas o resto sim)
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=meu-personal-ai-dev
R2_PUBLIC_URL=http://localhost:3000/placeholder
```

### 4.2 Subir o banco e o Redis com Docker

```bash
# Na pasta backend (ou raiz do projeto, onde está o docker-compose.yml)
docker compose up -d postgres redis

# Verifica se estão rodando:
docker compose ps
# Deve mostrar postgres e redis com status "healthy"
```

### 4.3 Rodar as migrations

```bash
cd backend
npm install
npm run migration:run

# Verifica se funcionou (deve listar as tabelas):
docker compose exec postgres psql -U postgres -d meupersonalai -c "\dt"
```

### 4.4 Popular o banco com exercícios

```bash
# Isso chama a API da Anthropic para gerar os 127 exercícios
# Leva ~3 minutos e vai usar ~R$0,50 de crédito
npx ts-node scripts/generate-exercise-bank.ts

# Se quiser pular por agora, pode importar um seed rápido:
# (o script vai criar versões simplificadas dos exercícios)
```

### 4.5 Rodar o backend

```bash
npm run start:dev

# Deve aparecer:
# [NestJS] Application is running on: http://localhost:3000
# [NestJS] Health: http://localhost:3000/health

# Teste se está funcionando:
curl http://localhost:3000/health
# Deve retornar: {"status":"ok"}
```

---

## PARTE 5 — Configurar o app Flutter

### 5.1 Instalar dependências

```bash
cd mobile
flutter pub get
```

### 5.2 Configurar a URL da API

O app precisa saber onde o backend está. No desenvolvimento, o backend está no seu computador — mas o celular não consegue acessar `localhost` diretamente.

**Para Android (emulador):**
- O emulador usa `10.0.2.2` para acessar o host
- A URL da API será: `http://10.0.2.2:3000`

**Para Android (celular físico via USB):**
- Descubra o IP do seu computador: `ifconfig | grep "inet "` (Mac/Linux) ou `ipconfig` (Windows)
- A URL da API será: `http://192.168.X.X:3000` (IP da sua rede local)

**Para iOS (simulador):**
- O simulador pode usar `localhost` normalmente
- A URL da API será: `http://localhost:3000`

**Para iOS (celular físico via USB):**
- Use o IP da sua rede local, igual ao Android físico

### 5.3 Rodar o app

```bash
# Lista os dispositivos disponíveis
flutter devices

# Exemplo de saída:
# emulator-5554  • Android SDK (API 34)
# iPhone 15 Pro  • iOS 17.4 (simulador)
# SM-G991B       • Android 13 (celular físico)

# Roda no emulador Android:
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  -d emulator-5554

# Roda no simulador iOS:
flutter run \
  --dart-define=API_BASE_URL=http://localhost:3000 \
  -d "iPhone 15 Pro"

# Roda no celular físico (substitua o IP):
flutter run \
  --dart-define=API_BASE_URL=http://192.168.1.100:3000 \
  -d SM-G991B
```

---

## PARTE 6 — Conectar o celular físico

### Android físico

1. No celular: **Configurações** → **Sobre o telefone** → toque 7x em **Número da versão** (ativa o modo desenvolvedor)
2. Volte: **Configurações** → **Opções do desenvolvedor** → ative **Depuração USB**
3. Conecte o cabo USB — aparecerá um popup no celular pedindo permissão → **Permitir**
4. Verifique: `flutter devices` deve listar o seu celular

### iPhone físico

1. Conecte o cabo USB
2. No iPhone: toque em **Confiar** quando aparecer o popup
3. No Xcode: abra `mobile/ios/Runner.xcworkspace`
4. Selecione seu iPhone no seletor de dispositivos (canto superior esquerdo)
5. Em **Signing & Capabilities**: selecione seu **Team** (sua conta Apple ID pessoal funciona)
6. Clique no botão ▶ para fazer um build de teste pelo Xcode primeiro
7. No iPhone: **Configurações** → **Geral** → **VPN e Gerenciamento de Dispositivo** → confie no certificado
8. Agora `flutter run` vai funcionar normalmente

---

## PARTE 7 — Verificar se está tudo funcionando

Com o backend rodando e o app aberto no celular:

**Fluxo de teste básico:**

1. ✅ Tela de login aparece → crie uma conta com e-mail e senha
2. ✅ Onboarding abre → preencha os 6 passos da anamnese
3. ✅ Tela de loading "gerando seu programa..." aparece (~30 segundos)
4. ✅ Home com o treino do dia aparece
5. ✅ Toque em "Iniciar treino" → tela de execução abre
6. ✅ Coach responde no chat

**Se algo não funcionar:**

```bash
# Ver logs do backend em tempo real
# (na pasta backend, com o servidor rodando)
# Os logs aparecem direto no terminal onde você rodou npm run start:dev

# Ver logs do Flutter
# (aparecem no terminal onde você rodou flutter run)
# Pressione 'r' para hot reload, 'R' para hot restart, 'q' para sair

# Verificar se o banco está acessível
curl http://localhost:3000/health/db
# Deve retornar: {"status":"ok","database":"connected"}

# Verificar se o Redis está acessível
curl http://localhost:3000/health/redis
# Deve retornar: {"status":"ok","redis":"connected"}
```

---

## PARTE 8 — O que NÃO vai funcionar sem configuração extra

| Funcionalidade | Motivo | O que fazer |
|---|---|---|
| Upload de foto de perfil | R2 não configurado | Crie conta Cloudflare → preencha R2_* no .env |
| Fotos de progresso | R2 não configurado | Idem |
| Assinatura Pro/Elite | RevenueCat + Stripe | Etapa final antes de publicar |
| Apple Health / Google Fit | Requer device físico e permissão real | Funciona em celular físico, não em emulador |
| Push notifications | Requer FCM configurado no device | Funciona em celular físico com Firebase configurado |
| Login com Google | Requer SHA-1 do app registrado no Firebase | Veja abaixo |

**Para ativar login com Google no Android físico:**
```bash
# Gere o SHA-1 do seu certificado de debug
cd mobile/android
./gradlew signingReport

# Copie o SHA-1 e adicione no Firebase:
# Console Firebase → Configurações do projeto → Seu app Android → Adicionar impressão digital
```

---

## Resumo — checklist de 15 minutos

```
□ Docker Desktop instalado e rodando
□ Flutter instalado (flutter doctor sem erros críticos)
□ Projeto clonado
□ Firebase criado + google-services.json e GoogleService-Info.plist no lugar
□ backend/.env preenchido com JWT secrets + Firebase + Anthropic
□ docker compose up -d postgres redis
□ cd backend && npm install && npm run migration:run
□ npm run start:dev (backend rodando na porta 3000)
□ cd mobile && flutter pub get
□ flutter run --dart-define=API_BASE_URL=http://[IP]:3000
□ Criar conta no app → preencher onboarding → ver treino gerado
```

---

## Problemas comuns

**"Connection refused" no app:**
- O backend não está rodando, ou a URL da API está errada
- Verifique o IP: celular físico não pode usar `localhost`

**"Firebase: auth/invalid-api-key":**
- O `google-services.json` está no lugar errado ou é do projeto errado

**"Migration failed":**
- O Postgres ainda está iniciando — espere 10s e rode de novo

**"Flutter doctor shows issues":**
- Siga as instruções que o próprio `flutter doctor` mostra

**Backend trava em "Connecting to database...":**
- Verifique `docker compose ps` — o Postgres pode estar unhealthy
- `docker compose logs postgres` para ver o erro
```
