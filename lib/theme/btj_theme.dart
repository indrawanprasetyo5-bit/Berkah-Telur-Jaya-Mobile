import 'package:material_ui/material_ui.dart';

class BtjColors {
  BtjColors._();

  static const Color background = Color(0xFFFAF7F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFFFDF9);
  static const Color surfaceSubtle = Color(0xFFF3EDE3);
  static const Color border = Color(0xFFE6DDD0);
  static const Color borderStrong = Color(0xFFCFC0AC);

  static const Color primary = Color(0xFF9A3412);
  static const Color primaryPressed = Color(0xFF7C2D12);
  static const Color primarySoft = Color(0xFFFDE8D7);
  static const Color primaryTint = Color(0xFFFEF5EE);
  static const Color primaryBorder = Color(0xFFF6B88B);

  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF57534E);
  static const Color textMuted = Color(0xFF78716C);

  static const Color success = Color(0xFF15803D);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successBorder = Color(0xFF86EFAC);

  static const Color warning = Color(0xFFB45309);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color warningBorder = Color(0xFFFCD34D);

  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color dangerBorder = Color(0xFFFCA5A5);

  static const Color info = Color(0xFF1D4ED8);
  static const Color infoBg = Color(0xFFDBEAFE);
  static const Color infoBorder = Color(0xFF93C5FD);
}

class BtjTheme {
  BtjTheme._();

  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  static const List<BoxShadow> cardShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x0C1C1917),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> topBarShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x121C1917),
      blurRadius: 18,
      offset: Offset(0, -4),
    ),
  ];

  static BoxDecoration cardDecoration({
    Color color = BtjColors.surface,
    Color borderColor = BtjColors.border,
    double borderWidth = 1.0,
    double radius = 16,
    bool elevated = true,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: elevated ? cardShadow : null,
    );
  }

  static ThemeData build() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: BtjColors.primary,
      onPrimary: Colors.white,
      primaryContainer: BtjColors.primarySoft,
      onPrimaryContainer: BtjColors.primaryPressed,
      secondary: Color(0xFF44403C),
      onSecondary: Colors.white,
      secondaryContainer: BtjColors.surfaceSubtle,
      onSecondaryContainer: BtjColors.textPrimary,
      tertiary: BtjColors.warning,
      onTertiary: Colors.white,
      tertiaryContainer: BtjColors.warningBg,
      onTertiaryContainer: BtjColors.warning,
      error: BtjColors.danger,
      onError: Colors.white,
      errorContainer: BtjColors.dangerBg,
      onErrorContainer: BtjColors.danger,
      surface: BtjColors.surface,
      onSurface: BtjColors.textPrimary,
      surfaceContainerHighest: BtjColors.surfaceSubtle,
      onSurfaceVariant: BtjColors.textSecondary,
      outline: BtjColors.borderStrong,
      outlineVariant: BtjColors.border,
      shadow: Color(0x141C1917),
      scrim: Color(0x661C1917),
      inverseSurface: BtjColors.textPrimary,
      onInverseSurface: BtjColors.background,
      inversePrimary: BtjColors.primaryBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BtjColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: BtjColors.surface,
        foregroundColor: BtjColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: BtjColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        shape: Border(
          bottom: BorderSide(color: BtjColors.border, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: BtjColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BtjColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BtjColors.surfaceWarm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: BtjColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: BtjColors.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        hintStyle: const TextStyle(
          color: BtjColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: BtjColors.borderStrong,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: BtjColors.borderStrong,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BtjColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BtjColors.danger, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BtjColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BtjColors.border,
          disabledForegroundColor: BtjColors.textMuted,
          elevation: 0,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BtjColors.textPrimary,
          backgroundColor: BtjColors.surface,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: const BorderSide(color: BtjColors.borderStrong, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BtjColors.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: BtjColors.border,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BtjColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: BtjColors.primarySoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BtjColors.primaryBorder, width: 1),
        ),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            letterSpacing: -0.1,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? BtjColors.primaryPressed : BtjColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 23,
            color: isSelected ? BtjColors.primary : BtjColors.textSecondary,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BtjColors.textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
