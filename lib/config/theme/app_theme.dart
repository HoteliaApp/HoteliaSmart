import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════════════════════
//  HOTELIA DESIGN SYSTEM — SMART TV (solo modo oscuro)
//  Copia sincronizada con HoteliaMovil/lib/config/theme/app_theme.dart,
//  con escala tipográfica y espaciado adaptados a pantalla de TV.
// ════════════════════════════════════════════════════════════════════════════

/// Paleta de colores de marca y neutros.
class AppColors {
  AppColors._();

  // ── Marca ──
  static const Color primary = Color(0xFFFF661A);
  static const Color primaryDark = Color(0xFFD4510E);
  static const Color secondary = Color(0xFFEFB49F);

  // ── Neutros modo claro (mantenidos por paridad de tokens) ──
  static const Color backgroundLight = Color(0xFFF0F0F0);
  static const Color surface = Color(0xFFF2F2F2);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Neutros modo oscuro ──
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF303030);
  static const Color cardDark = backgroundDark;
  static const Color success = Color(0xFF4CAF50);

  // ── Paleta de estados semánticos (modo claro) ──
  static const Color statusSuccessLight = Color(0xFF2E7D32);
  static const Color statusInfoLight = Color(0xFF1565C0);
  static const Color statusWarningLight = Color(0xFFE65100);
  static const Color statusDangerLight = Color(0xFFC62828);
  static const Color statusPurpleLight = Color(0xFF6A1B9A);
  static const Color statusNeutralLight = Color(0xFF616161);

  // ── Paleta de estados semánticos (modo oscuro) ──
  static const Color statusSuccessDark = Color(0xFF81C784);
  static const Color statusInfoDark = Color(0xFF64B5F6);
  static const Color statusWarningDark = Color(0xFFFFB74D);
  static const Color statusDangerDark = Color(0xFFE57373);
  static const Color statusPurpleDark = Color(0xFFBA68C8);
  static const Color statusNeutralDark = Color(0xFFB0BEC5);
}

/// Colores semánticos de estado (TV siempre opera en tema oscuro).
class AppStatusColors {
  final Color success;
  final Color info;
  final Color warning;
  final Color danger;
  final Color purple;
  final Color neutral;

  const AppStatusColors({
    required this.success,
    required this.info,
    required this.warning,
    required this.danger,
    required this.purple,
    required this.neutral,
  });

  static AppStatusColors of(BuildContext context) => dark;

  static const light = AppStatusColors(
    success: AppColors.statusSuccessLight,
    info: AppColors.statusInfoLight,
    warning: AppColors.statusWarningLight,
    danger: AppColors.statusDangerLight,
    purple: AppColors.statusPurpleLight,
    neutral: AppColors.statusNeutralLight,
  );

  static const dark = AppStatusColors(
    success: AppColors.statusSuccessDark,
    info: AppColors.statusInfoDark,
    warning: AppColors.statusWarningDark,
    danger: AppColors.statusDangerDark,
    purple: AppColors.statusPurpleDark,
    neutral: AppColors.statusNeutralDark,
  );
}

/// Radios de borde. El estándar de la marca es [md] (16).
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;

  static final BorderRadius smAll = BorderRadius.circular(sm);
  static final BorderRadius mdAll = BorderRadius.circular(md);
  static final BorderRadius lgAll = BorderRadius.circular(lg);
}

/// Escala de espaciado (múltiplos de 4).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const EdgeInsets screen = EdgeInsets.all(xl);
}

/// Tamaños de íconos para Smart TV.
class AppIconSize {
  AppIconSize._();

  static const double xs = 16;
  static const double sm = 22;
  static const double md = 26;
  static const double lg = 32;
  static const double hero = 64;
}

/// Opacidades estándar para tintes de color semántico.
class AppAlpha {
  AppAlpha._();

  static const double tint = 0.08;
  static const double badge = 0.12;
  static const double border = 0.25;
  static const double borderDark = 0.35;
}

/// Sombras estándar.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.22),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}

/// Clase que gestiona el tema de Smart TV (siempre oscuro de marca Hotelia).
class AppTheme {
  final bool isDarkMode;

  const AppTheme({this.isDarkMode = true});

  static TextTheme _tvTypography() {
    final m3 = Typography.material2021();
    final fullDark = m3.englishLike.merge(m3.white);
    final base = GoogleFonts.poppinsTextTheme(
      fullDark,
    ).apply(fontSizeFactor: 1.35);

    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static final TextTheme _poppinsDark = _tvTypography();
  static final RoundedRectangleBorder _shape = RoundedRectangleBorder(
    borderRadius: AppRadius.mdAll,
  );

  ThemeData getTheme() => _darkTheme;

  static final ThemeData _darkTheme = _buildDark();

  static ThemeData _buildDark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF8C3000),
      onPrimaryContainer: AppColors.secondary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFF5D3728),
      onSecondaryContainer: AppColors.secondary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.backgroundLight,
      surfaceContainerLowest: Color(0xFF0F0F0F),
      surfaceContainerLow: Color(0xFF1A1A1A),
      surfaceContainer: AppColors.surfaceDark,
      surfaceContainerHigh: Color(0xFF262626),
      surfaceContainerHighest: AppColors.backgroundDark,
      onSurfaceVariant: Color(0xFFBDBDBD),
      error: AppColors.statusDangerDark,
      onError: Colors.black,
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      outline: Color(0xFF555555),
      outlineVariant: Color(0xFF404040),
      shadow: Colors.black54,
      scrim: Colors.black87,
      inverseSurface: AppColors.backgroundLight,
      onInverseSurface: AppColors.backgroundDark,
      inversePrimary: Color(0xFF8C3000),
    );

    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: c, width: w),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: _poppinsDark,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      cardColor: AppColors.cardDark,
      dividerColor: const Color(0xFF404040),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _poppinsDark.titleLarge?.copyWith(
          color: AppColors.backgroundLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shape: _shape,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: _shape,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _shape,
      ),
      chipTheme: ChipThemeData(
        shape: _shape,
        side: BorderSide.none,
        labelStyle: _poppinsDark.labelMedium,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: _poppinsDark.labelLarge,
          shape: _shape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: _poppinsDark.labelLarge,
          shape: _shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          textStyle: _poppinsDark.labelLarge,
          shape: _shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: _poppinsDark.labelLarge,
          shape: _shape,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.scaffoldDark,
        border: border(const Color(0xFF555555)),
        enabledBorder: border(const Color(0xFF555555)),
        focusedBorder: border(AppColors.primary, 2),
        errorBorder: border(colorScheme.error),
        focusedErrorBorder: border(colorScheme.error, 2),
      ),
    );
  }
}
