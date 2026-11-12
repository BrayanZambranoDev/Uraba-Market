import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../theme/app_theme.dart';

/// Premium SnackBar helper. Floating, rounded, icon-led, with accent border.
enum AppSnackType { success, error, info, warning }

class AppSnack {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    Color color;
    IconData icon;
    switch (type) {
      case AppSnackType.success:
        color = AppTheme.success;
        icon = Iconsax.tick_circle;
        break;
      case AppSnackType.error:
        color = AppTheme.error;
        icon = Iconsax.close_circle;
        break;
      case AppSnackType.warning:
        color = AppTheme.warning;
        icon = Iconsax.warning_2;
        break;
      case AppSnackType.info:
      default:
        color = AppTheme.info;
        icon = Iconsax.info_circle;
        break;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: EdgeInsets.zero,
        duration: duration,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  static void success(BuildContext c, String m, {Duration? duration}) =>
      show(c, message: m, type: AppSnackType.success, duration: duration ?? const Duration(seconds: 3));

  static void error(BuildContext c, String m, {Duration? duration}) =>
      show(c, message: m, type: AppSnackType.error, duration: duration ?? const Duration(seconds: 3));

  static void info(BuildContext c, String m, {Duration? duration}) =>
      show(c, message: m, type: AppSnackType.info, duration: duration ?? const Duration(seconds: 3));

  static void warning(BuildContext c, String m, {Duration? duration}) =>
      show(c, message: m, type: AppSnackType.warning, duration: duration ?? const Duration(seconds: 3));
}
