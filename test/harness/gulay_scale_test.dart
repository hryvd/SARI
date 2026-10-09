import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sare/application/inventory_provider.dart';
import 'package:sare/domain/adapters/gulay_adapter.dart';
import 'package:sare/domain/entities/product.dart';
import 'package:sare/domain/services/portion_advisor.dart';
import 'package:sare/domain/services/scale_calculator.dart';
import 'package:sare/screens/gulay/gulay_pos.dart';

void main() {
  group('Gulay Scale Pricing & Arithmetic (Phase 4 Spec Checks)', () {
    test('ScaleCalculator: 1.8 kg × ₱65.00/kg = ₱117.00 (exact, no floating-point error)', () {
      final double price = ScaleCalculator.computePrice(
        weightKg: 1.8,
        pricePerKg: 65.0,
      );
      expect(price, equals(117.00));
    });

    test('ScaleCalculator: 1.25 kg × ₱140.00/kg = ₱175.00 (exact)', () {
      final double price = ScaleCalculator.computePrice(
        weightKg: 1.25,
        pricePerKg: 140.0,
      );
      expect(price, equals(175.00));
    });

    test('ScaleCalculator: 0.25 kg × ₱80.00/kg = ₱20.00 (exact)', () {
      final double price = ScaleCalculator.computePrice(
        weightKg: 0.25,
        pricePerKg: 80.0,
      );
      expect(price, equals(20.00));
    });

    test('ScaleCalculator: 1.0 kg × ₱90.00/kg = ₱90.00 (exact)', () {
      final double price = ScaleCalculator.computePrice(
        weightKg: 1.0,
        pricePerKg: 90.0,
      );
      expect(price, equals(90.00));
    });

    test('ScaleCalculator: Weight of 0.0 kg returns ₱0.00', () {
      final double price = ScaleCalculator.computePrice(
        weightKg: 0.0,
        pricePerKg: 150.0,
      );
      expect(price, equals(0.00));
    });

    test('ScaleCalculator: Negative weight is rejected', () {
      expect(
        () => ScaleCalculator.computePrice(
          weightKg: -1.5,
          pricePerKg: 60.0,
        ),
        throwsArgumentError,
      );
    });

    test('ScaleCalculator standardPresets contain 0.25, 0.5, 1.0, 1.2, 1.8 kg', () {
      expect(ScaleCalculator.standardPresets, contains(0.25));
      expect(ScaleCalculator.standardPresets, contains(0.5));
      expect(ScaleCalculator.standardPresets, contains(1.0));
      expect(ScaleCalculator.standardPresets, contains(1.2));
      expect(ScaleCalculator.standardPresets, contains(1.8));
    });
  });

  group('Dynamic Portion Advisor (Phase 4 Spec Checks)', () {
    test('Portion hint for 1.8 kg sitaw reads "Pang 6-8 katao"', () {
      final String? hint = PortionAdvisor.getHint(
        produceName: 'Sitaw (Stringbeans)',
        weightKg: 1.8,
      );
      expect(hint, isNotNull);
      expect(hint, contains('Pang 6-8 katao'));
    });

    test('Portion hint for 1.0 kg kalabasa with Pinakbet recipe reads "Pang 3-5 katao sa Pinakbet"', () {
      final String? hint = PortionAdvisor.getHint(
        produceName: 'Kalabasa',
        weightKg: 1.0,
        recipeHint: 'Pinakbet',
      );
      expect(hint, isNotNull);
      expect(hint, contains('Pang 3-5 katao'));
      expect(hint, contains('Pinakbet'));
    });

    test('Weight of 0.0 kg returns null portion hint', () {
      final String? hint = PortionAdvisor.getHint(
        produceName: 'Talong',
        weightKg: 0.0,
      );
      expect(hint, isNull);
    });

    test('Aromatics (Sibuyas, Bawang) display aromatic batch hint', () {
      final String? hint = PortionAdvisor.getHint(
        produceName: 'Sibuyas Pula',
        weightKg: 0.5,
      );
      expect(hint, isNotNull);
      expect(hint, contains('Pampalasa'));
    });
  });

  group('Gulay Adapter Contract Checks', () {
    test('GulayAdapter requires weight input and NO barcode', () {
      const GulayAdapter adapter = GulayAdapter();
      expect(adapter.requiresBarcode, isFalse);
      expect(adapter.requiresWeightInput, isTrue);
      expect(adapter.hasComboEngine, isFalse);
    });

    testWidgets('GulayPosScreen opens scale dialog, selects 1.8kg preset, shows portion hint and exact price',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          inventoryProvider.overrideWith(
            () => _MockInventoryNotifier(<Product>[
              Product(
                productId: 'P_SITAW',
                name: 'Sitaw (Stringbeans)',
                unitPrice: 65.0,
                costPrice: 45.0,
                stockQty: 20,
                threshold: 5,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                categoryName: 'Gulay',
              ),
            ]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: GulayPosScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Sitaw card and tap it
      expect(find.text('Sitaw (Stringbeans)'), findsOneWidget);
      await tester.tap(find.text('Sitaw (Stringbeans)'));
      await tester.pumpAndSettle();

      // Tap 1.8 kg preset chip
      expect(find.text('1.8 kg'), findsOneWidget);
      await tester.tap(find.text('1.8 kg'));
      await tester.pumpAndSettle();

      // Verify computed price ₱117.00 (1.8 * 65)
      expect(find.text('₱117.00'), findsOneWidget);

      // Verify portion hint "Pang 6-8 katao"
      expect(find.textContaining('Pang 6-8 katao'), findsOneWidget);
    });
  });
}

class _MockInventoryNotifier extends InventoryNotifier {
  _MockInventoryNotifier(this._initialProducts);
  final List<Product> _initialProducts;

  @override
  Future<InventoryState> build() async =>
      InventoryState(products: _initialProducts);
}

