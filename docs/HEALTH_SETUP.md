# Guia de configuração: Apple Health + Google Fit
## Meu Personal AI — Health Sync

Tempo estimado: **30–45 minutos**

---

## 1. iOS — Apple HealthKit

### 1.1 Ativar HealthKit no Xcode
1. Abra `ios/Runner.xcworkspace` no Xcode
2. Selecione o target **Runner**
3. Vá em **Signing & Capabilities** → **+ Capability**
4. Adicione **HealthKit**
5. Marque as opções:
   - ✅ Health Records (se quiser suporte a dados clínicos — opcional)
   - ✅ Background Delivery (para sincronização em background)

### 1.2 Adicionar strings de permissão no Info.plist
Abra `ios/Runner/Info.plist` e adicione as chaves do arquivo `ios_permissions.plist`
entregue neste pacote.

```xml
<key>NSHealthShareUsageDescription</key>
<string>O Meu Personal AI lê seus passos e peso para exibir seu progresso diário...</string>

<key>NSHealthUpdateUsageDescription</key>
<string>O Meu Personal AI salva seus treinos e peso no Apple Health...</string>
```

> **Atenção:** A App Store **rejeita automaticamente** apps com HealthKit declarado
> que não tenham essas duas chaves. O texto será exibido no diálogo de permissão.

### 1.3 Verificar entitlements
O arquivo `ios/Runner/Runner.entitlements` deve conter:

```xml
<key>com.apple.developer.healthkit</key>
<true/>
<key>com.apple.developer.healthkit.access</key>
<array/>
```

Isso é gerado automaticamente pelo Xcode ao adicionar a capability.

### 1.4 Testar no simulador vs device físico
- **Simulador:** HealthKit funciona, mas os dados de passos são simulados. Use o app "Health" do simulador para inserir valores de teste.
- **Device físico:** preferível para testes reais. Use sua conta Apple normal (não sandbox).

---

## 2. Android — Google Health Connect

O pacote `health: ^10.2.0` usa o **Health Connect** no Android 14+
e a **Fitness API** no Android < 14. Ambos são configurados automaticamente pelo pacote.

### 2.1 Adicionar permissões no AndroidManifest.xml
Copie as permissões do arquivo `android_permissions.xml` para
`android/app/src/main/AndroidManifest.xml`, antes de `<application>`:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION"/>
<uses-permission android:name="android.permission.health.WRITE_EXERCISE"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<!-- ... demais permissões do arquivo -->
```

### 2.2 minSdkVersion
Garanta `minSdkVersion 26` no `android/app/build.gradle`.
O Health Connect exige API 26+.

### 2.3 Health Connect no dispositivo
O usuário precisa ter o app **Health Connect** instalado no dispositivo
(disponível na Play Store). Em Android 14+, ele já vem pré-instalado.

### 2.4 Google Cloud Console — Fitness API (Android < 14)
1. Acesse https://console.cloud.google.com
2. Selecione ou crie o projeto `meu-personal-ai`
3. Ative a **Fitness API**
4. Crie credenciais **OAuth 2.0 → Android**:
   - Package name: `br.com.meupersonalai`
   - SHA-1 fingerprint de debug:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - SHA-1 de produção: copiar do Google Play Console → Assinatura do app

---

## 3. Onde o código se integra

### Fluxo de autorização
```
Usuário toca "Conectar" na HealthSyncScreen
        ↓
HealthNotifier.requestPermissions()
        ↓
HealthService.requestPermissions() → diálogo nativo iOS/Android
        ↓
Se concedido: healthProvider.authorized = true
        ↓
_fetchData() busca passos e peso em background
        ↓
StepsCard aparece na HomeScreen
```

### Fluxo de treino concluído
```
WorkoutCompleteScreen._onComplete()
        ↓
completeSession() → servidor
        ↓
ref.syncWorkoutToHealth(...)  ← patch em integration_patches.dart
        ↓
HealthService.saveWorkout() → Apple Health / Google Fit
```

### Fluxo de atualização de peso
```
EditProfileScreen._save()
        ↓
PATCH /users/me/profile → servidor
        ↓
ref.syncWeightToHealth(weight)  ← patch em integration_patches.dart
        ↓
HealthService.saveWeight() → Apple Health / Google Fit
```

---

## 4. Tipos de dado suportados

| Tipo de dado       | Leitura | Escrita | Plataforma         |
|--------------------|---------|---------|-------------------|
| Passos             | ✅      | ❌      | iOS + Android     |
| Peso               | ✅      | ✅      | iOS + Android     |
| Treinos            | ❌      | ✅      | iOS + Android     |
| Calorias ativas    | ✅      | ✅      | iOS + Android     |
| Frequência cardíaca| ✅      | ❌      | iOS + Android     |

---

## 5. Checklist antes do submit na store

- [ ] HealthKit capability ativada no Xcode
- [ ] Strings `NSHealthShareUsageDescription` e `NSHealthUpdateUsageDescription` no Info.plist
- [ ] Permissões Android no AndroidManifest.xml
- [ ] `minSdkVersion` ≥ 26 no build.gradle
- [ ] Fitness API ativada no Google Cloud Console
- [ ] SHA-1 de produção registrado no Google Cloud Console
- [ ] Testar em device físico iOS e Android antes do submit
- [ ] Na submissão App Store: marcar "Uses HealthKit" e justificar o uso
