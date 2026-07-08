import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

// ── ThemeMode persistence ────────────────────────────────────

const _kThemeKey = 'app_theme_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final box = Hive.box('user_cache');
    final stored = box.get(_kThemeKey, defaultValue: 'system') as String;
    return _fromString(stored);
  }

  void setLight()  => _set(ThemeMode.light);
  void setDark()   => _set(ThemeMode.dark);
  void setSystem() => _set(ThemeMode.system);

  void _set(ThemeMode mode) {
    final box = Hive.box('user_cache');
    box.put(_kThemeKey, _toString(mode));
    state = mode;
  }

  static ThemeMode _fromString(String s) => switch(s) {
    'light'  => ThemeMode.light,
    'dark'   => ThemeMode.dark,
    _        => ThemeMode.system,
  };
  static String _toString(ThemeMode m) => switch(m) {
    ThemeMode.light  => 'light',
    ThemeMode.dark   => 'dark',
    _                => 'system',
  };
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

// ── Paleta de cores ──────────────────────────────────────────

abstract class AppColors {
  static const brandPrimary = Color(0xFFFF6B1A);
  static const black        = Color(0xFF111111);
  static const white        = Color(0xFFFFFFFF);

  // Light
  static const textPrimary       = Color(0xFF111111);
  static const textSecondary     = Color(0xFF666666);
  static const divider           = Color(0xFFE5E5E3);
  static const surface           = Color(0xFFF5F5F3);
  static const background        = Color(0xFFF5F5F3);

  // Dark equivalents
  static const textPrimaryDark   = Color(0xFFF0EDE8);
  static const textSecondaryDark = Color(0xFF9A9896);
  static const dividerDark       = Color(0xFF2A2A28);
  static const surfaceDark       = Color(0xFF1C1C1A);
  static const backgroundDark    = Color(0xFF141412);
  static const cardDark          = Color(0xFF222220);

  // Semânticas (independentes de modo)
  static const success = Color(0xFF22A868);
  static const error   = Color(0xFFE24B4A);
  static const warning = Color(0xFFF5A623);
}

// ── Temas ────────────────────────────────────────────────────

class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    bg: AppColors.background,
    surface: Colors.white,
    card: Colors.white,
    text: AppColors.textPrimary,
    textSec: AppColors.textSecondary,
    divider: AppColors.divider,
    iconColor: AppColors.textSecondary,
    navBg: Colors.white,
    statusStyle: SystemUiOverlayStyle.dark,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    bg: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    card: AppColors.cardDark,
    text: AppColors.textPrimaryDark,
    textSec: AppColors.textSecondaryDark,
    divider: AppColors.dividerDark,
    iconColor: AppColors.textSecondaryDark,
    navBg: AppColors.surfaceDark,
    statusStyle: SystemUiOverlayStyle.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg, required Color surface, required Color card,
    required Color text, required Color textSec, required Color divider,
    required Color iconColor, required Color navBg,
    required SystemUiOverlayStyle statusStyle,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandPrimary,
        brightness: brightness,
        surface: surface,
        onSurface: text,
      ),

      scaffoldBackgroundColor: bg,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: card,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: text, letterSpacing: -.3,
        ),
        iconTheme: IconThemeData(color: text),
        systemOverlayStyle: statusStyle,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider, width: 0.5),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        hintStyle: TextStyle(color: textSec, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      // Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size.fromHeight(48),
        ),
      ),

      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: AppColors.brandPrimary.withOpacity(.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: AppColors.brandPrimary, size: 24);
          }
          return IconThemeData(color: iconColor, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brandPrimary);
          }
          return TextStyle(fontSize: 11, color: iconColor);
        }),
        elevation: 0,
        height: 64,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        side: BorderSide(color: divider),
        labelStyle: TextStyle(fontSize: 13, color: text),
        selectedColor: AppColors.brandPrimary.withOpacity(.15),
        checkmarkColor: AppColors.brandPrimary,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.brandPrimary : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
            ? AppColors.brandPrimary.withOpacity(.3)
            : Colors.grey.withOpacity(.2)),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brandPrimary,
        thumbColor: AppColors.brandPrimary,
        inactiveTrackColor: divider,
        overlayColor: AppColors.brandPrimary.withOpacity(.12),
      ),

      // Divider
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 0.5),

      // Typography
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: text, letterSpacing: -.5),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: text, letterSpacing: -.3),
        titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text),
        titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: text),
        bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: text, height: 1.6),
        bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: text, height: 1.5),
        bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textSec),
        labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: text),
        labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSec, letterSpacing: .04),
      ),
    );
  }
}

// ── Extensões de contexto ────────────────────────────────────

extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get cardColor  => isDark ? AppColors.cardDark : Colors.white;
  Color get bgColor    => isDark ? AppColors.backgroundDark : AppColors.background;
  Color get textColor  => isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
  Color get textSecColor => isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get divColor   => isDark ? AppColors.dividerDark : AppColors.divider;
  Color get surfColor  => isDark ? AppColors.surfaceDark : AppColors.surface;
}
