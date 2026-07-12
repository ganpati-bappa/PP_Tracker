import 'package:flutter/material.dart';

/// Centralized design system for the app.
///
/// Holds the colour palette, gradients, typography scale, spacing tokens,
/// radii, elevations and the assembled [ThemeData]. Everything visual should
/// reference these tokens so the app stays cohesive.
///
/// Visual language: warm, feminine and premium — soft blush/ivory backgrounds,
/// a dusty-rose brand, plum depth and a champagne-gold accent. Calm, welcoming
/// and trustworthy, made for a modern women's health & wellness companion.
class AppColors {
  AppColors._();

  // Surfaces & background — warm ivory / blush neutrals
  static const Color background = Color(0xFFFBF3F1); // solid fallback for the
  // background gradient (see [AppGradients.background])
  static const Color surface = Color(0xFFFFFDFC); // warm white
  static const Color surfaceAlt = Color(0xFFF7EBEC); // soft blush tint

  // Glass — translucent warm fills/borders for frosted surfaces (navbar)
  static const Color glassFill = Color(0xE6FFFDFC); // warm white @ ~90%
  static const Color glassBorder = Color(0x80FFFFFF); // white @ 50%
  static const Color hairline = Color(0xFFF0E2E4); // soft warm 1px border

  // Brand — dusty rose → plum
  static const Color primary = Color(0xFFC4677F); // dusty rose
  static const Color primarySoft = Color(0xFFF6E1E7); // blush wash
  static const Color primaryDeep = Color(0xFF934C67); // plum-rose
  static const Color accent = Color(0xFFD6A15E); // champagne gold (premium)

  // Text — warm plum-browns for a soft, high-contrast read on cream
  static const Color textPrimary = Color(0xFF3B2A31); // deep plum-brown
  static const Color textSecondary = Color(0xFF7C636C); // muted mauve-taupe
  static const Color textTertiary = Color(0xFFAD98A0);

  // Cycle phase colours — warm, harmonious, still clearly distinct.
  // Each has a deep variant for legible text/icons on light surfaces.
  static const Color menstrual = Color(0xFFD75F79); // rose-red
  static const Color menstrualDeep = Color(0xFFA83E58);
  static const Color follicular = Color(0xFF8FA97E); // soft sage
  static const Color follicularDeep = Color(0xFF5E7A4D);
  static const Color ovulation = Color(0xFFE0A55E); // warm gold
  static const Color ovulationDeep = Color(0xFFB27B33);
  static const Color luteal = Color(0xFFA986B5); // soft mauve
  static const Color lutealDeep = Color(0xFF7C5B8B);
  static const Color fertile = Color(0xFFE68D77); // warm coral
  static const Color fertileDeep = Color(0xFFC1614A);

  // Functional
  static const Color success = Color(0xFF7FA06E); // sage
  static const Color warning = Color(0xFFE0A55E); // gold
  static const Color danger = Color(0xFFD75F79); // rose-red
  static const Color water = Color(0xFF6DA8A3); // muted dusty teal
  static const Color sleep = Color(0xFFA986B5); // mauve
  static const Color divider = Color(0xFFF0E2E4);

  /// Colour-with-alpha helper that avoids the deprecated `withOpacity`.
  static Color alpha(Color c, double a) => c.withValues(alpha: a);

  /// Darken a colour in HSL space — handy for icon-chip gradients and text.
  static Color darken(Color c, [double amount = 0.10]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  /// Lighten a colour in HSL space.
  static Color lighten(Color c, [double amount = 0.10]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

/// Reusable gradients. Keep gradient definitions here so hero surfaces,
/// buttons and the app background stay consistent.
class AppGradients {
  AppGradients._();

  /// App background — a soft warm wash from ivory into blush and faint mauve.
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFDF7F4), Color(0xFFFBEFF0), Color(0xFFF7EEF3)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Primary brand gradient (buttons, hero surfaces) — rose → plum.
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFCE6E88), Color(0xFF934C67)],
  );

  /// A deeper plum variant for large brand surfaces.
  static const LinearGradient brandDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB4577A), Color(0xFF6F3A55)],
  );

  /// A warm "sunrise" gradient (peach → rose → mauve) for premium moments
  /// like the daily affirmation.
  static const LinearGradient sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE99A86), Color(0xFFC97192), Color(0xFF9A6BA0)],
  );

  /// A subtle sheen used to fake light hitting frosted glass.
  static LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withValues(alpha: 0.80),
      Colors.white.withValues(alpha: 0.50),
    ],
  );

  /// A soft phase-coloured wash for a given phase colour (light → lighter).
  static LinearGradient phaseWash(Color phaseColor) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          phaseColor.withValues(alpha: 0.20),
          phaseColor.withValues(alpha: 0.06),
        ],
      );
}

class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}

/// Soft, warm-tinted shadows for a gentle floating feel. Each is a layered set:
/// a tight contact shadow for definition plus a wide rose glow for depth.
class AppShadows {
  AppShadows._();

  static const Color _deep = Color(0xFF3B2A31); // warm plum-brown
  static const Color _rose = Color(0xFFC4677F); // brand rose

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: _rose.withValues(alpha: 0.12),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: _deep.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: _rose.withValues(alpha: 0.10),
          blurRadius: 40,
          spreadRadius: -6,
          offset: const Offset(0, 20),
        ),
      ];

  static List<BoxShadow> get lifted => [
        BoxShadow(
          color: _deep.withValues(alpha: 0.10),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: _rose.withValues(alpha: 0.22),
          blurRadius: 36,
          spreadRadius: -4,
          offset: const Offset(0, 18),
        ),
      ];

  /// A vivid coloured glow for brand/phase surfaces (e.g. the hero card, CTAs).
  static List<BoxShadow> glow([Color color = _rose]) => [
        BoxShadow(
          color: color.withValues(alpha: 0.32),
          blurRadius: 30,
          spreadRadius: -4,
          offset: const Offset(0, 14),
        ),
      ];
}

class AppDuration {
  AppDuration._();
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 550);
}

/// Typography tuned for a modern, premium, softly-editorial feel: gentle
/// negative tracking on large text, clear medium-weight body, warm neutral
/// colours, roomy line-heights.
///
/// Uses the bundled Roboto so there's no runtime font fetch. For an even more
/// premium feel, add `google_fonts` and swap [_family] for a humanist serif
/// display (e.g. 'Fraunces' / 'Cormorant') paired with a soft sans body.
class AppText {
  AppText._();

  static const String _family = 'Roboto';

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    height: 1.1,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.3,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
    letterSpacing: 0.2,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textTertiary,
    letterSpacing: 1.4,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
        fontFamily: AppText._family,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      splashColor: AppColors.alpha(AppColors.primary, 0.06),
      highlightColor: AppColors.alpha(AppColors.primary, 0.04),
      dividerColor: AppColors.divider,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
    );
  }
}

/// Paints the app's gradient background behind its [child].
///
/// Use it as the outermost widget of a screen/shell (with a transparent
/// Scaffold) so the warm wash shows through the content and floating surfaces.
class AppBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  const AppBackground({super.key, required this.child, this.gradient});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient ?? AppGradients.background),
      child: child,
    );
  }
}
