import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// URABÁ MARKET — "Rutas de la Abundancia" Design System
// Deep jungle night + mint green + gold accent.
// ═══════════════════════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ─── Primary: Mint Green (accent on dark bg) ───────────────────────────────
  static const Color primary = Color(0xFF72C46A);
  static const Color primaryDark = Color(0xFF1A4A12);
  static const Color primaryMid = Color(0xFF459434);
  static const Color primaryPale = Color(0xFF182E2A);

  // Backward compat aliases
  static const Color orange = Color(0xFF72C46A);
  static const Color orangeDark = Color(0xFF1A4A12);
  static const Color orangeLight = Color(0xFF8DE87A);
  static const Color orangePale = Color(0xFF182E2A);

  // ─── Active Green ──────────────────────────────────────────────────────────
  static const Color green = Color(0xFF72C46A);
  static const Color greenLight = Color(0xFF8DE87A);
  static const Color greenDark = Color(0xFF459434);
  static const Color greenPale = Color(0xFF0D231F);

  // ─── Gold Accent ───────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFF0C12E);
  static const Color goldDark = Color(0xFFCFA300);

  // ─── Regional Accents ──────────────────────────────────────────────────────
  static const Color banano = Color(0xFFF0C12E);      // Warnings / offers
  static const Color cacao = Color(0xFFFFB59C);       // Warm accent
  static const Color cacaoLight = Color(0xFFFFDBCF);
  static const Color cacaoDark = Color(0xFFA6583D);
  static const Color golfo = Color(0xFF72C46A);       // Info / links
  static const Color golfoDark = Color(0xFF459434);
  static const Color tierra = Color(0xFFF0C12E);

  // ─── Dark Surface Palette ──────────────────────────────────────────────────
  static const Color bg = Color(0xFF011713);           // Deep jungle night
  static const Color background = Color(0xFF011713);
  static const Color surface = Color(0xFF182E2A);      // Surface container
  static const Color cardBg = Color(0xFF233934);       // Card background (visible on bg)
  static const Color surfaceHigh = Color(0xFF273D39);  // Surface container high
  static const Color surfaceBright = Color(0xFF2F4540);
  static const Color inputBg = Color(0xFF1C3330);      // Input fill

  // ─── Text (light on dark bg) ───────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFCEE8E1);     // on-surface
  static const Color textSecondary = Color(0xFFBFC9C0);   // on-surface-variant
  static const Color textMuted = Color(0xFF8A938B);       // outline
  static const Color textDisabled = Color(0xFF404942);
  static const Color textWhite = Colors.white;

  // ─── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF404942);
  static const Color borderLight = Color(0xFF2D3A35);

  // ─── Status ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFF5252);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color success = Color(0xFF72C46A);
  static const Color warning = Color(0xFFF0C12E);
  static const Color info = Color(0xFF48CAE4);

  // ─── Category Styles (dark bg variants) ───────────────────────────────────
  static const Map<String, Map<String, dynamic>> categoryStyles = {
    'Frutas': {
      'color': Color(0xFF0D231F),
      'accent': Color(0xFF72C46A),
      'icon': Iconsax.tree,
    },
    'Verduras': {
      'color': Color(0xFF182E2A),
      'accent': Color(0xFF72C46A),
      'icon': Iconsax.tree,
    },
    'Artesanías': {
      'color': Color(0xFF1A1800),
      'accent': Color(0xFFF0C12E),
      'icon': Iconsax.brush,
    },
    'Gastronomía': {
      'color': Color(0xFF1A0E0C),
      'accent': Color(0xFFFFB59C),
      'icon': Iconsax.coffee,
    },
    'Otros': {
      'color': Color(0xFF182E2A),
      'accent': Color(0xFFBFC9C0),
      'icon': Iconsax.box,
    },
  };

  static Map<String, dynamic> getCategoryStyle(String? cat) {
    return categoryStyles[cat] ??
        {
          'color': const Color(0xFF182E2A),
          'accent': const Color(0xFFBFC9C0),
          'icon': Iconsax.box,
        };
  }

  // ─── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFF459434), Color(0xFF011713)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF011713), Color(0xFF0D231F), Color(0xFF182E2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF459434), Color(0xFF011713)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF011713), Color(0xFF0D231F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroHeaderGradient = LinearGradient(
    colors: [Color(0xFF011713), Color(0xFF0D231F), Color(0xFF182E2A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amanecerGradient = LinearGradient(
    colors: [Color(0xFF459434), Color(0xFF011713)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient golfoGradient = LinearGradient(
    colors: [Color(0xFF459434), Color(0xFF0D231F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ───────────────────────────────────────────────────────────────
  static const Color _shadowColor = Color(0xFF000000);

  static BoxShadow shadowSmall = BoxShadow(
    color: _shadowColor.withValues(alpha: 0.30),
    blurRadius: 10,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMedium = BoxShadow(
    color: _shadowColor.withValues(alpha: 0.40),
    blurRadius: 24,
    offset: const Offset(0, 8),
    spreadRadius: -2,
  );

  static BoxShadow shadowOrange = BoxShadow(
    color: primary.withValues(alpha: 0.20),
    blurRadius: 24,
    offset: const Offset(0, 8),
    spreadRadius: -2,
  );

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.30),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.15),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.40),
          blurRadius: 28,
          offset: const Offset(0, 10),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.20),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.50),
          blurRadius: 48,
          offset: const Offset(0, 20),
          spreadRadius: -6,
        ),
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowOrangeList => [
        BoxShadow(
          color: primary.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.10),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowSelvaList => [
        BoxShadow(
          color: primary.withValues(alpha: 0.30),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -2,
        ),
        BoxShadow(
          color: primary.withValues(alpha: 0.12),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // ─── Border Radius ─────────────────────────────────────────────────────────
  static BorderRadius radiusS = BorderRadius.circular(10);
  static BorderRadius radiusM = BorderRadius.circular(14);
  static BorderRadius radiusL = BorderRadius.circular(20);
  static BorderRadius radiusXL = BorderRadius.circular(28);
  static BorderRadius radiusFull = BorderRadius.circular(999);

  // ─── Spacing Scale ─────────────────────────────────────────────────────────
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceBase = 16;
  static const double spaceLg = 20;
  static const double spaceXl = 24;
  static const double space2xl = 32;
  static const double space3xl = 40;
  static const double space4xl = 48;
  static const double space5xl = 64;

  // ─── Animation Tokens ──────────────────────────────────────────────────────
  static const Duration animInstant = Duration(milliseconds: 100);
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSmooth = Duration(milliseconds: 400);
  static const Duration animDramatic = Duration(milliseconds: 600);
  static const Duration animSpring = Duration(milliseconds: 800);

  static const Curve curveDefault = Curves.easeOut;
  static const Curve curveSmooth = Curves.easeInOutCubic;
  static const Curve curveDramatic = Curves.easeOutCubic;
  static const Curve curveSpring = Curves.elasticOut;

  // ─── Typography ────────────────────────────────────────────────────────────
  static TextStyle get displayHero => GoogleFonts.dmSerifDisplay(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.1,
        letterSpacing: -0.5,
      );

  static TextStyle get displayLg => GoogleFonts.dmSerifDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.15,
        letterSpacing: -0.3,
      );

  static TextStyle get displayMd => GoogleFonts.dmSerifDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.2,
      );

  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.2,
        letterSpacing: -0.3,
      );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        height: 1.25,
        letterSpacing: -0.2,
      );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get subtitle => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.5,
      );

  static TextStyle get bodyMuted => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMuted,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMuted,
        height: 1.4,
      );

  static TextStyle get label => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get buttonText => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get overline => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: textMuted,
        letterSpacing: 1.2,
        height: 1.4,
      );

  // ─── Page Transition ──────────────────────────────────────────────────────
  static PageRouteBuilder<T> pageRoute<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 290),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curved),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.7, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ─── Input Decoration ──────────────────────────────────────────────────────
  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMuted),
      prefixIcon: Icon(icon, color: textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: inputBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: error, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: error),
    );
  }

  // ─── Material Theme ────────────────────────────────────────────────────────
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: gold,
        error: error,
        surface: surface,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSerifDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: error, width: 2),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: error),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusFull),
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: radiusFull),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL.topLeft.x)),
        ),
        showDragHandle: true,
        dragHandleColor: border,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radiusM),
        backgroundColor: surfaceHigh,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
