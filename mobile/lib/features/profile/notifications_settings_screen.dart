import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meu_personal_ai/core/network/api_client.dart';
import 'package:meu_personal_ai/core/theme/app_theme.dart';

// ── Modelo e provider ─────────────────────────────────────────

class NotifSettings {
  final bool dailyReminder;
  final String dailyReminderTime; // "HH:mm"
  final bool streakAlerts;
  final bool weeklyReport;
  final bool workoutComplete;
  final bool marketing;

  const NotifSettings({
    this.dailyReminder     = true,
    this.dailyReminderTime = '07:00',
    this.streakAlerts      = true,
    this.weeklyReport      = true,
    this.workoutComplete   = true,
    this.marketing         = false,
  });

  NotifSettings copyWith({
    bool? dailyReminder, String? dailyReminderTime,
    bool? streakAlerts, bool? weeklyReport,
    bool? workoutComplete, bool? marketing,
  }) => NotifSettings(
    dailyReminder:     dailyReminder     ?? this.dailyReminder,
    dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    streakAlerts:      streakAlerts      ?? this.streakAlerts,
    weeklyReport:      weeklyReport      ?? this.weeklyReport,
    workoutComplete:   workoutComplete   ?? this.workoutComplete,
    marketing:         marketing         ?? this.marketing,
  );

  Map<String, dynamic> toJson() => {
    'dailyReminder':     dailyReminder,
    'dailyReminderTime': dailyReminderTime,
    'streakAlerts':      streakAlerts,
    'weeklyReport':      weeklyReport,
    'workoutComplete':   workoutComplete,
    'marketing':         marketing,
  };

  factory NotifSettings.fromJson(Map<String, dynamic> j) => NotifSettings(
    dailyReminder:     j['dailyReminder']     ?? true,
    dailyReminderTime: j['dailyReminderTime'] ?? '07:00',
    streakAlerts:      j['streakAlerts']      ?? true,
    weeklyReport:      j['weeklyReport']      ?? true,
    workoutComplete:   j['workoutComplete']   ?? true,
    marketing:         j['marketing']         ?? false,
  );
}

class NotifSettingsNotifier extends AsyncNotifier<NotifSettings> {
  @override
  Future<NotifSettings> build() async {
    final api = ref.read(apiClientProvider);
    final res = await api.dio.get('/users/me/notification-settings');
    return NotifSettings.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> update(NotifSettings updated) async {
    // Update otimista
    final previous = state.valueOrNull;
    state = AsyncData(updated);

    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/me/notification-settings',
        data: updated.toJson());
    } catch (_) {
      // Reverter em caso de erro
      if (previous != null) state = AsyncData(previous);
    }
  }
}

final notifSettingsProvider =
    AsyncNotifierProvider<NotifSettingsNotifier, NotifSettings>(
      NotifSettingsNotifier.new);

// ── Tela ──────────────────────────────────────────────────────

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notifSettingsProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Notificações'),
        backgroundColor: context.cardColor,
        foregroundColor: context.textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: context.divColor),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erro: $e')),
        data:    (s) => _Body(settings: s),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final NotifSettings settings;
  const _Body({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notifSettingsProvider.notifier);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Permissão do sistema ──────────────────────────────
      _PermissionBanner(),
      const SizedBox(height: 16),

      // ── Treino ────────────────────────────────────────────
      _SectionLabel('Treino', context),
      _Card(context: context, child: Column(children: [
        _Toggle(
          icon: Icons.alarm_rounded,
          title: 'Lembrete diário',
          subtitle: 'Aviso para não deixar o treino escapar',
          value: settings.dailyReminder,
          onChanged: (v) =>
              notifier.update(settings.copyWith(dailyReminder: v)),
        ),
        if (settings.dailyReminder) ...[
          Divider(height: 1, color: context.divColor),
          _TimeRow(
            time: settings.dailyReminderTime,
            onChanged: (t) =>
                notifier.update(settings.copyWith(dailyReminderTime: t)),
          ),
        ],
        Divider(height: 1, color: context.divColor),
        _Toggle(
          icon: Icons.emoji_events_rounded,
          title: 'Conquistas e streak',
          subtitle: 'Milestones de 7, 14, 30, 60 e 90 dias',
          value: settings.streakAlerts,
          onChanged: (v) =>
              notifier.update(settings.copyWith(streakAlerts: v)),
        ),
        Divider(height: 1, color: context.divColor),
        _Toggle(
          icon: Icons.check_circle_outline_rounded,
          title: 'Resumo pós-treino',
          subtitle: 'Feedback da IA após cada sessão concluída',
          value: settings.workoutComplete,
          onChanged: (v) =>
              notifier.update(settings.copyWith(workoutComplete: v)),
        ),
      ])),

      const SizedBox(height: 16),

      // ── Relatórios ────────────────────────────────────────
      _SectionLabel('Relatórios', context),
      _Card(context: context, child: _Toggle(
        icon: Icons.bar_chart_rounded,
        title: 'Resumo semanal',
        subtitle: 'Receba todo domingo um resumo da semana',
        value: settings.weeklyReport,
        onChanged: (v) =>
            notifier.update(settings.copyWith(weeklyReport: v)),
      )),

      const SizedBox(height: 16),

      // ── Marketing ─────────────────────────────────────────
      _SectionLabel('Comunicações', context),
      _Card(context: context, child: _Toggle(
        icon: Icons.campaign_rounded,
        title: 'Novidades e dicas',
        subtitle: 'Conteúdo sobre treino, nutrição e atualizações do app',
        value: settings.marketing,
        onChanged: (v) =>
            notifier.update(settings.copyWith(marketing: v)),
      )),

      const SizedBox(height: 32),
    ]);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => AppSettings.openAppSettings(),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withOpacity(.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(.2))),
      child: Row(children: [
        Icon(Icons.notifications_outlined,
          color: AppColors.brandPrimary, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(
          'As notificações precisam estar habilitadas nas configurações do dispositivo.',
          style: TextStyle(fontSize: 12, color: AppColors.brandPrimary,
            height: 1.4))),
        const SizedBox(width: 6),
        Text('Configurar', style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: AppColors.brandPrimary)),
      ]),
    ),
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
      color: ctx.textSecColor, letterSpacing: .04)),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final BuildContext context;
  const _Card({required this.child, required this.context});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor)),
    child: child,
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: SwitchListTile.adaptive(
      secondary: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: value
              ? AppColors.brandPrimary.withOpacity(.1) : context.bgColor,
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18,
          color: value ? AppColors.brandPrimary : context.textSecColor)),
      title: Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: context.textColor)),
      subtitle: Text(subtitle, style: TextStyle(
        fontSize: 12, color: context.textSecColor)),
      value: value, onChanged: onChanged,
      activeColor: AppColors.brandPrimary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
    ),
  );
}

class _TimeRow extends StatelessWidget {
  final String time;
  final ValueChanged<String> onChanged;
  const _TimeRow({required this.time, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(children: [
      const SizedBox(width: 42), // alinha com os toggles
      const SizedBox(width: 16),
      Text('Horário', style: TextStyle(
        fontSize: 13, color: context.textSecColor)),
      const Spacer(),
      GestureDetector(
        onTap: () async {
          final parts = time.split(':');
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour:   int.parse(parts[0]),
              minute: int.parse(parts[1])),
          );
          if (picked != null) {
            onChanged('${picked.hour.toString().padLeft(2,'0')}:'
                '${picked.minute.toString().padLeft(2,'0')}');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.divColor)),
          child: Text(time, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: context.textColor)),
        ),
      ),
    ]),
  );
}
