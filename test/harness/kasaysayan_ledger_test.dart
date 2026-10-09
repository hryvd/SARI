import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sare/application/ledger_provider.dart';
import 'package:sare/data/local/daos/ledger_dao.dart';
import 'package:sare/domain/entities/customer.dart';
import 'package:sare/domain/entities/ledger_entry.dart';
import 'package:sare/screens/ledger/kasaysayan_screen.dart';

void main() {
  group('Unified Kasaysayan Ledger (Phase 7 Unit & Model Tests)', () {
    test('LedgerEntry model correctly flags entry types and round-trips to map', () {
      final now = DateTime(2026, 10, 6, 10, 30);
      final sale = LedgerEntry(
        id: 'LE_01',
        transactionId: 'TXN_101',
        entryType: 'CASH_SALE',
        amount: 250.0,
        balanceAfter: 0.0,
        timestamp: now,
        note: '2x Bigas',
      );
      expect(sale.isSale, isTrue);
      expect(sale.isUtang, isFalse);
      expect(sale.isPayment, isFalse);

      final map = sale.toMap();
      expect(map['entry_type'], equals('CASH_SALE'));
      expect(map['amount'], equals(250.0));
      expect(map['balance_after'], equals(0.0));

      final restored = LedgerEntry.fromMap(map);
      expect(restored.id, equals('LE_01'));
      expect(restored.transactionId, equals('TXN_101'));
      expect(restored.amount, equals(250.0));
      expect(restored.isSale, isTrue);
    });

    test('LedgerEntry utang and bayad types are correctly identified', () {
      final utang = LedgerEntry(
        id: 'LE_02',
        customerId: 'CUST_01',
        entryType: 'UTANG_ISSUED',
        amount: 150.0,
        balanceAfter: 450.0,
        timestamp: DateTime.now(),
        customerName: 'Aling Nena',
      );
      expect(utang.isUtang, isTrue);
      expect(utang.isSale, isFalse);

      final bayad = LedgerEntry(
        id: 'LE_03',
        customerId: 'CUST_01',
        entryType: 'UTANG_PAYMENT',
        amount: 100.0,
        balanceAfter: 350.0,
        timestamp: DateTime.now(),
        customerName: 'Aling Nena',
      );
      expect(bayad.isPayment, isTrue);
      expect(bayad.isUtang, isFalse);
    });

    test('LedgerDao.generateCsv produces correct unified header and rows', () {
      final dao = LedgerDao();
      final entries = <LedgerEntry>[
        LedgerEntry(
          id: 'LE_001',
          transactionId: 'TX_1',
          entryType: 'CASH_SALE',
          amount: 245.0,
          balanceAfter: 0.0,
          timestamp: DateTime(2026, 10, 6, 10, 45),
          note: 'Bigas Sardinas',
        ),
        LedgerEntry(
          id: 'LE_002',
          customerId: 'C_1',
          entryType: 'UTANG_ISSUED',
          amount: 115.0,
          balanceAfter: 420.0,
          timestamp: DateTime(2026, 10, 6, 10, 15),
          customerName: 'Aling Nena',
          note: 'Dinorado Itlog',
        ),
      ];

      final csv = dao.generateCsv(entries);
      expect(
        csv,
        startsWith(
            'entry_id,timestamp,entry_type,customer_name,amount_php,customer_remaining_balance,payment_ref'),
      );
      expect(csv, contains('LE_001'));
      expect(csv, contains('CASH_SALE'));
      expect(csv, contains('245.00'));
      expect(csv, contains('LE_002'));
      expect(csv, contains('Aling Nena'));
      expect(csv, contains('115.00'));
      expect(csv, contains('420.00'));
    });

    test('LedgerState filters entries by timeline filter chips and search', () {
      final entries = <LedgerEntry>[
        LedgerEntry(
          id: 'LE_SALE',
          entryType: 'CASH_SALE',
          amount: 50.0,
          balanceAfter: 0.0,
          timestamp: DateTime.now(),
          note: 'Sari-Sari snack',
        ),
        LedgerEntry(
          id: 'LE_UTANG',
          entryType: 'UTANG_ISSUED',
          amount: 120.0,
          balanceAfter: 120.0,
          timestamp: DateTime.now(),
          customerName: 'Mang Tomas',
        ),
        LedgerEntry(
          id: 'LE_BAYAD',
          entryType: 'UTANG_PAYMENT',
          amount: 50.0,
          balanceAfter: 70.0,
          timestamp: DateTime.now(),
          customerName: 'Mang Tomas',
        ),
      ];

      final stateAll = LedgerState(entries: entries, filter: LedgerTimelineFilter.lahat);
      expect(stateAll.filteredEntries.length, equals(3));

      final stateBenta = LedgerState(entries: entries, filter: LedgerTimelineFilter.benta);
      expect(stateBenta.filteredEntries.length, equals(1));
      expect(stateBenta.filteredEntries.first.id, equals('LE_SALE'));

      final stateUtang = LedgerState(entries: entries, filter: LedgerTimelineFilter.utang);
      expect(stateUtang.filteredEntries.length, equals(1));
      expect(stateUtang.filteredEntries.first.id, equals('LE_UTANG'));

      final stateBayad = LedgerState(entries: entries, filter: LedgerTimelineFilter.bayad);
      expect(stateBayad.filteredEntries.length, equals(1));
      expect(stateBayad.filteredEntries.first.id, equals('LE_BAYAD'));

      final stateSearch = LedgerState(
        entries: entries,
        filter: LedgerTimelineFilter.lahat,
        searchQuery: 'Tomas',
      );
      expect(stateSearch.filteredEntries.length, equals(2));
    });
  });

  group('Unified Kasaysayan Ledger (Phase 7 Widget Tests)', () {
    testWidgets('KasaysayanScreen displays timeline, summary boxes, and filter chips',
        (WidgetTester tester) async {
      final mockState = LedgerState(
        totalCashSales: 4850.0,
        totalOutstandingCredit: 1250.0,
        totalCollectedPayments: 800.0,
        customers: <Customer>[
          Customer(
            customerId: 'C_01',
            name: 'Aling Nena',
            creditBalance: 420.0,
            isActive: true,
            createdAt: DateTime.now(),
          ),
        ],
        entries: <LedgerEntry>[
          LedgerEntry(
            id: 'E_01',
            transactionId: 'TXN1042',
            entryType: 'CASH_SALE',
            amount: 245.0,
            balanceAfter: 0.0,
            timestamp: DateTime.now(),
            note: '3 items: 1.5kg Bigas',
          ),
          LedgerEntry(
            id: 'E_02',
            customerId: 'C_01',
            entryType: 'UTANG_ISSUED',
            amount: 115.0,
            balanceAfter: 420.0,
            timestamp: DateTime.now(),
            customerName: 'Aling Nena',
            note: '2 items: 1kg Dinorado',
          ),
          LedgerEntry(
            id: 'E_03',
            customerId: 'C_01',
            entryType: 'UTANG_PAYMENT',
            amount: 200.0,
            balanceAfter: 220.0,
            timestamp: DateTime.now(),
            customerName: 'Mang Tomas',
            note: 'Partial repayment',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ledgerProvider.overrideWith(() => _MockLedgerNotifier(mockState)),
          ],
          child: const MaterialApp(
            home: KasaysayanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check summary boxes
      expect(find.text('Benta (Cash)'), findsOneWidget);
      expect(find.text('₱4850.00'), findsOneWidget);
      expect(find.text('Utang (Pautang)'), findsOneWidget);
      expect(find.text('₱1250.00'), findsOneWidget);
      expect(find.text('Nasingil (Bayad)'), findsOneWidget);
      expect(find.text('₱800.00'), findsOneWidget);

      // Check filter chips
      expect(find.text('Lahat'), findsOneWidget);
      expect(find.text('Benta'), findsOneWidget);
      expect(find.text('Utang'), findsOneWidget);
      expect(find.text('Bayad'), findsOneWidget);

      // Check timeline entry badges
      expect(find.text('[BENTA]'), findsOneWidget);
      expect(find.text('+₱245.00'), findsOneWidget);
      expect(find.text('[UTANG]'), findsOneWidget);
      expect(find.text('+₱115.00'), findsOneWidget);
      expect(find.text('[BAYAD]'), findsOneWidget);
      expect(find.text('-₱200.00'), findsOneWidget);

      // Zero BackdropFilter rule verification
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('Tapping timeline filter chip changes active filter',
        (WidgetTester tester) async {
      final mockNotifier = _MockLedgerNotifier(const LedgerState());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ledgerProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(
            home: KasaysayanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Utang'));
      await tester.pumpAndSettle();
      expect(mockNotifier.lastFilter, equals(LedgerTimelineFilter.utang));

      await tester.tap(find.text('Bayad'));
      await tester.pumpAndSettle();
      expect(mockNotifier.lastFilter, equals(LedgerTimelineFilter.bayad));
    });
  });
}

class _MockLedgerNotifier extends LedgerNotifier {
  _MockLedgerNotifier(this._initialState);
  final LedgerState _initialState;
  LedgerTimelineFilter? lastFilter;

  @override
  Future<LedgerState> build() async => _initialState;

  @override
  void setFilter(LedgerTimelineFilter filter) {
    lastFilter = filter;
    state = AsyncData<LedgerState>(_initialState.copyWith(filter: filter));
  }
}
