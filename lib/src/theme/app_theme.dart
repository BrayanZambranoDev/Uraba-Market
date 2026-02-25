import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colores principales (FUENTE ÚNICA DE VERDAD) ───
  static const Color orange = Color(0xFFF97316);
  static const Color orangeDark = Color(0xFFEA580C);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFF22C55E);
  static const Color greenDark = Color(0xFF15803D);

  // ─── Fondos ───
  static const Color bg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color inputBg = Color(0xFFF8FAFC);

  // ─── Texto ───
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Colors.white;

  // ─── Bordes ───
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFE0E0E0);

  // ─── Estado ───
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Categorías (colores de fondo + accent) ───
  static const Map<String, Map<String, dynamic>> categoryStyles = {
    'Frutas': {
      'color': Color(0xFFFEF3C7),
      'accent': Color(0xFFF59E0B),
      'icon': Icons.eco_rounded,
    },
    'Verduras': {
      'color': Color(0xFFDCFCE7),
      'accent': Color(0xFF16A34A),
      'icon': Icons.grass_rounded,
    },
    'Artesanías': {
      'color': Color(0xFFFFEDD5),
      'accent': Color(0xFFF97316),
      'icon': Icons.palette_rounded,
    },
    'Gastronomía': {
      'color': Color(0xFFFCE7F3),
      'accent': Color(0xFFEC4899),
      'icon': Icons.restaurant_rounded,
    },
    'Otros': {
      'color': Color(0xFFF1F5F9),
      'accent': Color(0xFF64748B),
      'icon': Icons.inventory_2_rounded,
    },
  };

  static Map<String, dynamic> getCategoryStyle(String? cat) {
    return categoryStyles[cat] ??
        {
          'color': const Color(0xFFF1F5F9),
          'accent': const Color(0xFF64748B),
          'icon': Icons.inventory_2_rounded,
        };
  }

  // ─── Gradientes ───
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF15803D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Sombras ───
  static BoxShadow shadowSmall = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMedium = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static BoxShadow shadowOrange = BoxShadow(
    color: orange.withValues(alpha: 0.35),
    blurRadius: 16,
    offset: const Offset(0, 6),
  );

  // ─── Bordes redondeados ───
  static BorderRadius radiusS = BorderRadius.circular(8);
  static BorderRadius radiusM = BorderRadius.circular(12);
  static BorderRadius radiusL = BorderRadius.circular(16);
  static BorderRadius radiusXL = BorderRadius.circular(20);

  // ─── Estilos de texto reutilizables ───
  static TextStyle heading1 = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static TextStyle heading2 = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );

  static TextStyle heading3 = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle subtitle = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static TextStyle bodyMuted = GoogleFonts.plusJakartaSans(
    fontSize: 13,
    color: textMuted,
  );

  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 11,
    color: textMuted,
  );

  static TextStyle label = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF374151),
  );

  static TextStyle buttonText = GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: textWhite,
  );

  // ─── InputDecoration reutilizable ───
  static InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        color: textMuted,
      ),
      prefixIcon: Icon(icon, color: textMuted, size: 19),
      filled: true,
      fillColor: inputBg,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: green, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radiusM,
        borderSide: const BorderSide(color: error, width: 2),
      ),
      errorStyle: GoogleFonts.plusJakartaSans(fontSize: 10),
    );
  }

  // ─── Tema Material completo ───
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        brightness: Brightness.light,
        primary: orange,
        secondary: green,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor: orange,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textWhite,
        ),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radiusM,
          borderSide: const BorderSide(color: green, width: 2),
        ),
      ),
    );
  }
}
