/// ════════════════════════════════════════════════════════════
/// app_config.dart
/// Fonte única de verdade para branding, URLs e configurações.
/// Para renomear o app ou trocar de marca: edite APENAS este arquivo.
/// ════════════════════════════════════════════════════════════

class AppConfig {
  AppConfig._();

  // ── Identidade ─────────────────────────────────────────────
  static const appName      = 'Meu Personal AI';
  static const appNameShort = 'Personal AI';
  static const appInitials  = 'MP';
  static const appTagline   = 'Seu personal trainer com inteligência artificial';
  static const appVersion   = '1.0.0';

  // ── Bundle IDs ─────────────────────────────────────────────
  static const bundleIdIos     = 'br.com.meupersonalai';
  static const bundleIdAndroid = 'br.com.meupersonalai';

  // ── URLs ────────────────────────────────────────────────────
  static const apiBaseUrl    = String.fromEnvironment(
    'API_BASE_URL', defaultValue: 'http://localhost:3000',
  );
  static const websiteUrl      = 'https://meupersonalai.com.br';
  static const privacyPolicyUrl= 'https://meupersonalai.com.br/privacidade';
  static const termsUrl        = 'https://meupersonalai.com.br/termos';
  static const supportEmail    = 'suporte@meupersonalai.com.br';
  static const privacyEmail    = 'privacidade@meupersonalai.com.br';

  // ── Deep Links ──────────────────────────────────────────────
  static const deepLinkScheme  = 'meupersonalai';
  static const deepLinkBase    = 'meupersonalai://';

  // ── Planos ──────────────────────────────────────────────────
  static const proPriceMonthly = 'R\$39';
  static const proPriceAnnual  = 'R\$29';   // por mês no anual
  static const elitePriceMonthly = 'R\$89';
  static const elitePriceAnnual  = 'R\$69'; // por mês no anual
  static const trialDays       = 7;

  // ── Limites do plano Free ───────────────────────────────────
  static const freeAiMessagesPerDay  = 5;
  static const freeMaxPrograms       = 1;

  // ── Cores (sync com app_theme.dart) ────────────────────────
  static const brandPrimaryHex = 'FF6B1A'; // laranja
  static const brandBlackHex   = '111111';

  // ── Redes sociais ───────────────────────────────────────────
  static const instagramUrl = 'https://instagram.com/meupersonalai';
  static const tiktokUrl    = 'https://tiktok.com/@meupersonalai';

  // ── Feature flags ───────────────────────────────────────────
  // Ativar/desativar features sem deploy — altere aqui
  static const enableSocialFeatures  = true;
  static const enableExpressWorkout  = true;
  static const enableHealthSync      = true;
  static const enablePhotoProgress   = true;
  static const enableDarkMode        = true;

  // ── Analytics ───────────────────────────────────────────────
  static const analyticsEnabled = true;
  static const analyticsBatchSize = 20;
  static const analyticsBatchIntervalSeconds = 30;

  // ── Configurações de IA ─────────────────────────────────────
  static const aiCoachName          = 'Alex';   // nome padrão do coach
  static const aiMaxContextMessages = 20;       // msgs no contexto do chat
  static const aiStreamingEnabled   = true;

  // ── Notificações ────────────────────────────────────────────
  static const notifReengagementDays = 2;   // dias inativo → push
  static const notifMaxPerDay        = 3;   // máximo por usuário/dia
  static const notifStreakMilestones = [7, 14, 30, 60, 90]; // dias

  // ── Cache ────────────────────────────────────────────────────
  static const exerciseCacheTtlHours = 24;
  static const profileCacheTtlMinutes = 5;
}
