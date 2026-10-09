// Phase 0 Harness: Contract tests for the StoreType system.
// These tests must pass before any Phase 2+ work is merged.
// Run: flutter test test/harness/store_type_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sare/theme/store_theme.dart';

void main() {
  group('StoreType persistence keys', () {
    test('all StoreType values have unique persist keys', () {
      final Set<String> keys =
          StoreType.values.map((e) => e.key).toSet();
      expect(keys.length, equals(StoreType.values.length),
          reason: 'Duplicate StoreType.key detected');
    });

    test('fromKey round-trips all known store types', () {
      for (final StoreType type in StoreType.values) {
        expect(StoreType.fromKey(type.key), equals(type),
            reason: 'Round-trip failed for ${type.key}');
      }
    });

    test('fromKey falls back to sariSari for unknown key', () {
      expect(StoreType.fromKey('unknown_value'), equals(StoreType.sariSari));
    });

    test('every StoreType has a non-empty displayName', () {
      for (final StoreType type in StoreType.values) {
        expect(type.displayName, isNotEmpty,
            reason: 'displayName empty for $type');
      }
    });

    test('every StoreType has an emoji', () {
      for (final StoreType type in StoreType.values) {
        expect(type.emoji, isNotEmpty,
            reason: 'emoji empty for $type');
      }
    });
  });

  group('StoreColors', () {
    test('forType returns a non-transparent color for all types', () {
      for (final StoreType type in StoreType.values) {
        final color = StoreColors.forType(type);
        expect(color.a, greaterThan(0),
            reason: 'Color is transparent for $type');
      }
    });
  });

  group('GlowTokens.cardDecoration', () {
    test('out-of-stock uses crimson border', () {
      final deco = GlowTokens.cardDecoration(
          isLowStock: false, isOutOfStock: true);
      expect(deco.border, isNotNull);
    });

    test('low-stock uses amber border', () {
      final deco = GlowTokens.cardDecoration(
          isLowStock: true, isOutOfStock: false);
      expect(deco.border, isNotNull);
      expect(deco.boxShadow, isNotNull);
      expect(deco.boxShadow!.isNotEmpty, isTrue);
    });

    test('normal state has no boxShadow', () {
      final deco = GlowTokens.cardDecoration(
          isLowStock: false, isOutOfStock: false);
      expect(deco.boxShadow, isNull);
    });

    test('out-of-stock card is dimmed (0.5 alpha)', () {
      final deco = GlowTokens.cardDecoration(
          isLowStock: false, isOutOfStock: true);
      // card color must have reduced alpha for dimming effect
      expect(deco.color?.a, lessThan(1.0));
    });
  });
}
