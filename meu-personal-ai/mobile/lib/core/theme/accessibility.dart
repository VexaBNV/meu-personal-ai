import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

// ═══════════════════════════════════════════════════════════
// WIDGETS DE ACESSIBILIDADE
// ═══════════════════════════════════════════════════════════

/// Botão acessível com label e hint para VoiceOver/TalkBack
class A11yButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Widget child;

  const A11yButton({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    hint: hint,
    button: true,
    enabled: onPressed != null,
    child: ExcludeSemantics(child: GestureDetector(onTap: onPressed, child: child)),
  );
}

/// Card com header acessível
class A11yCard extends StatelessWidget {
  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  const A11yCard({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    button: onTap != null,
    child: GestureDetector(onTap: onTap, child: child),
  );
}

/// Wrapper para métricas — anuncia o valor + label
class A11yMetric extends StatelessWidget {
  final String label;
  final String value;
  final Widget child;

  const A11yMetric({super.key, required this.label, required this.value, required this.child});

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    child: ExcludeSemantics(child: child),
  );
}

/// Wrapper para imagens decorativas (exclui do leitor)
class A11yDecorativeImage extends StatelessWidget {
  final Widget child;
  const A11yDecorativeImage({super.key, required this.child});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: child);
}

/// Componente de input com label acessível explícito
class A11yTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscureText;

  const A11yTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    hint: hint,
    textField: true,
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

// ═══════════════════════════════════════════════════════════
// TELA DE APARÊNCIA (tema claro/escuro + tamanho de fonte)
// ═══════════════════════════════════════════════════════════

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

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
        _SectionHeader('Tema', context),

        // Cards de tema
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            _ThemeCard(
              icon: Icons.light_mode_rounded,
              label: 'Claro',
              selected: themeMode == ThemeMode.light,
              onTap: () => ref.read(themeProvider.notifier).setLight(),
            ),
            const SizedBox(width: 10),
            _ThemeCard(
              icon: Icons.dark_mode_rounded,
              label: 'Escuro',
              selected: themeMode == ThemeMode.dark,
              onTap: () => ref.read(themeProvider.notifier).setDark(),
            ),
            const SizedBox(width: 10),
            _ThemeCard(
              icon: Icons.phone_android_rounded,
              label: 'Sistema',
              selected: themeMode == ThemeMode.system,
              onTap: () => ref.read(themeProvider.notifier).setSystem(),
            ),
          ]),
        ),

        const SizedBox(height: 16),
        _SectionHeader('Acessibilidade', context),

        // Tamanho de fonte (usa escala nativa do sistema)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.divColor),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tamanho do texto', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: context.textColor)),
            const SizedBox(height: 4),
            Text('O app respeita o tamanho de fonte configurado nas preferências do sistema (Acessibilidade → Tamanho do texto).',
              style: TextStyle(fontSize: 13, color: context.textSecColor, height: 1.5)),
            const SizedBox(height: 12),
            Row(children: [
              Text('Aa', style: TextStyle(fontSize: 14, color: context.textSecColor)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LinearProgressIndicator(
                    value: MediaQuery.textScalerOf(context).scale(1.0).clamp(0.8, 2.0) / 2.0,
                    backgroundColor: context.divColor,
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('Aa', style: TextStyle(fontSize: 22, color: context.textSecColor)),
            ]),
          ]),
        ),

        // Reduzir movimento
        _SwitchTile(
          title: 'Reduzir animações',
          subtitle: 'Desativa animações decorativas para melhor conforto visual',
          value: MediaQuery.of(context).disableAnimations,
          onChange: null, // controlado pelo sistema
          isSystemControlled: true,
          context: context,
        ),

        // Alto contraste
        _SwitchTile(
          title: 'Alto contraste',
          subtitle: 'Aumenta o contraste das bordas e textos',
          value: MediaQuery.of(context).highContrast,
          onChange: null,
          isSystemControlled: true,
          context: context,
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withOpacity(.07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Reduzir animações e alto contraste são controlados pelas configurações de acessibilidade do seu dispositivo (iOS: Ajustes → Acessibilidade · Android: Configurações → Acessibilidade).',
              style: TextStyle(fontSize: 12, color: AppColors.brandPrimary, height: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final BuildContext ctx;
  const _SectionHeader(this.title, this.ctx);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
    child: Text(title, style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: ctx.textSecColor, letterSpacing: .04,
    )),
  );
}

class _ThemeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeCard({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      label: 'Tema $label${selected ? ', selecionado' : ''}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandPrimary.withOpacity(.1) : context.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandPrimary : context.divColor,
              width: selected ? 2 : 0.5,
            ),
          ),
          child: Column(children: [
            Icon(icon, color: selected ? AppColors.brandPrimary : context.textSecColor, size: 24),
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

class _SwitchTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool>? onChange;
  final bool isSystemControlled;
  final BuildContext context;
  const _SwitchTile({
    required this.title, required this.subtitle, required this.value,
    required this.onChange, required this.isSystemControlled, required this.context,
  });

  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: context.cardColor, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.divColor),
    ),
    child: Semantics(
      label: '$title: ${value ? "ativado" : "desativado"}',
      hint: isSystemControlled ? 'Controlado pelo sistema' : null,
      child: SwitchListTile.adaptive(
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecColor)),
        value: value,
        onChanged: isSystemControlled ? null : onChange,
        activeColor: AppColors.brandPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    ),
  );
}
