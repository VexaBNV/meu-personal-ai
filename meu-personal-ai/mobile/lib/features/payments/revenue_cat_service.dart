import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── IDs dos produtos (configurar no RevenueCat dashboard) ──
const kEntitlementPro   = 'pro';
const kEntitlementElite = 'elite';
const kProductProMonthly  = 'com.meupersonalai.pro.monthly';
const kProductProAnnual   = 'com.meupersonalai.pro.annual';
const kProductEliteMonthly = 'com.meupersonalai.elite.monthly';
const kProductEliteAnnual  = 'com.meupersonalai.elite.annual';

class RevenueCatService {
  static const _apiKeyIos     = String.fromEnvironment('REVENUECAT_API_KEY_IOS');
  static const _apiKeyAndroid = String.fromEnvironment('REVENUECAT_API_KEY_ANDROID');

  /// Chamar no main.dart antes de runApp
  static Future<void> init({String? userId}) async {
    await Purchases.setLogLevel(LogLevel.debug);
    final config = Platform.isIOS
        ? PurchasesConfiguration(_apiKeyIos)
        : PurchasesConfiguration(_apiKeyAndroid);
    await Purchases.configure(config);
    if (userId != null) await Purchases.logIn(userId);
  }

  /// Identifica o usuário após login (Firebase UID)
  Future<void> identify(String userId) async {
    await Purchases.logIn(userId);
  }

  /// Logout ao sair da conta
  Future<void> reset() async => Purchases.logOut();

  /// CustomerInfo atual com entitlements ativos
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  /// Verifica se tem entitlement ativo
  Future<bool> hasEntitlement(String entitlementId) async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey(entitlementId);
  }

  /// Retorna plano atual: 'free' | 'pro' | 'elite'
  Future<String> getCurrentPlan() async {
    final info = await Purchases.getCustomerInfo();
    if (info.entitlements.active.containsKey(kEntitlementElite)) return 'elite';
    if (info.entitlements.active.containsKey(kEntitlementPro))   return 'pro';
    return 'free';
  }

  /// Busca os packages disponíveis da offering padrão
  Future<List<Package>> getOfferings() async {
    final offerings = await Purchases.getOfferings();
    return offerings.current?.availablePackages ?? [];
  }

  /// Compra um package e retorna CustomerInfo atualizado
  Future<CustomerInfo> purchase(Package package) async {
    final info = await Purchases.purchasePackage(package);
    return info.customerInfo;
  }

  /// Restaura compras (obrigatório nas stores)
  Future<CustomerInfo> restore() async {
    return Purchases.restorePurchases();
  }

  /// Stream de atualizações (ex: expiração durante uso)
  Stream<CustomerInfo> get customerInfoStream =>
      Purchases.customerInfoStream;
}

// ── Providers ───────────────────────────────────────────────

final revenueCatServiceProvider = Provider((_) => RevenueCatService());

/// Provider do CustomerInfo — atualiza em tempo real
final customerInfoProvider = StreamProvider<CustomerInfo>((ref) {
  return ref.read(revenueCatServiceProvider).customerInfoStream;
});

/// Plano atual ('free' | 'pro' | 'elite') — derivado do CustomerInfo
final currentPlanProvider = Provider<String>((ref) {
  final info = ref.watch(customerInfoProvider).valueOrNull;
  if (info == null) return 'free';
  if (info.entitlements.active.containsKey(kEntitlementElite)) return 'elite';
  if (info.entitlements.active.containsKey(kEntitlementPro))   return 'pro';
  return 'free';
});

/// Se o usuário tem acesso Pro ou Elite
final hasPremiumProvider = Provider<bool>((ref) {
  final plan = ref.watch(currentPlanProvider);
  return plan == 'pro' || plan == 'elite';
});

/// Packages disponíveis para compra
final offeringsProvider = FutureProvider<List<Package>>((ref) {
  return ref.read(revenueCatServiceProvider).getOfferings();
});
