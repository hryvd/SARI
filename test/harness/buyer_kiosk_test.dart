import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sare/application/buyer_provider.dart';
import 'package:sare/application/cart_provider.dart';
import 'package:sare/domain/entities/buyer_order.dart';
import 'package:sare/domain/entities/product.dart';
import 'package:sare/domain/entities/store_profile.dart';
import 'package:sare/domain/services/buyer_order_service.dart';
import 'package:sare/screens/buyer/buyer_kiosk_screen.dart';
import 'package:sare/screens/buyer/widgets/buyer_qr_dialog.dart';
import 'package:sare/screens/buyer/widgets/buyer_qr_view.dart';
import 'package:sare/screens/buyer/widgets/credibility_badge_sheet.dart';

void main() {
  group('Phase 9: Buyer Kiosk Domain & Service Contract Tests', () {
    test('BuyerOrderItem computes unit price and subtotal accurately with addons', () {
      const item = BuyerOrderItem(
        id: 'DISH_01',
        name: 'Adobo Combo',
        unitPrice: 65.0,
        qty: 2,
        addons: <String>['Extra Rice (+₱15)', 'Sago (+₱15)'],
        addonPrice: 30.0,
      );

      expect(item.itemUnitPrice, equals(95.0));
      expect(item.subtotal, equals(190.0));
    });

    test('BuyerOrder serialization & deserialization round-trip preserves exact values', () {
      final now = DateTime(2026, 10, 6, 14, 0);
      final order = BuyerOrder(
        orderId: 'ORD_7741',
        storeId: 'STR_BATANGAS_01',
        timestamp: now,
        items: const <BuyerOrderItem>[
          BuyerOrderItem(
            id: 'RICE_01',
            name: 'Dinorado (1.5kg)',
            unitPrice: 97.5,
            qty: 1,
          ),
          BuyerOrderItem(
            id: 'VEG_01',
            name: 'Talong',
            unitPrice: 45.0,
            qty: 2,
            addons: <String>['Tali Pack'],
            addonPrice: 5.0,
          ),
        ],
        totalAmount: 197.5, // 97.5 + (50.0 * 2) = 197.5
        notes: 'Daliin po',
      );

      final payload = BuyerOrderService.serialize(order);
      expect(payload.startsWith(BuyerOrderService.orderPrefix), isTrue);
      expect(BuyerOrderService.isBuyerOrder(payload), isTrue);

      final decoded = BuyerOrderService.deserialize(payload);
      expect(decoded, isNotNull);
      expect(decoded!.orderId, equals('ORD_7741'));
      expect(decoded.storeId, equals('STR_BATANGAS_01'));
      expect(decoded.items.length, equals(2));
      expect(decoded.items[0].name, equals('Dinorado (1.5kg)'));
      expect(decoded.items[1].addons, contains('Tali Pack'));
      expect(decoded.totalAmount, equals(197.5));
      expect(BuyerOrderService.validateTotal(decoded), isTrue);
    });

    test('BuyerOrderService recognizes raw JSON as well as prefixed strings', () {
      const rawJson =
          '{"v":1,"order_id":"ORD_RAW","store_id":"STR_01","items":[],"total":0.0}';
      expect(BuyerOrderService.isBuyerOrder(rawJson), isTrue);

      const invalid = 'SOME_RANDOM_BARCODE_12345';
      expect(BuyerOrderService.isBuyerOrder(invalid), isFalse);
    });

    test('Seller CartNotifier stages BuyerOrder into cart items seamlessly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final order = BuyerOrder(
        orderId: 'ORD_990',
        storeId: 'STR_01',
        timestamp: DateTime.now(),
        items: const <BuyerOrderItem>[
          BuyerOrderItem(
            id: 'P_1',
            name: 'Canned Sardines',
            unitPrice: 24.5,
            qty: 3,
          ),
          BuyerOrderItem(
            id: 'P_2',
            name: 'Pandesal Combo',
            unitPrice: 30.0,
            qty: 1,
            addons: <String>['Extra Butter'],
            addonPrice: 5.0,
          ),
        ],
        totalAmount: 108.5, // (24.5 * 3) + 35.0 = 108.5
      );

      container.read(cartProvider.notifier).stageBuyerOrder(order);
      final cart = container.read(cartProvider);

      expect(cart.items.length, equals(2));
      expect(cart.total, equals(108.5));
      expect(cart.items[0].qty, equals(3));
      expect(cart.items[1].product.name, contains('Extra Butter'));
    });
  });

  group('Phase 9: Buyer Kiosk Widget & Verification Tests', () {
    testWidgets('BuyerQrView renders pure custom canvas QR code without exceptions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: BuyerQrView(
                data: 'SARE_ORDER:{"v":1,"order_id":"123","total":50.0,"items":[]}',
                size: 200,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BuyerQrView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('CredibilityBadgeSheet renders verified document tags and GPS details',
        (WidgetTester tester) async {
      final profile = StoreProfile(
        id: 'SP_01',
        storeType: 'gulay',
        storeName: 'Nanay Tess Produce',
        ownerName: 'Teresa Santos',
        latitude: 13.7563,
        longitude: 121.0583,
        permitDocsJson:
            '{"permit_number":"BAT-2026-9921","barangay_clearance":"Brgy Kumintang Ibaba Clearance"}',
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CredibilityBadgeSheet.show(context, profile),
                child: const Text('Open Credibility'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Credibility'));
      await tester.pumpAndSettle();

      expect(
        find.text('Dokumento ay Nakakabit sa Telepono'),
        findsOneWidget,
      );
      expect(
        find.text('Self-Declared Verified Documents Attached'),
        findsOneWidget,
      );
      expect(find.text('BAT-2026-9921'), findsOneWidget);
      expect(find.text('Nanay Tess Produce'), findsOneWidget);
    });

    testWidgets('BuyerKioskScreen renders box grid, search, credibility badge, and zero BackdropFilter',
        (WidgetTester tester) async {
      final now = DateTime.now();
      final mockProducts = <Product>[
        Product(
          productId: 'PROD_1',
          name: 'Siling Labuyo',
          categoryName: 'Gulay',
          unitPrice: 25.0,
          costPrice: 15.0,
          stockQty: 10,
          threshold: 2,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Product(
          productId: 'PROD_2',
          name: 'Talong',
          categoryName: 'Gulay',
          unitPrice: 35.0,
          costPrice: 20.0,
          stockQty: 2, // low stock
          threshold: 2,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
        Product(
          productId: 'PROD_3',
          name: 'Ampalaya',
          categoryName: 'Gulay',
          unitPrice: 40.0,
          costPrice: 25.0,
          stockQty: 0, // Ubos
          threshold: 2,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final profile = StoreProfile(
        id: 'SP_TEST',
        storeType: 'gulay',
        storeName: 'Aling Maria Gulayan',
        ownerName: 'Maria Santos',
        createdAt: DateTime.now(),
      );

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            buyerProvider.overrideWith(
              () => _MockBuyerNotifier(mockProducts, profile),
            ),
          ],
          child: const MaterialApp(
            home: BuyerKioskScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify zero BackdropFilter
      expect(find.byType(BackdropFilter), findsNothing);

      // Verify header and credibility banner
      expect(find.text('Aling Maria Gulayan'), findsOneWidget);
      expect(
        find.text('Dokumento ay Nakakabit sa Telepono'),
        findsOneWidget,
      );

      // Verify catalog items and stock badges
      expect(find.text('Siling Labuyo'), findsOneWidget);
      expect(find.text('Talong'), findsOneWidget);
      expect(find.text('Ampalaya'), findsOneWidget);
      expect(find.text('Konti na lang'), findsOneWidget);
      expect(find.text('UBOS NA'), findsOneWidget);

      // Add item to cart
      final addIcons = find.byIcon(Icons.add_shopping_cart);
      expect(addIcons, findsWidgets);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Floating cart action bar should now be visible
      expect(find.text('Tingnan ang Basket'), findsOneWidget);
      expect(find.text('Kabuuang Order'), findsOneWidget);
    });

    testWidgets('BuyerQrDialog renders order breakdown and serialized QR',
        (WidgetTester tester) async {
      final order = BuyerOrder(
        orderId: 'A7B2C9',
        storeId: 'STR_01',
        timestamp: DateTime.now(),
        items: const <BuyerOrderItem>[
          BuyerOrderItem(
            id: 'P_1',
            name: 'Pork Adobo',
            unitPrice: 65.0,
            qty: 1,
          ),
        ],
        totalAmount: 65.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => BuyerQrDialog.show(context, order),
                child: const Text('Open Order QR'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Order QR'));
      await tester.pumpAndSettle();

      expect(find.text('Order #A7B2C9'), findsOneWidget);
      expect(find.byType(BuyerQrView), findsOneWidget);
      expect(find.text('1x Pork Adobo'), findsOneWidget);
      expect(find.text('Isara / Tapos Na'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}

class _MockBuyerNotifier extends BuyerNotifier {
  _MockBuyerNotifier(this._initialCatalog, this._initialProfile);

  final List<Product> _initialCatalog;
  final StoreProfile _initialProfile;

  @override
  BuyerState build() {
    return BuyerState(
      catalog: _initialCatalog,
      storeProfile: _initialProfile,
      isLoading: false,
    );
  }
}
