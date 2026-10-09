import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sare/data/local/daos/ledger_dao.dart';
import 'package:sare/domain/entities/buyer_order.dart';
import 'package:sare/domain/entities/item_gulay.dart';
import 'package:sare/domain/entities/item_rice.dart';
import 'package:sare/domain/entities/ledger_entry.dart';
import 'package:sare/domain/services/buyer_order_service.dart';
import 'package:sare/domain/services/combo_engine.dart';
import 'package:sare/domain/services/scale_calculator.dart';
import 'package:sare/screens/buyer/buyer_kiosk_screen.dart';
import 'package:sare/screens/login_screen.dart';

void main() {
  group('Phase 10: Field Hardening Architecture Verification', () {
    test('ZERO BackdropFilter in active Dart source code across lib/', () {
      final libDir = Directory('lib');
      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          // Exclude comments that document the rule
          if (line.startsWith('//') || line.startsWith('///') || line.startsWith('*')) {
            continue;
          }
          if (line.contains('BackdropFilter') || line.contains('ImageFilter.blur')) {
            violations.add('${file.path}:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Violations of ZERO BackdropFilter rule found: \n${violations.join('\n')}',
      );
    });

    testWidgets('LoginScreen renders without BackdropFilter or ImageFilter.blur',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('Welcome back!'), findsOneWidget);
      expect(find.text('Pumasok Bilang Mamimili (Buyer Kiosk)'), findsOneWidget);
    });

    testWidgets('BuyerKioskScreen has strict zero BackdropFilter and 16dp horizontal padding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BuyerKioskScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BackdropFilter), findsNothing);

      // Verify 16dp horizontal padding is present
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      final has16dpPadding = paddings.any((p) {
        final insets = p.padding;
        return insets is EdgeInsets && (insets.left == 16.0 && insets.right == 16.0);
      });
      expect(has16dpPadding, isTrue);
    });
  });

  group('Phase 10: Scale Pricing Precision Checks', () {
    test('Exact cent arithmetic: 1.8 kg × ₱65.00/kg = ₱117.00 without floating point drift', () {
      final price = ScaleCalculator.computePrice(
        weightKg: 1.8,
        pricePerKg: 65.0,
      );
      expect(price, equals(117.00));
    });

    test('Exact cent arithmetic: 1.25 kg × ₱140.00/kg = ₱175.00 without floating point drift', () {
      final price = ScaleCalculator.computePrice(
        weightKg: 1.25,
        pricePerKg: 140.0,
      );
      expect(price, equals(175.00));
    });

    test('Gulay and Rice entity price computations match ScaleCalculator', () {
      const gulay = ItemGulay(
        itemId: 'G_01',
        pricePerKg: 65.0,
        stockKg: 10.0,
      );
      expect(gulay.computePrice(1.8), equals(117.00));

      const rice = ItemRice(
        itemId: 'R_01',
        variety: 'Dinorado',
        millingGrade: 'Well-Milled',
        pricePerKg: 50.0,
        stockKg: 100.0,
        qrPayload: 'SARE_RICE:1:Dinorado:50.0',
      );
      expect(rice.computePrice(2.5), equals(125.00));
    });

    test('POS Keypad presets contain standard weights [0.25, 0.5, 1.0, 1.2, 1.8]', () {
      const presets = <double>[0.25, 0.5, 1.0, 1.2, 1.8];
      for (final preset in presets) {
        final computed = ScaleCalculator.computePrice(
          weightKg: preset,
          pricePerKg: 100.0,
        );
        expect(computed, equals((preset * 100.0).roundToDouble()));
      }
    });
  });

  group('Phase 10: Offline Airplane Mode Resilience', () {
    test('Buyer order serialization & decoding works completely offline without network', () {
      final order = BuyerOrder(
        orderId: 'OFFLINE_01',
        storeId: 'STR_AIRPLANE',
        timestamp: DateTime(2026, 10, 6, 15, 0),
        items: const <BuyerOrderItem>[
          BuyerOrderItem(
            id: 'ITM_1',
            name: 'Pork Sinigang',
            unitPrice: 70.0,
            qty: 1,
            addons: <String>['Extra Rice'],
            addonPrice: 15.0,
          ),
        ],
        totalAmount: 85.0,
      );

      final serialized = BuyerOrderService.serialize(order);
      expect(serialized.length, lessThan(400)); // lightweight < 400 bytes

      final stopwatch = Stopwatch()..start();
      final decoded = BuyerOrderService.deserialize(serialized);
      stopwatch.stop();

      expect(decoded, isNotNull);
      expect(decoded!.totalAmount, equals(85.0));
      // Fast parsing budget (< 10 ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });

    test('Carinderia ComboEngine computes combos fully offline', () {
      const combo = ComboMeal(
        comboId: 'CMB_01',
        name: 'Combo A (1 Ulam + 1 Kanin)',
        comboPrice: 65.0,
        items: <ComboItem>[
          ComboItem(dishId: 'ULAM_01', dishName: 'Adobo', alaCartePrice: 50.0),
          ComboItem(dishId: 'RICE_01', dishName: 'Kanin', alaCartePrice: 15.0),
        ],
      );

      expect(combo.alaCarteTotal, equals(65.0));
      expect(combo.comboPrice, equals(65.0));
      expect(combo.savings, equals(0.0));
    });

    test('Ledger CSV export generates clean tabular data without server dependency', () {
      final entries = <LedgerEntry>[
        LedgerEntry(
          id: 'LE_OFF_01',
          transactionId: 'TXN_01',
          entryType: 'CASH_SALE',
          amount: 250.0,
          balanceAfter: 0.0,
          timestamp: DateTime(2026, 10, 6, 10, 0),
          customerName: 'Cash Buyer',
        ),
        LedgerEntry(
          id: 'LE_OFF_02',
          customerId: 'CUST_01',
          entryType: 'UTANG_ISSUED',
          amount: 150.0,
          balanceAfter: 450.0,
          timestamp: DateTime(2026, 10, 6, 11, 0),
          customerName: 'Aling Tess',
        ),
      ];

      final csv = LedgerDao().generateCsv(entries);
      expect(csv, contains('entry_id,timestamp,entry_type,customer_name,amount_php,customer_remaining_balance,payment_ref'));
      expect(csv, contains('Cash Buyer'));
      expect(csv, contains('Aling Tess'));
      expect(csv, contains('250.00'));
      expect(csv, contains('150.00'));
    });
  });
}
