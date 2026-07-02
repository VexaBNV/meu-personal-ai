import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark    = context.isDark;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Aparência'),
        backgroundColor: context.cardColor,
        foregroundColor: context.textColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(height: 0.5, color: context.divColor),
        ),
      ),
      body: ListView(children: [

        // ── Tema ──────────────────────────────────────────────
        _Section('Tema', context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _ThemeOption(
              icon: Icons.light_mode_rounded,
              label: 'Claro',
              selected: themeMode == ThemeMode.light,
              onTap: () => ref.read(themeProvider.notifier).setLight(),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              icon: Icons.dark_mode_rounded,
              label: 'Escuro',
              selected: themeMode == ThemeMode.dark,
              onTap: () => ref.read(themeProvider.notifier).setDark(),
            ),
            const SizedBox(width: 10),
            _ThemeOption(
              icon: Icons.phone_android_rounded,
              label: 'Sistema',
              selected: themeMode == ThemeMode.system,
              onTap: () => ref.read(themeProvider.notifier).setSystem(),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // Preview ao vivo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _ThemePreview(isDark: isDark),
        ),

        // ── Acessibilidade ────────────────────────────────────
        _Section('Acessibilidade', context),

        // Tamanho de fonte
        _Card(
          context: context,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.text_fields_rounded, size: 18, color: context.textSecColor),
              const SizedBox(width: 10),
              Text('Tamanho do texto',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: context.textColor)),
            ]),
            const SizedBox(height: 6),
            Text(
              'Controlado pelas preferências do sistema.',
              style: TextStyle(fontSize: 12, color: context.textSecColor, height: 1.4),
            ),
            const SizedBox(height: 12),
            // Régua de escala atual
            Row(children: [
              Text('A', style: TextStyle(fontSize: 12, color: context.textSecColor)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (MediaQuery.textScalerOf(context).scale(1.0))
                          .clamp(0.8, 2.0) / 2.0,
                      minHeight: 6,
                      backgroundColor: context.divColor,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
              ),
              Text('A', style: TextStyle(fontSize: 20, color: context.textSecColor)),
            ]),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'iOS: Ajustes → Acessibilidade → Tamanho do texto\n'
                'Android: Config → Acessibilidade → Tamanho da fonte',
                style: TextStyle(fontSize: 11, color: context.textSecColor,
                  height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ]),
        ),

        const SizedBox(height: 8),

        // Reduzir animações
        _SystemToggle(
          context: context,
          icon: Icons.animation_rounded,
          title: 'Reduzir animações',
          subtitle: 'Desativa animações decorativas',
          value: MediaQuery.of(context).disableAnimations,
        ),

        const SizedBox(height: 8),

        // Alto contraste
        _SystemToggle(
          context: context,
          icon: Icons.contrast_rounded,
          title: 'Alto contraste',
          subtitle: 'Aumenta contraste de bordas e textos',
          value: MediaQuery.of(context).highContrast,
        ),

        const SizedBox(height: 8),

        // Bold text (iOS)
        _SystemToggle(
          context: context,
          icon: Icons.format_bold_rounded,
          title: 'Texto em negrito',
          subtitle: 'Aplica negrito em todo o texto do sistema',
          value: MediaQuery.of(context).boldText,
        ),

        const SizedBox(height: 8),

        // Aviso sobre controles do sistema
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brandPrimary.withOpacity(.2)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reduzir animações, alto contraste e negrito são controlados '
                  'pelas configurações de acessibilidade do seu dispositivo. '
                  'O app respeita essas preferências automaticamente.',
                  style: TextStyle(fontSize: 12, color: AppColors.brandPrimary,
                    height: 1.5),
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final BuildContext ctx;
  const _Section(this.title, this.ctx);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(title, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: ctx.textSecColor, letterSpacing: .04,
      textBaseline: TextBaseline.alphabetic,
    )),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final BuildContext context;
  const _Card({required this.child, required this.context});
  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor),
    ),
    child: child,
  );
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeOption({
    required this.icon, required this.label,
    required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: 'Tema $label${selected ? ", selecionado" : ""}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPrimary.withOpacity(.1)
                : context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brandPrimary : context.divColor,
              width: selected ? 2 : 0.5,
            ),
          ),
          child: Column(children: [
            Icon(icon,
              size: 26,
              color: selected ? AppColors.brandPrimary : context.textSecColor),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? AppColors.brandPrimary : context.textColor,
            )),
          ]),
        ),
      ),
    ),
  );
}

class _ThemePreview extends StatelessWidget {
  final bool isDark;
  const _ThemePreview({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
          size: 14, color: context.textSecColor),
        const SizedBox(width: 6),
        Text(isDark ? 'Modo escuro ativo' : 'Modo claro ativo',
          style: TextStyle(fontSize: 11, color: context.textSecColor)),
      ]),
      const SizedBox(height: 10),
      // Mini mockup de card
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.divColor),
        ),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fitness_center_rounded,
              color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 10, width: 120,
              decoration: BoxDecoration(
                color: context.textColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(5))),
            const SizedBox(height: 5),
            Container(height: 8, width: 80,
              decoration: BoxDecoration(
                color: context.textSecColor.withOpacity(.15),
                borderRadius: BorderRadius.circular(4))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Pro', style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    ]),
  );
}

class _SystemToggle extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title, subtitle;
  final bool value;
  const _SystemToggle({
    required this.context, required this.icon,
    required this.title, required this.subtitle,
    required this.value,
  });

  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: context.cardColor,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.divColor),
    ),
    child: Semantics(
      label: '$title: ${value ? "ativado pelo sistema" : "desativado"}',
      child: ListTile(
        leading: Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: value
                ? AppColors.brandPrimary.withOpacity(.1)
                : context.bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18,
            color: value ? AppColors.brandPrimary : context.textSecColor),
        ),
        title: Text(title, style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w500, color: context.textColor)),
        subtitle: Text(subtitle, style: TextStyle(
          fontSize: 12, color: context.textSecColor)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: value
                ? AppColors.brandPrimary.withOpacity(.1)
                : context.divColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value ? 'Ativo' : 'Inativo',
            style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600,
              color: value ? AppColors.brandPrimary : context.textSecColor),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
  );
}
