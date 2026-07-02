# Contribuindo com o Meu Personal AI

Obrigado pelo interesse em contribuir! Este guia cobre tudo que você precisa para começar.

---

## Antes de começar

- Leia o [README.md](./README.md) para entender a stack e a estrutura
- Verifique as [issues abertas](../../issues) — pode haver algo em andamento
- Para mudanças grandes, abra uma issue primeiro para discutir a abordagem

---

## Ambiente de desenvolvimento

### Requisitos

```
Flutter  >= 3.22.0
Dart     >= 3.3.0
Node.js  >= 20.0.0
Docker   >= 24.0 (opcional)
```

### Setup rápido

```bash
# 1. Clone
git clone https://github.com/seu-org/meu-personal-ai.git
cd meu-personal-ai

# 2. Backend
cd backend
cp .env.example .env
# Preencher .env com credenciais de desenvolvimento
npm install
npm run start:dev

# 3. Mobile (em outro terminal)
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

---

## Fluxo de trabalho

### Branches

```
main          → produção (protegida, requer PR aprovado)
develop       → integração de features
feature/xxx   → nova funcionalidade
fix/xxx       → correção de bug
chore/xxx     → ajustes sem impacto no produto
```

### Criando uma feature

```bash
# 1. Sempre partir de develop atualizado
git checkout develop
git pull origin develop

# 2. Criar branch
git checkout -b feature/nome-da-feature

# 3. Desenvolver com commits pequenos e descritivos
git commit -m "feat(coach): adicionar animação de piscada no avatar"

# 4. Rodar testes antes de abrir PR
cd mobile && flutter test
cd backend && npm test

# 5. Push e abrir PR para develop
git push origin feature/nome-da-feature
```

### Convenção de commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope):  nova funcionalidade
fix(scope):   correção de bug
chore(scope): manutenção sem impacto no produto
test(scope):  adicionar ou corrigir testes
docs(scope):  documentação
style(scope): formatação, sem mudança de lógica
refactor:     refatoração sem bug fix ou feature
perf:         melhoria de performance
```

Exemplos:
```
feat(workout): adicionar modo de pausa durante execução
fix(auth): corrigir refresh token expirado silenciosamente
chore(deps): atualizar purchases_flutter para 7.6.0
test(health): adicionar testes para mapWorkoutType
```

---

## Padrões de código

### Flutter / Dart

**Estrutura de feature:**
```
lib/features/nome_da_feature/
├── data/
│   ├── nome_repository.dart    # acesso a dados (API + cache)
│   └── nome_provider.dart      # providers Riverpod
├── domain/
│   └── models.dart             # modelos de dados
└── presentation/
    ├── nome_screen.dart         # tela principal
    └── widgets/                 # widgets específicos da feature
```

**Regras:**
- Use `context.cardColor`, `context.textColor` etc. — nunca `Colors.white` hardcoded
- Providers sempre via Riverpod — sem `setState` em ConsumerWidget
- Erros de rede: sempre mostrar estado de erro com botão de retry
- Loading: sempre mostrar skeleton ou `CircularProgressIndicator`
- Strings de UI: sempre em português brasileiro

**Nomenclatura:**
```dart
// Providers — sufixo Provider
final userProfileProvider = FutureProvider<UserProfile>(...);

// Notifiers — sufixo Notifier
class WorkoutNotifier extends AsyncNotifier<WorkoutState> { ... }

// Screens — sufixo Screen
class HomeScreen extends ConsumerWidget { ... }

// Widgets reutilizáveis — sem sufixo específico
class StepsCard extends ConsumerWidget { ... }
```

### NestJS / TypeScript

**Estrutura de módulo:**
```
src/nome-do-modulo/
├── nome.controller.ts
├── nome.service.ts
├── nome.module.ts
├── nome.entity.ts          # entidade TypeORM
└── dto/
    ├── create-nome.dto.ts
    └── update-nome.dto.ts
```

**Regras:**
- Toda rota autenticada usa `@UseGuards(JwtAuthGuard)`
- Features Pro/Elite usam `@RequireFeature('nome_feature')`
- Nunca expor dados de outros usuários — sempre filtrar por `userId`
- Logs via `Logger` do NestJS — nunca `console.log` em produção
- Erros esperados: `throw new BadRequestException('mensagem descritiva')`

---

## Testes

### Flutter

```bash
# Rodar todos
flutter test

# Com cobertura
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Watch mode (requer flutter_test_watch)
flutter test --watch
```

**Requisito mínimo:** todo PR deve manter cobertura acima de 60% nos módulos alterados.

**O que testar:**
- `fromJson` / `toJson` de todos os modelos
- Lógica de negócio nos providers (não a UI)
- Widget tests para estados críticos: loading, erro, vazio, com dados
- Integração para fluxos completos (anamnese, treino, pagamento)

### Backend

```bash
# Unit tests
npm test

# Watch
npm run test:watch

# E2E (requer banco de teste)
npm run test:e2e

# Cobertura
npm run test:cov
```

---

## Abrindo um Pull Request

### Checklist

- [ ] Testes passando (`flutter test` + `npm test`)
- [ ] Nenhuma cor hardcoded — usando `context.cardColor` etc.
- [ ] Sem `console.log` no backend
- [ ] PR title segue Conventional Commits
- [ ] Descrição explica **o que** e **por que** (não apenas o como)
- [ ] Screenshot ou vídeo se houver mudança visual

### Template de descrição

```markdown
## O que foi feito
Breve descrição da mudança.

## Por que
Contexto e motivação.

## Como testar
1. ...
2. ...

## Screenshots (se aplicável)
```

---

## Dúvidas

Abra uma issue com a label `question` ou entre em contato por
`dev@meupersonalai.com.br`.
