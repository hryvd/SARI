// Neutral app canvas: no backdrop filters or decorative glow layers.

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Adds a restrained brand tint behind screens hosted by the main shell.
class SolidGlowBackground extends StatelessWidget {
  const SolidGlowBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color.lerp(c.background, c.primary, 0.025)!,
              c.background,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

// Keep old name as alias so existing import references don't break while
// we migrate files one by one.
typedef LiquidBackground = SolidGlowBackground;
