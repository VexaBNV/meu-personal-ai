import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';
import '../data/health_provider.dart';

class HealthSyncScreen extends ConsumerWidget {
  const HealthSyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Saúde e dispositivos'),
        backgroundColor: context.cardColor,
        foregroundColor: context.textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: context.divColor),
        ),
        actions: [
          if (healthAsync.valueOrNull?.authorized == true)
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Sincronizar agora',
              onPressed: healthAsync.isLoading
                  ? null
                  : () => ref.read(healthProvider.notifier).syncNow(),
            ),
        ],
      ),
      body: healthAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: \$e')),
        data: (state) => _Body(state: state),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final HealthState state;
  const _Body({required this.state});

  static final _fmt = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(healthProvider.notifier);
    final isIos    = Theme.of(context).platform == TargetPlatform.iOS;
    final appName  = isIos ? 'Apple Health' : 'Google Fit';

    return ListView(padding: const EdgeInsets.all(16), children: [
      _Card(child: Row(children: [
        Text(isIos ? '🍎' : '💚', style: const TextStyle(fontSize: 38)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(appName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.textColor)),
          const SizedBox(height: 4),
          _StatusDot(connected: state.authorized),
          if (state.lastSync != null) ...[
            const SizedBox(height: 3),
            Text('Última sync: ${_fmt.format(state.lastSync!)}',
              style: TextStyle(fontSize: 11, color: context.textSecColor)),
          ],
        ])),
        if (!state.authorized)
          _ConnectButton(onTap: () => notifier.requestPermissions()),
      ])),

      const SizedBox(height: 12),

      if (state.authorized && (state.todaySteps != null || state.latestWeight != null)) ...[
        _SectionLabel('Dados sincronizados', context),
        _Card(child: Column(children: [
          if (state.todaySteps != null)
            _DataRow(
              icon: Icons.directions_walk_rounded,
              label: 'Passos hoje',
              value: '${_fmtNum(state.todaySteps!)} passos',
            ),
          if (state.todaySteps != null && state.latestWeight != null)
            Divider(height: 1, color: context.divColor),
          if (state.latestWeight != null)
            _DataRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Peso mais recente',
              value: '${state.latestWeight!.toStringAsFixed(1)} kg',
            ),
        ])),
        const SizedBox(height: 12),
      ],

      if (state.authorized) ...[
        _SectionLabel('O que sincronizar', context),
        _Card(child: Column(children: [
          _ToggleTile(
            icon: Icons.fitness_center_rounded,
            title: 'Salvar treinos',
            subtitle: 'Envia cada sessão concluída para o \$appName',
            value: state.syncWorkouts,
            onChanged: notifier.toggleSyncWorkouts,
          ),
          Divider(height: 1, color: context.divColor),
          _ToggleTile(
            icon: Icons.monitor_weight_outlined,
            title: 'Salvar peso',
            subtitle: 'Sincroniza o peso ao atualizar o perfil',
            value: state.syncWeight,
            onChanged: notifier.toggleSyncWeight,
          ),
          Divider(height: 1, color: context.divColor),
          _ToggleTile(
            icon: Icons.directions_walk_rounded,
            title: 'Ler passos',
            subtitle: 'Mostra seus passos do dia na tela inicial',
            value: state.readSteps,
            onChanged: notifier.toggleReadSteps,
          ),
        ])),
        const SizedBox(height: 12),
      ],

      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.brandPrimary.withOpacity(.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brandPrimary.withOpacity(.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brandPrimary),
          const SizedBox(width: 8),
          Expanded(child: Text(
            'Seus dados de saúde ficam no dispositivo. '
            'O Meu Personal AI não armazena dados do \$appName nos nossos servidores.',
            style: TextStyle(fontSize: 12, color: AppColors.brandPrimary, height: 1.5),
          )),
        ]),
      ),

      const SizedBox(height: 32),
    ]);
  }

  String _fmtNum(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor),
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final BuildContext ctx;
  const _SectionLabel(this.text, this.ctx);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: ctx.textSecColor, letterSpacing: .04,
    )),
  );
}

class _StatusDot extends StatelessWidget {
  final bool connected;
  const _StatusDot({required this.connected});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: connected ? AppColors.success : context.textSecColor,
    )),
    const SizedBox(width: 5),
    Text(connected ? 'Conectado' : 'Não conectado',
      style: TextStyle(fontSize: 12, color: context.textSecColor)),
  ]);
}

class _ConnectButton extends StatefulWidget {
  final Future<bool> Function() onTap;
  const _ConnectButton({required this.onTap});
  @override createState() => _State();
}

class _State extends State<_ConnectButton> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _loading ? null : _go,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.black,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    child: _loading
        ? const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
        : const Text('Conectar'),
  );
  Future<void> _go() async {
    setState(() => _loading = true);
    await widget.onTap();
    if (mounted) setState(() => _loading = false);
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _DataRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Icon(icon, size: 18, color: context.textSecColor),
      const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 13, color: context.textColor)),
      const Spacer(),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, size: 18, color: context.textSecColor),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: context.textColor)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: context.textSecColor)),
      ])),
      Switch.adaptive(
        value: value, onChanged: onChanged,
        activeColor: AppColors.brandPrimary,
      ),
    ]),
  );
}
