import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sare/application/store_adapter_provider.dart';
import 'package:sare/domain/adapters/carinderia_adapter.dart';
import 'package:sare/domain/adapters/gulay_adapter.dart';
import 'package:sare/domain/adapters/rice_adapter.dart';
import 'package:sare/domain/adapters/sari_sari_adapter.dart';
import 'package:sare/domain/adapters/store_adapter.dart';
import 'package:sare/domain/entities/item_dish.dart';
import 'package:sare/domain/entities/item_gulay.dart';
import 'package:sare/domain/entities/item_rice.dart';
import 'package:sare/domain/entities/ledger_entry.dart';
import 'package:sare/domain/entities/product.dart';
import 'package:sare/domain/entities/store_profile.dart';
import 'package:sare/theme/store_theme.dart';

void main() {
  group('StoreAdapter Contract Suite', () {
    test('storeAdapterForType returns correct adapter for all StoreType values', () {
      for (final StoreType type in StoreType.values) {
        final StoreAdapter adapter = storeAdapterForType(type);
        expect(adapter.storeType, equals(type));
        expect(adapter.storeTitle, isNotEmpty);
        expect(adapter.brandColor, equals(StoreColors.forType(type)));
        expect(adapter.csvHeaders, isNotEmpty);
        expect(adapter.defaultCategories, isNotEmpty);
      }
    });

    test('SariSariAdapter contract properties', () {
      const SariSariAdapter adapter = SariSariAdapter();
      expect(adapter.storeType, equals(StoreType.sariSari));
      expect(adapter.requiresBarcode, isTrue);
      expect(adapter.requiresWeightInput, isFalse);
      expect(adapter.hasComboEngine, isFalse);
      expect(adapter.csvHeaders, contains('barcode'));
      expect(adapter.csvHeaders, contains('stock_qty'));

      final Product product = Product(
        productId: 'P1',
        name: 'Piattos Cheese',
        barcode: '4800016004309',
        unitPrice: 14.0,
        costPrice: 10.0,
        stockQty: 20,
        threshold: 5,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categoryName: 'Snacks',
      );
      final List<String> row = adapter.itemToCsvRow(product);
      expect(row, contains('Piattos Cheese'));
      expect(row, contains('14.00'));
      expect(row, contains('IN STOCK'));
    });

    test('GulayAdapter contract properties (zero barcode, kilo scale pricing)', () {
      const GulayAdapter adapter = GulayAdapter();
      expect(adapter.storeType, equals(StoreType.gulay));
      expect(adapter.requiresBarcode, isFalse,
          reason: 'Gulay produce must NOT require barcode');
      expect(adapter.requiresWeightInput, isTrue,
          reason: 'Gulay produce requires scale/weight input');
      expect(adapter.hasComboEngine, isFalse);
      expect(adapter.csvHeaders, contains('price_per_kg'));
      expect(adapter.csvHeaders, contains('current_stock_kg'));

      const ItemGulay gulay = ItemGulay(
        itemId: 'Talong Long Purple',
        pricePerKg: 75.0,
        stockKg: 14.5,
        lowStockKg: 3.0,
        portionHintRecipe: 'Pinakbet',
        portionServingsPerKg: 4.0,
      );
      expect(gulay.computePrice(1.8), equals(135.0));
      expect(gulay.isLowStock, isFalse);
      expect(gulay.isOutOfStock, isFalse);

      final List<String> row = adapter.itemToCsvRow(gulay);
      expect(row, contains('75.00'));
      expect(row, contains('14.50'));
      expect(row, contains('IN STOCK'));
    });

    test('RiceAdapter contract properties (QR bins & kilo/sack pricing)', () {
      const RiceAdapter adapter = RiceAdapter();
      expect(adapter.storeType, equals(StoreType.rice));
      expect(adapter.requiresBarcode, isTrue,
          reason: 'Rice uses QR bin stickers');
      expect(adapter.requiresWeightInput, isTrue);
      expect(adapter.hasComboEngine, isFalse);
      expect(adapter.csvHeaders, contains('variety_name'));
      expect(adapter.csvHeaders, contains('milling_grade'));
      expect(adapter.csvHeaders, contains('price_sack_25kg'));

      const ItemRice rice = ItemRice(
        itemId: 'R1',
        variety: 'Dinorado Special',
        millingGrade: 'Well-Milled',
        pricePerKg: 56.0,
        sackPrice25kg: 1350.0,
        sackPrice50kg: 2650.0,
        stockKg: 120.0,
        lowStockKg: 25.0,
        qrPayload: 'sare://rice?id=R1&price=56.0',
      );
      expect(rice.computePrice(2.5), equals(140.0));
      expect(rice.isLowStock, isFalse);
      expect(rice.isOutOfStock, isFalse);

      final List<String> row = adapter.itemToCsvRow(rice);
      expect(row, contains('Dinorado Special'));
      expect(row, contains('Well-Milled'));
      expect(row, contains('1350.00'));
    });

    test('CarinderiaAdapter contract properties (combo engine & batch portions)', () {
      const CarinderiaAdapter adapter = CarinderiaAdapter();
      expect(adapter.storeType, equals(StoreType.carinderia));
      expect(adapter.requiresBarcode, isFalse);
      expect(adapter.requiresWeightInput, isFalse);
      expect(adapter.hasComboEngine, isTrue,
          reason: 'Carinderia must activate combo meal engine');
      expect(adapter.csvHeaders, contains('dish_name'));
      expect(adapter.csvHeaders, contains('portions_remaining'));
      expect(adapter.csvHeaders, contains('combo_eligible'));

      const ItemDish dish = ItemDish(
        itemId: 'Pork Adobo',
        price: 55.0,
        dailyPortions: 30,
        portionsLeft: 22,
        isComboEligible: true,
      );
      expect(dish.isLowStock, isFalse);
      expect(dish.isOutOfStock, isFalse);

      final List<String> row = adapter.itemToCsvRow(dish);
      expect(row, contains('55.00'));
      expect(row, contains('22'));
      expect(row, contains('YES'));
    });
  });

  group('Domain Entities Serialization', () {
    test('StoreProfile round-trips toMap and fromMap', () {
      final StoreProfile profile = StoreProfile(
        id: 'store_123',
        storeType: 'gulay',
        storeName: 'Batangas Palengke Stall 4',
        ownerName: 'Mang Tomas',
        googleEmail: 'tomas@example.com',
        latitude: 14.1234,
        longitude: 121.5678,
        createdAt: DateTime(2026, 1, 1),
      );

      final Map<String, dynamic> map = profile.toMap();
      final StoreProfile restored = StoreProfile.fromMap(map);

      expect(restored.id, equals(profile.id));
      expect(restored.storeType, equals('gulay'));
      expect(restored.storeName, equals('Batangas Palengke Stall 4'));
      expect(restored.latitude, equals(14.1234));
    });

    test('LedgerEntry round-trips toMap and fromMap', () {
      final LedgerEntry entry = LedgerEntry(
        id: 'LEDGER_001',
        transactionId: 'TXN_10',
        customerId: 'CUST_5',
        entryType: 'UTANG_ISSUED',
        amount: 350.0,
        balanceAfter: 750.0,
        timestamp: DateTime(2026, 10, 6, 12, 0),
        note: 'Bilin ni misis',
      );

      expect(entry.isUtang, isTrue);
      expect(entry.isSale, isFalse);
      expect(entry.isPayment, isFalse);

      final Map<String, dynamic> map = entry.toMap();
      final LedgerEntry restored = LedgerEntry.fromMap(map);

      expect(restored.id, equals('LEDGER_001'));
      expect(restored.amount, equals(350.0));
      expect(restored.balanceAfter, equals(750.0));
      expect(restored.entryType, equals('UTANG_ISSUED'));
    });
  });

  group('Widget Tests: Adapter Inventory Cards', () {
    testWidgets('GulayAdapter renders box card with kilo unit and green accent',
        (WidgetTester tester) async {
      const GulayAdapter adapter = GulayAdapter();
      const ItemGulay gulay = ItemGulay(
        itemId: 'Kalabasa Suprema',
        pricePerKg: 45.0,
        stockKg: 22.0,
        lowStockKg: 4.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) =>
                  adapter.buildInventoryBox(gulay, () {}, context),
            ),
          ),
        ),
      );

      expect(find.text('Kalabasa Suprema'), findsOneWidget);
      expect(find.text('₱45.00 / kg'), findsOneWidget);
      expect(find.text('22.0 kg'), findsOneWidget);
    });

    testWidgets('RiceAdapter renders box card with sack/kilo info',
        (WidgetTester tester) async {
      const RiceAdapter adapter = RiceAdapter();
      const ItemRice rice = ItemRice(
        itemId: 'R1',
        variety: 'Jasmine Fragrant',
        millingGrade: 'Premium',
        pricePerKg: 62.0,
        stockKg: 18.0,
        lowStockKg: 25.0, // Low stock!
        qrPayload: 'qr',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) =>
                  adapter.buildInventoryBox(rice, () {}, context),
            ),
          ),
        ),
      );

      expect(find.text('Jasmine Fragrant'), findsOneWidget);
      expect(find.text('₱62.00 / kg'), findsOneWidget);
      expect(find.text('18.0 kg'), findsOneWidget);
      expect(find.text('Premium'), findsOneWidget);
      expect(find.text('MABABA'), findsOneWidget);
    });
  });
}
