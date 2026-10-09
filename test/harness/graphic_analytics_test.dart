import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sare/application/analytics_provider.dart';
import 'package:sare/domain/entities/sales_summary.dart';
import 'package:sare/domain/entities/transaction.dart';
import 'package:sare/domain/services/business_advisor.dart';
import 'package:sare/screens/analytics/widgets/lokal_na_payo_card.dart';
import 'package:sare/screens/analytics/widgets/peak_hour_heat_strip.dart';
import 'package:sare/screens/analytics/widgets/radial_goal_ring.dart';
import 'package:sare/screens/analytics/widgets/top_products_bar.dart';
import 'package:sare/screens/analytics_screen.dart';

void main() {
  group('Graphic Visual Analytics (Phase 8 Unit & Service Tests)', () {
    test('BusinessAdvisor generates meaningful localized advice in Tagalog and English', () {
      final adviceFil = BusinessAdvisor.generateAdvice(
        revenue: 4850.0,
        grossProfit: 1240.0,
        profitMargin: 25.5,
        dailyTarget: 5000.0,
        topProducts: <TopProduct>[
          const TopProduct(
            productId: 'P1',
            name: 'Dinorado Rice',
            totalQty: 30,
            totalRevenue: 1680.0,
          ),
        ],
        recentTransactions: <Transaction>[
          Transaction(
            transactionId: 'T1',
            timestamp: DateTime(2026, 10, 6, 8, 30),
            paymentMethod: 'cash',
            totalAmount: 200.0,
            changeDue: 0.0,
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        ],
        isFilipino: true,
      );

      expect(adviceFil.length, greaterThanOrEqualTo(3));
      expect(adviceFil.any((tip) => tip.contains('Kulang na lang ng ₱150.00')), isTrue);
      expect(adviceFil.any((tip) => tip.contains('25.5% profit margin')), isTrue);
      expect(adviceFil.any((tip) => tip.contains('Dinorado Rice')), isTrue);

      final adviceEn = BusinessAdvisor.generateAdvice(
        revenue: 5500.0,
        grossProfit: 1500.0,
        profitMargin: 27.2,
        dailyTarget: 5000.0,
        topProducts: const <TopProduct>[],
        recentTransactions: const <Transaction>[],
        isFilipino: false,
      );
      expect(adviceEn.any((tip) => tip.contains('Congratulations! You reached your daily sales target')), isTrue);
    });

    test('AnalyticsState calculates correct profit margin', () {
      const state = AnalyticsState(
        revenue: 1000.0,
        grossProfit: 350.0,
      );
      expect(state.profitMargin, equals(35.0));
    });
  });

  group('Graphic Visual Analytics (Phase 8 Widget & Component Tests)', () {
    testWidgets('RadialGoalRing renders canvas arc, percentage, and metric rows',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RadialGoalRing(
              achieved: 4850.0,
              target: 5000.0,
              accentColor: Color(0xFFC9352C),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('97%'), findsOneWidget);
      expect(find.text('Arawang Target (Sales Goal)'), findsOneWidget);
      expect(find.text('₱5000.00'), findsOneWidget);
      expect(find.text('₱4850.00'), findsOneWidget);
      expect(find.text('₱150.00!'), findsOneWidget);
    });

    testWidgets('PeakHourHeatStrip renders morning and afternoon blocks with peak indicators',
        (WidgetTester tester) async {
      final txns = <Transaction>[
        Transaction(
          transactionId: 'T1',
          timestamp: DateTime(2026, 10, 6, 8, 0),
          paymentMethod: 'cash',
          totalAmount: 100.0,
          changeDue: 0.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
        Transaction(
          transactionId: 'T2',
          timestamp: DateTime(2026, 10, 6, 8, 30),
          paymentMethod: 'cash',
          totalAmount: 150.0,
          changeDue: 0.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
        Transaction(
          transactionId: 'T3',
          timestamp: DateTime(2026, 10, 6, 17, 15),
          paymentMethod: 'cash',
          totalAmount: 250.0,
          changeDue: 0.0,
          status: 'completed',
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeakHourHeatStrip(
              transactions: txns,
              accentColor: const Color(0xFFC9352C),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Oras ng Bugso (Peak Hour Heat Strip)'), findsOneWidget);
      expect(find.text('Umaga (Morning):'), findsOneWidget);
      expect(find.text('Hapon (Afternoon):'), findsOneWidget);
      expect(find.text('Peak: 8-10 AM'), findsOneWidget);
      expect(find.text('Peak: 5-7 PM'), findsOneWidget);
    });

    testWidgets('TopProductsBarView renders thick horizontal bars for top items',
        (WidgetTester tester) async {
      const top = <TopProduct>[
        TopProduct(
          productId: 'P1',
          name: 'Dinorado Rice',
          totalQty: 30,
          totalRevenue: 1680.0,
        ),
        TopProduct(
          productId: 'P2',
          name: 'Pork Adobo Meal',
          totalQty: 18,
          totalRevenue: 980.0,
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TopProductsBarView(
              topProducts: top,
              accentColor: Color(0xFFC9352C),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pinakamalakas na Produkto'), findsOneWidget);
      expect(find.text('Dinorado Rice'), findsOneWidget);
      expect(find.text('₱1680.00'), findsOneWidget);
      expect(find.text('Pork Adobo Meal'), findsOneWidget);
      expect(find.text('₱980.00'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('LokalNaPayoCard renders personalized business advice',
        (WidgetTester tester) async {
      final tips = <String>[
        'Mabenta ang Bigas at Karne tuwing Biyernes ng hapon.',
        'Mag-handa ng dagdag na 5 kilo bago mag-alas 4.',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LokalNaPayoCard(
              insights: tips,
              accentColor: const Color(0xFFC9352C),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lokal na Payo (AI Business Insight)'), findsOneWidget);
      expect(find.text(tips[0]), findsOneWidget);
      expect(find.text(tips[1]), findsOneWidget);
    });

    testWidgets('Full AnalyticsScreen integration verifies spec checks and retires LineChart',
        (WidgetTester tester) async {
      final mockState = AnalyticsState(
        period: AnalyticsPeriod.daily,
        revenue: 4850.0,
        grossProfit: 1240.0,
        txnCount: 24,
        dailyTarget: 5000.0,
        topProducts: const <TopProduct>[
          TopProduct(
            productId: 'P1',
            name: 'Dinorado Rice',
            totalQty: 25,
            totalRevenue: 1400.0,
          ),
        ],
        recentTransactions: <Transaction>[
          Transaction(
            transactionId: 'TXN101',
            timestamp: DateTime(2026, 10, 6, 9, 30),
            paymentMethod: 'cash',
            totalAmount: 150.0,
            changeDue: 0.0,
            status: 'completed',
            createdAt: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsProvider.overrideWith(() => _MockAnalyticsNotifier(mockState)),
          ],
          child: MaterialApp(
            home: AnalyticsScreen(
              onOpenTransactions: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check period selectors
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Check KPI cards
      expect(find.text('TOTAL SALES'), findsOneWidget);
      expect(find.text('₱4850.00'), findsNWidgets(2)); // in KPI card and RadialGoalRing Naabot
      expect(find.text('ESTIMATED PROFIT'), findsOneWidget);
      expect(find.text('₱1240.00'), findsOneWidget);
      expect(find.text('25.6% Margin'), findsOneWidget);

      // Check Custom Graphic Visual Components
      expect(find.byType(RadialGoalRing), findsOneWidget);
      expect(find.byType(PeakHourHeatStrip), findsOneWidget);
      expect(find.byType(TopProductsBarView), findsOneWidget);
      expect(find.byType(LokalNaPayoCard), findsOneWidget);

      // Verify LineChart is retired (not in widget tree!)
      expect(find.byType(LineChart), findsNothing);

      // Verify ZERO BackdropFilter rule
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}

class _MockAnalyticsNotifier extends AnalyticsNotifier {
  _MockAnalyticsNotifier(this._initialState);
  final AnalyticsState _initialState;

  @override
  Future<AnalyticsState> build() async => _initialState;
}
