import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import '../data/revenue_cat_service.dart';
import 'paywall_screen.dart';

/// Tile de assinatura para inserir na ProfileScreen.
/// Exibe plano atual, data de expiração e botão de ação.
class ManageSubscriptionTile extends ConsumerStatefulWidget {
  const ManageSubscriptionTile({super.key});

  @override
  createState() => _State();
}

class _State extends ConsumerState<ManageSubscriptionTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(currentPlanProvider);
    final info = ref.watch(customerInfoProvider).valueOrNull;

    final expiry = info?.entitlements.active.values.firstOrNull?.expirationDate;
    final isTrialing = plan == 'pro' &&
        (info?.entitlements.active['pro']?.productIdentifier?.contains('trial') ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Column(children: [
        // Header do plano
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _planBg(plan),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_planIcon(plan), style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_planName(plan),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (isTrialing)
                Text('Trial ativo', style: TextStyle(fontSize: 12, color: AppColors.brandPrimary)),
              if (expiry != null && !isTrialing)
                Text('Renova em ${_formatDate(expiry)}',
                  style: TextStyle(fontSize: 12, color: context.textSecColor)),
            ])),
            if (plan == 'free')
              GestureDetector(
                onTap: () => PaywallScreen.show(context, ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Upgrade', style: TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),

        if (plan != 'free') ...[
          Divider(height: 20, indent: 16, endIndent: 16, color: context.divColor),
          // Ações de assinatura
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [
              _ActionTile(
                icon: Icons.receipt_long_outlined,
                label: 'Gerenciar assinatura',
                subtitle: 'Cancelar, trocar plano ou atualizar pagamento',
                onTap: _openPortal,
                loading: _loading,
              ),
              const SizedBox(height: 4),
              _ActionTile(
                icon: Icons.restore_rounded,
                label: 'Restaurar compras',
                subtitle: 'Recuperar assinatura anterior',
                onTap: _restore,
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Future<void> _openPortal() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/plans/portal');
      final url = Uri.parse(res.data['url'] as String);
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o portal de assinatura.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      await ref.read(revenueCatServiceProvider).restore();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compras restauradas com sucesso!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma compra anterior encontrada.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _planName(String p) => p == 'elite' ? 'Plano Elite' : p == 'pro' ? 'Plano Pro' : 'Plano Free';
  String _planIcon(String p) => p == 'elite' ? '⭐' : p == 'pro' ? '🔥' : '🆓';
  Color  _planBg(String p) => p == 'elite'
      ? const Color(0xFFEEEDFE)
      : p == 'pro'
          ? const Color(0xFFFFF4EE)
          : const Color(0xFFF1EFE8);

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;
  final bool loading;
  const _ActionTile({
    required this.icon, required this.label, required this.subtitle,
    required this.onTap, this.loading = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: loading ? null : onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: context.textSecColor),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(subtitle, style: TextStyle(fontSize: 11, color: context.textSecColor)),
        ])),
        if (loading)
          const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(Icons.chevron_right, size: 18, color: context.divColor),
      ]),
    ),
  );
}
