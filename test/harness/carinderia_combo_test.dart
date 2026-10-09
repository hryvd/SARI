import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sare/domain/adapters/carinderia_adapter.dart';
import 'package:sare/domain/entities/item_dish.dart';
import 'package:sare/domain/services/combo_engine.dart';
import 'package:sare/screens/carinderia/carinderia_pos.dart';
import 'package:sare/screens/carinderia/combo_builder.dart';

void main() {
  group('Carinderia & Combo Engine (Phase 6 Unit Tests)', () {
    test('Default silog combos contain standard options with positive savings', () {
      final List<ComboMeal> combos = ComboEngine.defaultSilogCombos();
      expect(combos.length, equals(5));

      final ComboMeal tapsilog = combos.firstWhere((c) => c.comboId == 'combo_tapsilog');
      expect(tapsilog.name, equals('Tapsilog'));
      expect(tapsilog.items.length, equals(3));
      expect(tapsilog.comboPrice, equals(79.0));
      // Tapa (50) + Sinangag (20) + Itlog (15) = 85
      expect(tapsilog.alaCarteTotal, equals(85.0));
      expect(tapsilog.savings, equals(6.0));
      expect(tapsilog.savingsPct, closeTo(7.05, 0.1));
      expect(tapsilog.savingsLabel, contains('Makatipid ₱6.00'));
    });

    test('Combo availability checks portions map', () {
      final List<ComboMeal> combos = ComboEngine.defaultSilogCombos();
      final ComboMeal tapsilog = combos.first;

      final Map<String, int> allAvailable = {
        'tapa': 10,
        'sinangag': 25,
        'itlog': 30,
      };
      expect(ComboEngine.isComboAvailable(tapsilog, allAvailable), isTrue);

      final Map<String, int> tapaSoldOut = {
        'tapa': 0,
        'sinangag': 25,
        'itlog': 30,
      };
      expect(ComboEngine.isComboAvailable(tapsilog, tapaSoldOut), isFalse);
    });

    test('CartLine lineTotal and addToCart quantity merging', () {
      final List<CartLine> cart = [];
      final CartLine item1 = CartLine(
        id: 'adobo',
        name: 'Pork Adobo',
        unitPrice: 55.0,
        category: 'Ulam',
        quantity: 1,
      );

      final List<CartLine> cart1 = ComboEngine.addToCart(cart, item1);
      expect(cart1.length, equals(1));
      expect(cart1.first.quantity, equals(1));
      expect(cart1.first.lineTotal, equals(55.0));

      final CartLine item2 = CartLine(
        id: 'adobo',
        name: 'Pork Adobo',
        unitPrice: 55.0,
        category: 'Ulam',
        quantity: 2,
      );
      final List<CartLine> cart2 = ComboEngine.addToCart(cart1, item2);
      expect(cart2.length, equals(1));
      expect(cart2.first.quantity, equals(3));
      expect(cart2.first.lineTotal, equals(165.0));
    });

    test('removeOne decrements and clears item at 0', () {
      final List<CartLine> cart = [
        CartLine(
          id: 'kanin',
          name: 'Extra Rice',
          unitPrice: 15.0,
          category: 'Kanin',
          quantity: 2,
        ),
      ];

      final List<CartLine> step1 = ComboEngine.removeOne(cart, 'kanin');
      expect(step1.first.quantity, equals(1));

      final List<CartLine> step2 = ComboEngine.removeOne(step1, 'kanin');
      expect(step2.isEmpty, isTrue);
    });

    test('cartTotal and computeChange exact cent calculations', () {
      final List<CartLine> cart = [
        CartLine(
          id: 'c1',
          name: 'Tapsilog',
          unitPrice: 79.0,
          category: 'Silog',
          quantity: 2,
        ),
        CartLine(
          id: 'c2',
          name: 'Iced Tea',
          unitPrice: 20.0,
          category: 'Inumin',
          quantity: 1,
        ),
      ];

      // 79 * 2 = 158 + 20 = 178
      final double total = ComboEngine.cartTotal(cart);
      expect(total, equals(178.0));

      final double change = ComboEngine.computeChange(total, 200.0);
      expect(change, equals(22.0));
    });

    test('ItemDish stock status checks', () {
      const ItemDish dishAvailable = ItemDish(
        itemId: 'kaldereta',
        price: 65.0,
        dailyPortions: 20,
        portionsLeft: 12,
        isComboEligible: true,
      );
      expect(dishAvailable.isLowStock, isFalse);
      expect(dishAvailable.isOutOfStock, isFalse);

      const ItemDish dishLow = ItemDish(
        itemId: 'menudo',
        price: 60.0,
        dailyPortions: 20,
        portionsLeft: 3,
        isComboEligible: true,
      );
      expect(dishLow.isLowStock, isTrue);
      expect(dishLow.isOutOfStock, isFalse);

      const ItemDish dishEmpty = ItemDish(
        itemId: 'tinola',
        price: 50.0,
        dailyPortions: 20,
        portionsLeft: 0,
        isComboEligible: true,
      );
      expect(dishEmpty.isLowStock, isFalse);
      expect(dishEmpty.isOutOfStock, isTrue);
    });
  });

  group('Carinderia Adapter Contract Checks', () {
    test('CarinderiaAdapter properties adhere to architecture contract', () {
      const CarinderiaAdapter adapter = CarinderiaAdapter();
      expect(adapter.requiresBarcode, isFalse);
      expect(adapter.requiresWeightInput, isFalse);
      expect(adapter.hasComboEngine, isTrue);
      expect(adapter.defaultCategories, contains('Ulam'));
      expect(adapter.defaultCategories, contains('Silog'));
      expect(adapter.defaultCategories, contains('Kanin'));
    });

    testWidgets('CarinderiaAdapter buildPosInterface returns CarinderiaPosScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: _buildAdapterPos,
            ),
          ),
        ),
      );

      expect(find.byType(CarinderiaPosScreen), findsOneWidget);
    });
  });

  group('Carinderia UI & Kiosk Widget Tests', () {
    testWidgets('ComboBuilderScreen renders default combos with savings chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ComboBuilderScreen(
            onAddCombo: (_) {},
          ),
        ),
      );

      expect(find.text('Combo Builder'), findsOneWidget);
      expect(find.text('Tapsilog'), findsOneWidget);
      expect(find.text('Longsilog'), findsOneWidget);
      expect(find.text('Bangsilog'), findsOneWidget);
      expect(find.text('Tosilog'), findsOneWidget);
      expect(find.text('Chicksilog'), findsOneWidget);
    });

    testWidgets('CarinderiaPosScreen renders category tabs and combo action',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CarinderiaPosScreen(),
            ),
          ),
        ),
      );

      // Verify header and category tabs exist
      expect(find.text('Carinderia Kiosk'), findsOneWidget);
      expect(find.text('Lahat'), findsOneWidget);
      expect(find.text('Ulam'), findsOneWidget);
      expect(find.text('Silog'), findsOneWidget);
      expect(find.byTooltip('Combo Builder'), findsOneWidget);
    });
  });
}

Widget _buildAdapterPos(BuildContext context) {
  const CarinderiaAdapter adapter = CarinderiaAdapter();
  return adapter.buildPosInterface(context);
}
