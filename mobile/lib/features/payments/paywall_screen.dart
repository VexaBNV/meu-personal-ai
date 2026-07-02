import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/revenue_cat_service.dart';
import 'package:meu_personal_ai/core/theme/app_colors.dart';

/// Sheet/tela de paywall completa com preços reais do RevenueCat.
/// Uso: PaywallScreen.show(context, ref, feature: 'AI Coach ilimitado')
class PaywallScreen extends ConsumerStatefulWidget {
  final String? highlightedFeature;
  const PaywallScreen({super.key, this.highlightedFeature});

  static Future<bool> show(
    BuildContext context,
    WidgetRef ref, {
    String? feature,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaywallScreen(highlightedFeature: feature),
    );
    return result ?? false;
  }

  @override
  createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int   _selectedIndex = 0; // 0=Pro Mensal 1=Pro Anual 2=Elite Mensal
  bool  _loading = false;
  String? _error;

  // Features por plano
  static const _proFeatures = [
    ('IA Coach ilimitado', true),
    ('Analytics completo de força e corpo', true),
    ('Social, ranking e desafios', true),
    ('Fotos de progresso antes/depois', true),
    ('Treino express gerado por IA', true),
    ('Substituição inteligente de exercício', true),
    ('Relatório semanal por push', true),
  ];

  static const _eliteExtras = [
    ('Até 10 perfis (família / alunos)', true),
    ('Análise de postura por vídeo com IA', true),
    ('Painel do personal trainer', true),
    ('Export PDF de relatórios', true),
    ('Apple Health + Google Fit sync', true),
    ('Suporte prioritário 4h', true),
  ];

  @override
  Widget build(BuildContext context) {
    final offerings = ref.watch(offeringsProvider);

    return DraggableScrollableSheet(
      initialChildSize: .94,
      minChildSize: .7,
      maxChildSize: .98,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: offerings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error:   (e, _) => _ErrorState(onRetry: () => ref.invalidate(offeringsProvider)),
          data:    (packages) => _buildContent(context, scroll, packages),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext ctx, ScrollController scroll, List<Package> packages) {
    // Mapeia packages por productId
    final pkgMap = {for (final p in packages) p.storeProduct.identifier: p};

    final options = [
      _PlanOption(
        label: 'Pro Mensal',
        price: pkgMap[kProductProMonthly]?.storeProduct.priceString ?? 'R\$39',
        period: '/mês',
        package: pkgMap[kProductProMonthly],
        entitlement: kEntitlementPro,
        badge: null,
      ),
      _PlanOption(
        label: 'Pro Anual',
        price: pkgMap[kProductProAnnual]?.storeProduct.priceString ?? 'R\$348',
        period: '/ano · R\$29/mês',
        package: pkgMap[kProductProAnnual],
        entitlement: kEntitlementPro,
        badge: 'Economize 26%',
      ),
      _PlanOption(
        label: 'Elite Mensal',
        price: pkgMap[kProductEliteMonthly]?.storeProduct.priceString ?? 'R\$89',
        period: '/mês',
        package: pkgMap[kProductEliteMonthly],
        entitlement: kEntitlementElite,
        badge: null,
      ),
    ];

    return Column(children: [
      // Handle
      Container(
        width: 36, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
      ),

      Expanded(child: SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          if (widget.highlightedFeature != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandPrimary.withOpacity(.2)),
              ),
              child: Row(children: [
                Icon(Icons.lock_outline, color: AppColors.brandPrimary, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  '${widget.highlightedFeature} requer plano Pro ou Elite',
                  style: TextStyle(fontSize: 13, color: AppColors.brandPrimary),
                )),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          const Text('Escolha seu plano', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('7 dias grátis no Pro · Cancele quando quiser',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Opções de plano
          ...options.asMap().entries.map((e) {
            final i = e.key; final opt = e.value;
            final selected = _selectedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brandPrimary.withOpacity(.06) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.brandPrimary : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.brandPrimary : AppColors.divider,
                        width: selected ? 2 : 1.5,
                      ),
                      color: selected ? AppColors.brandPrimary : Colors.transparent,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(opt.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      if (opt.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(opt.badge!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(opt.period, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                  Text(opt.price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Features do plano selecionado
          Text(
            _selectedIndex == 2 ? 'Tudo do Pro, mais:' : 'Incluído no plano:',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),

          ...(_selectedIndex == 2 ? [..._proFeatures, ..._eliteExtras] : _proFeatures)
              .map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.brandPrimary, size: 16),
                  const SizedBox(width: 8),
                  Text(f.$1, style: const TextStyle(fontSize: 13)),
                ]),
              )),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            ),
          ],
        ]),
      )),

      // Botão de compra
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(children: [
          ElevatedButton(
            onPressed: _loading ? null : () => _purchase(options[_selectedIndex]),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.black,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _selectedIndex == 1
                        ? 'Iniciar 7 dias grátis · Pro Anual'
                        : _selectedIndex == 0
                            ? 'Iniciar 7 dias grátis · Pro'
                            : 'Assinar Elite',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading ? null : _restore,
            child: Text('Restaurar compras',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
          Text(
            'Cobrado pela App Store/Google Play · Cancele quando quiser · CNPJ [a preencher]',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(.6)),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    ]);
  }

  Future<void> _purchase(_PlanOption opt) async {
    if (opt.package == null) {
      setState(() => _error = 'Produto não disponível. Verifique sua conexão.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(revenueCatServiceProvider).purchase(opt.package!);
      if (mounted) Navigator.pop(context, true);
    } on PurchasesErrorCode catch (e) {
      if (e != PurchasesErrorCode.purchaseCancelledError) {
        setState(() => _error = 'Erro na compra: ${e.name}');
      }
    } catch (e) {
      setState(() => _error = 'Erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(revenueCatServiceProvider).restore();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Não foi possível restaurar. Entre em contato com o suporte.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _PlanOption {
  final String label, price, period, entitlement;
  final Package? package;
  final String? badge;
  const _PlanOption({
    required this.label, required this.price, required this.period,
    required this.entitlement, required this.package, required this.badge,
  });
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Não foi possível carregar os planos.'),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
    ],
  ));
}
