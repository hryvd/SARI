// GPU-safe background: NO BackdropFilter, NO ImageFilter.blur.
// Uses solid OLED-dark fills with accent glow orbs via BoxShadow/BoxDecoration.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen background that replaces the old liquid glass approach.
/// Renders a gradient dark surface with soft ambient glow orbs using BoxDecoration
/// only — zero offscreen render buffers, zero GPU raster thrashing.
class SolidGlowBackground extends StatelessWidget {
  const SolidGlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[c.background, c.backgroundSecondary],
          ),
        ),
        child: Stack(
          children: <Widget>[
            // Top-left ambient orb — no blur, soft radial gradient only
            Positioned(
              left: -60,
              top: -50,
              child: _GlowOrb(
                color: c.primary.withValues(alpha: dark ? 0.20 : 0.10),
                size: 200,
              ),
            ),
            // Right accent orb
            Positioned(
              right: -55,
              top: 120,
              child: _GlowOrb(
                color: c.accent.withValues(alpha: dark ? 0.10 : 0.08),
                size: 170,
              ),
            ),
            // Bottom ambient orb
            Positioned(
              left: 60,
              bottom: -70,
              child: _GlowOrb(
                color: c.primaryDark.withValues(alpha: dark ? 0.16 : 0.07),
                size: 220,
              ),
            ),
            // Main content — no filter child
            child,
          ],
        ),
      ),
    );
  }
}

/// A soft radial gradient circle used as an ambient glow orb.
/// Uses a Container with a BoxDecoration gradient — no GPU offscreen buffers.
class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0.0)],
          stops: const <double>[0.0, 1.0],
        ),
      ),
    );
  }
}

// Keep old name as alias so existing import references don't break while
// we migrate files one by one.
typedef LiquidBackground = SolidGlowBackground;
