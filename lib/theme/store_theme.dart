// SARI — Store type definitions and per-store brand theme tokens.
// Each store type gets its own accent color and glow palette.
// NO BackdropFilter anywhere — only BoxShadow for glow effects.

import 'package:flutter/material.dart';

import 'app_theme.dart';

// ─── Store Type Enum ────────────────────────────────────────────────────────

enum StoreType {
  sariSari,
  gulay,
  rice,
  carinderia;

  /// Persisted value used in SharedPreferences and the DB store_type column.
  String get key => switch (this) {
        StoreType.sariSari => 'sari_sari',
        StoreType.gulay => 'gulay',
        StoreType.rice => 'rice',
        StoreType.carinderia => 'carinderia',
      };

  static StoreType fromKey(String key) => switch (key) {
        'gulay' => StoreType.gulay,
        'rice' => StoreType.rice,
        'carinderia' => StoreType.carinderia,
        _ => StoreType.sariSari,
      };

  String get displayName => switch (this) {
        StoreType.sariSari => 'Sari-Sari Store',
        StoreType.gulay => 'Gulay / Palengke',
        StoreType.rice => 'Bigasan / Rice Store',
        StoreType.carinderia => 'Carinderia',
      };

  String get emoji => switch (this) {
        StoreType.sariSari => '🏪',
        StoreType.gulay => '🥬',
        StoreType.rice => '🌾',
        StoreType.carinderia => '🍚',
      };

  String get tagline => switch (this) {
        StoreType.sariSari => 'Scan, sell & track inventory',
        StoreType.gulay => 'Kilo pricing & portion advisor',
        StoreType.rice => 'Rice bins with printable QR labels',
        StoreType.carinderia => 'Kiosk combos & daily portions',
      };
}

// ─── Per-Store Brand Colors ──────────────────────────────────────────────────

class StoreColors {
  const StoreColors._();

  static const Color sariSari = brandRed;
  static const Color sariSariDark = brandRed;
  static const Color gulay = brandRed;
  static const Color gulayDark = brandRed;
  static const Color rice = brandRed;
  static const Color riceDark = brandRed;
  static const Color carinderia = brandRed;
  static const Color carinderiaDark = brandRed;

  static Color forType(StoreType type) => switch (type) {
        StoreType.sariSari => sariSari,
        StoreType.gulay => gulay,
        StoreType.rice => rice,
        StoreType.carinderia => carinderia,
      };

  static Color darkForType(StoreType type) => switch (type) {
        StoreType.sariSari => sariSariDark,
        StoreType.gulay => gulayDark,
        StoreType.rice => riceDark,
        StoreType.carinderia => carinderiaDark,
      };
}

// ─── Glow Theme Tokens ───────────────────────────────────────────────────────

/// Glow states for item boxes in the inventory grid.
/// RULE: Only BoxShadow — never BackdropFilter or blur.
class GlowTokens {
  const GlowTokens._();

  // Stock status glow colors
  static const Color lowStockGlow = Color(0xFFFFB300); // Amber
  static const Color outOfStockGlow = Color(0xFFE53935); // Crimson
  static const Color normalBorder = Color(0xFF2D333B); // Slate border

  // Surface / background
  static const Color surfaceCard = Color(0xFF1E2228);
  static const Color surfaceBackground = Color(0xFF121417);

  static BoxDecoration cardDecoration({
    required bool isLowStock,
    required bool isOutOfStock,
    Color? overrideAccent,
    Color? surfaceColor,
    Color? borderColor,
  }) {
    final Color baseSurface = surfaceColor ?? surfaceCard;
    final Color baseBorder = borderColor ?? normalBorder;

    if (isOutOfStock) {
      return BoxDecoration(
        color: baseSurface.withValues(alpha: surfaceColor != null ? 0.75 : 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: outOfStockGlow.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: outOfStockGlow.withValues(alpha: 0.20),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      );
    }
    if (isLowStock) {
      return BoxDecoration(
        color: baseSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lowStockGlow.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: lowStockGlow.withValues(alpha: 0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: baseSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: baseBorder, width: 1.0),
    );
  }
}

// ─── Spacing Tokens ──────────────────────────────────────────────────────────

class SpaceTokens {
  const SpaceTokens._();

  static const double pagePadding = 16.0;
  static const double cardGap = 12.0;
  static const double cardRadius = 8.0;
  static const double sheetRadius = 24.0;
  static const double chipRadius = 32.0;
  static const double iconSizeGrid = 28.0;
  static const double iconSizeBar = 24.0;
}
