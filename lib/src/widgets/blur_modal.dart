import 'dart:ui';
import 'package:flutter/material.dart';

/// Helpers to show modals with iOS-style backdrop blur (frosted glass).
class BlurModal {
  /// Show a modal bottom sheet with the background blurred.
  static Future<T?> bottomSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    Color barrierColor = const Color(0x66000000),
    double blurSigma = 8.0,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Stack(children: [
          // Backdrop blur layer
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(color: barrierColor),
              ),
            ),
          ),
          // Actual sheet content
          builder(ctx),
        ]);
      },
    );
  }

  /// Show a dialog with the background blurred.
  static Future<T?> dialog<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    Color barrierColor = const Color(0x99000000),
    double blurSigma = 6.0,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'dialog',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim, _) {
        return Stack(children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: barrierDismissible ? () => Navigator.of(ctx).pop() : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: blurSigma * anim.value,
                  sigmaY: blurSigma * anim.value,
                ),
                child: Container(color: barrierColor),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
                child: builder(ctx),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
