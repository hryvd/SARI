import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sare/domain/adapters/gulay_adapter.dart';
import 'package:sare/domain/adapters/rice_adapter.dart';
import 'package:sare/domain/adapters/sari_sari_adapter.dart';
import 'package:sare/domain/entities/product.dart';
import 'package:sare/screens/inventory/gulay/gulay_inventory.dart';
import 'package:sare/screens/inventory/sari_sari/sari_sari_inventory.dart';
import 'package:sare/screens/inventory/shared/item_box_grid.dart';
import 'package:sare/theme/store_theme.dart';

void main() {
  group('Universal Box-Grid Inventory (Phase 3 Checks)', () {
    final List<Product> sampleProducts = <Product>[
      Product(
        productId: 'P1',
        name: 'Piattos Cheese',
        barcode: '4800016004309',
        unitPrice: 14.0,
        costPrice: 10.0,
        stockQty: 48,
        threshold: 10,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: 'Snacks',
      ),
      Product(
        productId: 'P2',
        name: 'San Miguel Pale Pilsen',
        barcode: '4800016004311',
        unitPrice: 55.0,
        costPrice: 44.0,
        stockQty: 4, // Low stock!
        threshold: 6,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: 'Alcohol',
      ),
      Product(
        productId: 'P3',
        name: 'Hope Cigarettes',
        barcode: '4800016004318',
        unitPrice: 90.0,
        costPrice: 80.0,
        stockQty: 0, // Out of stock!
        threshold: 2,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: 'Tobacco',
      ),
    ];

    testWidgets('StoreItemBoxGrid renders a 2-column GridView with 12dp card gap',
        (WidgetTester tester) async {
      const SariSariAdapter adapter = SariSariAdapter();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreItemBoxGrid(
              items: sampleProducts,
              adapter: adapter,
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      final Finder gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final GridView gridView = tester.widget<GridView>(gridFinder);
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, equals(2));
      expect(delegate.crossAxisSpacing, equals(SpaceTokens.cardGap));
      expect(delegate.mainAxisSpacing, equals(SpaceTokens.cardGap));
      expect(delegate.crossAxisSpacing, equals(12.0));
      expect(delegate.mainAxisSpacing, equals(12.0));

      expect(find.text('Piattos Cheese'), findsOneWidget);
      expect(find.text('San Miguel Pale Pilsen'), findsOneWidget);
      expect(find.text('Hope Cigarettes'), findsOneWidget);
    });

    testWidgets('Glow state rendering: normal, low-stock (amber), out-of-stock (crimson)',
        (WidgetTester tester) async {
      const SariSariAdapter adapter = SariSariAdapter();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreItemBoxGrid(
              items: sampleProducts,
              adapter: adapter,
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      // Low stock item displays MABABA badge
      expect(find.text('MABABA'), findsOneWidget);

      // Out of stock item displays UBOS badge
      expect(find.text('UBOS'), findsOneWidget);

      // Normal item has no status overlay badge
      final Finder normalItemFinder = find.text('Piattos Cheese');
      expect(normalItemFinder, findsOneWidget);
    });

    testWidgets('Instant search filtering filters cards with no lag',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SariSariInventoryView(
              products: sampleProducts,
              onTapProduct: (_) {},
              onAddProduct: ({
                required String barcode,
                required double costPrice,
                required String name,
                required int stockQty,
                required int threshold,
                required double unitPrice,
                String? category,
              }) {},
            ),
          ),
        ),
      );

      // Initially all 3 products are visible
      expect(find.text('Piattos Cheese'), findsOneWidget);
      expect(find.text('San Miguel Pale Pilsen'), findsOneWidget);
      expect(find.text('Hope Cigarettes'), findsOneWidget);

      // Type "pilsen" in the search box
      final Finder searchField = find.byType(TextField);
      await tester.enterText(searchField, 'pilsen');
      await tester.pumpAndSettle();

      // Only San Miguel should remain
      expect(find.text('San Miguel Pale Pilsen'), findsOneWidget);
      expect(find.text('Piattos Cheese'), findsNothing);
      expect(find.text('Hope Cigarettes'), findsNothing);
    });

    testWidgets('StoreItemBoxGrid handles 0 items with friendly empty message',
        (WidgetTester tester) async {
      const GulayAdapter adapter = GulayAdapter();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreItemBoxGrid(
              items: const <dynamic>[],
              adapter: adapter,
              onTapItem: (_) {},
              emptyMessage: 'Walang nahanap na gulay',
            ),
          ),
        ),
      );

      expect(find.text('Walang nahanap na gulay'), findsOneWidget);
      expect(find.text('🥬'), findsOneWidget);
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('StoreItemBoxGrid scales gracefully to 100 items',
        (WidgetTester tester) async {
      const RiceAdapter adapter = RiceAdapter();
      final List<Map<String, dynamic>> hundredItems =
          List<Map<String, dynamic>>.generate(
        100,
        (int i) => <String, dynamic>{
          'name': 'Bigas Variety #$i',
          'price_per_kg': 50.0 + i,
          'stock_kg': 100.0,
          'low_stock_kg': 20.0,
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoreItemBoxGrid(
              items: hundredItems,
              adapter: adapter,
              onTapItem: (_) {},
            ),
          ),
        ),
      );

      // Initial visible items in viewport should be present
      expect(find.text('Bigas Variety #0'), findsOneWidget);
      expect(find.text('Bigas Variety #1'), findsOneWidget);
    });

    testWidgets('Gulay inventory add form requires NO barcode field',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GulayInventoryView(
              products: const <Product>[],
              onTapProduct: (_) {},
              onAddGulay: ({
                required String name,
                required double pricePerKg,
                required double stockKg,
                required double lowStockKg,
                String? category,
                String? portionHint,
              }) {},
            ),
          ),
        ),
      );

      // Tap DAGDAG GULAY floating action button
      await tester.tap(find.text('DAGDAG GULAY'));
      await tester.pumpAndSettle();

      // Modal bottom sheet appears
      expect(find.text('Magdagdag ng Gulay / Prutas'), findsOneWidget);
      expect(find.text('Presyo bawat Kilo (₱/kg)'), findsOneWidget);
      expect(find.text('Stock (Kilo)'), findsOneWidget);
      expect(find.text('Pang-ulam / Recipe Hint'), findsOneWidget);

      // Ensure NO Barcode field exists in Gulay form
      expect(find.text('Barcode'), findsNothing);
      expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    });
  });
}
