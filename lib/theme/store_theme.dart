// Sar-E — Store type definitions and per-store brand theme tokens.
// Each store type gets its own accent color and glow palette.
// NO BackdropFilter anywhere — only BoxShadow for glow effects.

import 'package:flutter/material.dart';

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

  // Sari-Sari: Energetic Red-Orange
  static const Color sariSari = Color(0xFFC9352C);
  static const Color sariSariDark = Color(0xFF9E2920);

  // Gulay: Fresh Produce Green
  static const Color gulay = Color(0xFF2E7D32);
  static const Color gulayDark = Color(0xFF1B5E20);

  // Rice: Warm Harvest Golden Amber
  static const Color rice = Color(0xFFF57F17);
  static const Color riceDark = Color(0xFFE65100);

  // Carinderia: Savory Flame Terracotta
  static const Color carinderia = Color(0xFFD84315);
  static const Color carinderiaDark = Color(0xFFBF360C);

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
  }) {
    if (isOutOfStock) {
      return BoxDecoration(
        color: surfaceCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: outOfStockGlow.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: outOfStockGlow.withValues(alpha: 0.25),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      );
    }
    if (isLowStock) {
      return BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: lowStockGlow.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: lowStockGlow.withValues(alpha: 0.30),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      );
    }
    return BoxDecoration(
      color: surfaceCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: normalBorder, width: 1.0),
    );
  }
}

// ─── Spacing Tokens ──────────────────────────────────────────────────────────

class SpaceTokens {
  const SpaceTokens._();

  static const double pagePadding = 16.0;
  static const double cardGap = 12.0;
  static const double cardRadius = 16.0;
  static const double sheetRadius = 24.0;
  static const double chipRadius = 32.0;
  static const double iconSizeGrid = 28.0;
  static const double iconSizeBar = 24.0;
}
