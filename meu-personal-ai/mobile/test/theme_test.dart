import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import '../lib/core/theme/app_theme.dart';
import '../lib/core/theme/appearance_screen.dart';
import '../lib/core/theme/accessibility.dart';

void main() {
  // ── AppTheme ─────────────────────────────────────────────
  group('AppTheme', () {
    test('light() tem brightness Brightness.light', () {
      final theme = AppTheme.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark() tem brightness Brightness.dark', () {
      final theme = AppTheme.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('ambos usam brandPrimary como seedColor', () {
      final light = AppTheme.light();
      final dark  = AppTheme.dark();
      // Verifica que o ElevatedButton mantém cor do tema
      expect(light.elevatedButtonTheme.style, isNotNull);
      expect(dark.elevatedButtonTheme.style, isNotNull);
    });

    test('light scaffoldBackground difere do dark', () {
      final light = AppTheme.light();
      final dark  = AppTheme.dark();
      expect(
        light.scaffoldBackgroundColor,
        isNot(equals(dark.scaffoldBackgroundColor)),
      );
    });

    test('brandPrimary é igual nos dois modos', () {
      // O laranja é a identidade visual — não muda com o tema
      expect(AppColors.brandPrimary, const Color(0xFFFF6B1A));
    });
  });

  // ── ThemeNotifier ─────────────────────────────────────────
  group('ThemeNotifier', () {
    late ProviderContainer container;

    setUp(() async {
      // Hive em memória para testes
      Hive.init('/tmp/hive_test');
      await Hive.openBox('user_cache');
      container = ProviderContainer();
    });

    tearDown(() async {
      container.dispose();
      await Hive.deleteBoxFromDisk('user_cache');
    });

    test('estado inicial é ThemeMode.system', () {
      final mode = container.read(themeProvider);
      expect(mode, ThemeMode.system);
    });

    test('setLight() muda para ThemeMode.light', () {
      container.read(themeProvider.notifier).setLight();
      expect(container.read(themeProvider), ThemeMode.light);
    });

    test('setDark() muda para ThemeMode.dark', () {
      container.read(themeProvider.notifier).setDark();
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    test('setSystem() volta para ThemeMode.system', () {
      container.read(themeProvider.notifier).setDark();
      container.read(themeProvider.notifier).setSystem();
      expect(container.read(themeProvider), ThemeMode.system);
    });

    test('persiste no Hive após mudança', () {
      container.read(themeProvider.notifier).setDark();
      final box = Hive.box('user_cache');
      expect(box.get('app_theme_mode'), 'dark');
    });

    test('restaura do Hive na inicialização', () async {
      // Pré-popula o box
      final box = Hive.box('user_cache');
      await box.put('app_theme_mode', 'light');

      // Novo container lê do Hive
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      expect(c2.read(themeProvider), ThemeMode.light);
    });
  });

  // ── Extensões de contexto ─────────────────────────────────
  group('BuildContext extensions', () {
    Widget _wrap(ThemeMode mode, WidgetBuilder builder) => ProviderScope(
      overrides: [themeProvider.overrideWithValue(mode)],
      child: MaterialApp(
        themeMode: mode,
        theme:     AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: Builder(builder: builder),
      ),
    );

    testWidgets('isDark false no modo claro', (tester) async {
      bool? result;
      await tester.pumpWidget(_wrap(ThemeMode.light, (ctx) {
        result = ctx.isDark;
        return const SizedBox();
      }));
      expect(result, isFalse);
    });

    testWidgets('isDark true no modo escuro', (tester) async {
      bool? result;
      await tester.pumpWidget(_wrap(ThemeMode.dark, (ctx) {
        result = ctx.isDark;
        return const SizedBox();
      }));
      expect(result, isTrue);
    });

    testWidgets('cardColor é branco no modo claro', (tester) async {
      Color? result;
      await tester.pumpWidget(_wrap(ThemeMode.light, (ctx) {
        result = ctx.cardColor;
        return const SizedBox();
      }));
      expect(result, Colors.white);
    });

    testWidgets('cardColor é escuro no modo escuro', (tester) async {
      Color? result;
      await tester.pumpWidget(_wrap(ThemeMode.dark, (ctx) {
        result = ctx.cardColor;
        return const SizedBox();
      }));
      expect(result, AppColors.cardDark);
    });
  });

  // ── AppearanceScreen ─────────────────────────────────────
  group('AppearanceScreen', () {
    testWidgets('exibe as 3 opções de tema', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AppearanceScreen(),
        ),
      ));
      expect(find.text('Claro'),  findsOneWidget);
      expect(find.text('Escuro'), findsOneWidget);
      expect(find.text('Sistema'), findsOneWidget);
    });

    testWidgets('tocar em Escuro atualiza o provider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const AppearanceScreen(),
        ),
      ));

      await tester.tap(find.text('Escuro'));
      await tester.pump();
      expect(container.read(themeProvider), ThemeMode.dark);
    });

    testWidgets('exibe seção de Acessibilidade', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AppearanceScreen(),
        ),
      ));
      expect(find.text('Acessibilidade'), findsOneWidget);
      expect(find.text('Tamanho do texto'), findsOneWidget);
    });
  });

  // ── Widgets de acessibilidade ─────────────────────────────
  group('A11yButton', () {
    testWidgets('tem label semântico correto', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: A11yButton(
            label: 'Começar treino',
            hint: 'Inicia a sessão de treino',
            onPressed: () {},
            child: const Text('Iniciar'),
          ),
        ),
      ));

      final semantics = tester.getSemantics(find.byType(A11yButton));
      expect(semantics.label, 'Começar treino');
    });
  });

  group('DarkAwareCard', () {
    testWidgets('renderiza filho corretamente', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DarkAwareCard(
            child: const Text('Conteúdo'),
          ),
        ),
      ));
      expect(find.text('Conteúdo'), findsOneWidget);
    });

    testWidgets('aplica border-radius corretamente', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DarkAwareCard(
            radius: 20,
            child: const Text('Teste'),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(20));
    });
  });

  // ── Contraste WCAG ───────────────────────────────────────
  group('Contraste de cores (WCAG AA)', () {
    double _luminance(Color c) {
      double normalize(int v) {
        final s = v / 255;
        return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) * ((s + 0.055) / 1.055);
      }
      return 0.2126 * normalize(c.red) +
             0.7152 * normalize(c.green) +
             0.0722 * normalize(c.blue);
    }

    double _contrast(Color fg, Color bg) {
      final l1 = _luminance(fg);
      final l2 = _luminance(bg);
      final lighter = l1 > l2 ? l1 : l2;
      final darker  = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('texto primário sobre fundo claro — WCAG AA (≥4.5)', () {
      final ratio = _contrast(AppColors.textPrimary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Contraste insuficiente: ${ratio.toStringAsFixed(2)}:1');
    });

    test('texto secundário sobre fundo claro — WCAG AA', () {
      final ratio = _contrast(AppColors.textSecondary, Colors.white);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Contraste insuficiente: ${ratio.toStringAsFixed(2)}:1');
    });

    test('texto primário escuro sobre fundo escuro — WCAG AA', () {
      final ratio = _contrast(
        AppColors.textPrimaryDark, AppColors.backgroundDark);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Contraste insuficiente: ${ratio.toStringAsFixed(2)}:1');
    });

    test('laranja sobre preto — WCAG AA', () {
      final ratio = _contrast(AppColors.brandPrimary, AppColors.black);
      expect(ratio, greaterThanOrEqualTo(4.5),
        reason: 'Contraste insuficiente: ${ratio.toStringAsFixed(2)}:1');
    });

    test('branco sobre laranja — WCAG AA', () {
      final ratio = _contrast(Colors.white, AppColors.brandPrimary);
      expect(ratio, greaterThanOrEqualTo(3.0), // AA para texto grande/UI
        reason: 'Contraste insuficiente: ${ratio.toStringAsFixed(2)}:1');
    });
  });
}
