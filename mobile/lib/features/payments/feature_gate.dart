import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/revenue_cat_service.dart';
import 'paywall_screen.dart';
import 'package:meu_personal_ai/core/theme/app_colors.dart';

enum FeatureTier { pro, elite }

/// Wrapper que bloqueia conteúdo e exibe paywall se necessário.
/// Exemplo:
///   FeatureGate(
///     feature: 'Analytics completo',
///     tier: FeatureTier.pro,
///     child: AnalyticsTab(),
///   )
class FeatureGate extends ConsumerWidget {
  final String       feature;
  final FeatureTier  tier;
  final Widget       child;
  final Widget?      lockedChild; // opcional: o que mostrar bloqueado
  final bool         showOverlay; // false = oculta totalmente

  const FeatureGate({
    super.key,
    required this.feature,
    required this.tier,
    required this.child,
    this.lockedChild,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentPlanProvider);
    final hasAccess = _hasAccess(plan);

    if (hasAccess) return child;
    if (!showOverlay) return lockedChild ?? const SizedBox.shrink();

    return Stack(children: [
      // Conteúdo bloqueado (desfocado)
      AbsorbPointer(
        child: Opacity(opacity: .35, child: lockedChild ?? child),
      ),
      // Overlay de lock
      Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openPaywall(context, ref),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(.3)),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.lock_rounded, color: AppColors.brandPrimary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      tier == FeatureTier.elite ? 'Plano Elite' : 'Plano Pro',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(feature,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Ver planos', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  bool _hasAccess(String plan) {
    if (tier == FeatureTier.pro)   return plan == 'pro'  || plan == 'elite';
    if (tier == FeatureTier.elite) return plan == 'elite';
    return true;
  }

  Future<void> _openPaywall(BuildContext context, WidgetRef ref) async {
    await PaywallScreen.show(context, ref, feature: feature);
  }
}

/// Hook para verificar acesso antes de executar ação.
/// Retorna true se pode prosseguir, false se foi bloqueado.
/// Exemplo:
///   if (!await checkFeatureAccess(context, ref, 'Substituição', FeatureTier.pro)) return;
Future<bool> checkFeatureAccess(
  BuildContext context,
  WidgetRef ref,
  String feature,
  FeatureTier tier,
) async {
  final plan = ref.read(currentPlanProvider);
  final hasAccess = tier == FeatureTier.pro
      ? plan == 'pro' || plan == 'elite'
      : plan == 'elite';

  if (hasAccess) return true;
  final purchased = await PaywallScreen.show(context, ref, feature: feature);
  return purchased;
}
