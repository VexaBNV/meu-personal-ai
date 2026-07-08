# Como enviar o projeto para o GitHub

## Passo 1 — Criar conta no GitHub (se não tiver)
Acesse https://github.com e crie uma conta gratuita.

## Passo 2 — Criar o repositório no GitHub

1. Clique no botão **+** no canto superior direito → **New repository**
2. Preencha:
   - **Repository name:** `meu-personal-ai`
   - **Description:** Personal trainer com inteligência artificial
   - **Visibility:** Private (recomendado — o código tem valor comercial)
   - Deixe **todas as outras opções desmarcadas** (sem README, sem .gitignore)
3. Clique em **Create repository**
4. Copie a URL que aparece — será algo como:
   `https://github.com/seu-usuario/meu-personal-ai.git`

## Passo 3 — Instalar o Git no seu computador

**Windows:**
Baixe em https://git-scm.com/download/win e instale com as opções padrão.
Após instalar, abra o **Git Bash** (aparece no menu iniciar).

**Mac:**
```bash
brew install git
```

## Passo 4 — Configurar o Git (só precisa fazer uma vez)

Abra o Git Bash (Windows) ou Terminal (Mac) e rode:

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"
```

Use o mesmo e-mail da sua conta GitHub.

## Passo 5 — Copiar os arquivos do projeto para uma pasta

Crie uma pasta chamada `meu-personal-ai` no seu computador e coloque
todos os arquivos baixados desta conversa dentro dela, respeitando
a estrutura de pastas:

```
meu-personal-ai/
├── .gitignore
├── .github/
├── README.md
├── CONTRIBUTING.md
├── docker-compose.yml
├── backend/
├── mobile/
├── docs/
└── web/
```

## Passo 6 — Inicializar e enviar o repositório

Abra o Git Bash dentro da pasta `meu-personal-ai` e rode os comandos
**um por um**:

```bash
# Inicializa o Git na pasta
git init

# Configura a branch principal como 'main'
git branch -M main

# Conecta com o repositório do GitHub
# (substitua pela URL copiada no Passo 2)
git remote add origin https://github.com/seu-usuario/meu-personal-ai.git

# Adiciona todos os arquivos
git add .

# Verifica o que será enviado (opcional mas recomendado)
git status

# Cria o primeiro commit
git commit -m "feat: initial commit — Meu Personal AI v1.0.0"

# Envia para o GitHub
git push -u origin main
```

O GitHub vai pedir seu usuário e senha.
**Atenção:** a senha não é a senha da sua conta — é um **Personal Access Token**.

## Passo 7 — Criar um Personal Access Token

O GitHub não aceita senha comum para push. Você precisa de um token:

1. No GitHub, clique na sua foto → **Settings**
2. Role até o final → **Developer settings**
3. **Personal access tokens** → **Tokens (classic)** → **Generate new token**
4. Em **Note:** escreva `meu-personal-ai-push`
5. Em **Expiration:** escolha **No expiration**
6. Em **Select scopes:** marque apenas **repo**
7. Clique em **Generate token**
8. **Copie o token agora** — ele só aparece uma vez
9. Quando o Git pedir a senha, cole o token no lugar da senha

## Passo 8 — Verificar o resultado

Acesse `https://github.com/seu-usuario/meu-personal-ai` no navegador.
Você deve ver todos os arquivos listados.

---

## Configurar os Secrets para o CI/CD (GitHub Actions)

Para o deploy automático funcionar (Fly.io + Play Store), você precisa
registrar as chaves secretas no GitHub:

1. No repositório, clique em **Settings** → **Secrets and variables** → **Actions**
2. Clique em **New repository secret** para cada item abaixo:

| Secret | Onde obter |
|--------|-----------|
| `FLY_API_TOKEN` | `flyctl auth token` no terminal após instalar Fly CLI |
| `API_BASE_URL` | `https://api.meupersonalai.com.br` |
| `REVENUECAT_API_KEY_ANDROID` | app.revenuecat.com → Project → API Keys |
| `GOOGLE_PLAY_JSON_KEY` | Google Play Console → Setup → API access → JSON key |

---

## Branches recomendadas

Após o push inicial, crie a branch de desenvolvimento:

```bash
git checkout -b develop
git push -u origin develop
```

A partir daí, o fluxo é:
- Desenvolvimento → branch `feature/nome`
- Merge para `develop` via Pull Request
- Merge de `develop` para `main` gera deploy automático
