import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget reusable untuk pasang background pattern (25% opacity)
/// di belakang konten screen manapun.
///
/// Cara pakai:
/// ```dart
/// body: PatternBackground(
///   child: SafeArea(
///     child: ...isi screen kamu seperti biasa...
///   ),
/// ),
/// ```
class PatternBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const PatternBackground({
    super.key,
    required this.child,
    this.opacity = 0.50,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── Layer pattern ───────────────────────────────────
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              context.isDark
                  ? 'assets/images/pattern_dark.png'
                  : 'assets/images/pattern_light.png',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // ─── Layer konten asli ───────────────────────────────
        child,
      ],
    );
  }
}