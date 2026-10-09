import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../application/analytics_provider.dart';
import '../application/auth_provider.dart';
import '../application/locale_provider.dart';
import '../data/local/daos/transaction_dao.dart';
import '../domain/entities/sales_summary.dart';
import '../domain/entities/transaction.dart';
import '../domain/services/business_advisor.dart';
import '../theme/app_theme.dart';
import '../theme/store_theme.dart';
import 'analytics/widgets/lokal_na_payo_card.dart';
import 'analytics/widgets/peak_hour_heat_strip.dart';
import 'analytics/widgets/radial_goal_ring.dart';
import 'analytics/widgets/top_products_bar.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key, required this.onOpenTransactions});

  final VoidCallback onOpenTransactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(analyticsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(child: Text('Error: $e')),
          data: (AnalyticsState state) => _AnalyticsContent(
            state: state,
            onOpenTransactions: onOpenTransactions,
            locale: ref.watch(localeProvider),
          ),
        );
  }
}

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({
    required this.state,
    required this.onOpenTransactions,
    required this.locale,
  });

  final AnalyticsState state;
  final VoidCallback onOpenTransactions;
  final AppLocale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = appColors(context);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final Color storeAccent = StoreColors.forType(auth.storeType);
    final bool isFilipino = locale == AppLocale.fil;

    final List<String> businessTips = BusinessAdvisor.generateAdvice(
      revenue: state.revenue,
      grossProfit: state.grossProfit,
      profitMargin: state.profitMargin,
      dailyTarget: state.dailyTarget,
      topProducts: state.topProducts,
      recentTransactions: state.recentTransactions,
      isFilipino: isFilipino,
    );

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.read(analyticsProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Screen Header ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          isFilipino ? 'Kita at Benta' : 'Sales & Profit',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFilipino
                              ? 'Visual na ulat ng takbo ng negosyo'
                              : 'Intuitive graphic performance overview',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        IconButton.filledTonal(
                          tooltip: 'I-refresh',
                          onPressed: () =>
                              ref.read(analyticsProvider.notifier).refresh(),
                          icon: const Icon(Icons.refresh, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: c.surface,
                            foregroundColor: c.text,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'PDF Export',
                          onPressed: () => _exportPdf(context),
                          icon: const Icon(Icons.picture_as_pdf_outlined,
                              size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: c.surface,
                            foregroundColor: c.text,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Period Choice Chips ──────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AnalyticsPeriod.values.map((AnalyticsPeriod p) {
                      final bool isSelected = state.period.label == p.label;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            p.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : c.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: storeAccent,
                          backgroundColor: c.surface,
                          side: BorderSide(
                            color: isSelected ? storeAccent : c.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) => ref
                              .read(analyticsProvider.notifier)
                              .setPeriod(p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // ── High-Contrast KPI Cards ──────────────────────────────────
                Row(
                  children: <Widget>[
                    _AnalyticsKpiCard(
                      label: 'TOTAL SALES',
                      value: '₱${state.revenue.toStringAsFixed(2)}',
                      sublabel: '${state.txnCount} orders',
                      color: storeAccent,
                    ),
                    const SizedBox(width: 10),
                    _AnalyticsKpiCard(
                      label: 'ESTIMATED PROFIT',
                      value: '₱${state.grossProfit.toStringAsFixed(2)}',
                      sublabel: '${state.profitMargin.toStringAsFixed(1)}% Margin',
                      color: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Component 1: Radial Goal Ring ────────────────────────────
                RadialGoalRing(
                  achieved: state.revenue,
                  target: state.dailyTarget,
                  accentColor: storeAccent,
                  onTapChangeTarget: () => _showChangeTargetDialog(context, ref),
                ),
                const SizedBox(height: 16),

                // ── Component 2: Oras ng Bugso (Peak Hour Heat Strip) ────────
                PeakHourHeatStrip(
                  transactions: state.recentTransactions,
                  accentColor: storeAccent,
                ),
                const SizedBox(height: 16),

                // ── Component 3: Pinakamalakas na Produkto ───────────────────
                TopProductsBarView(
                  topProducts: state.topProducts,
                  accentColor: storeAccent,
                ),
                const SizedBox(height: 16),

                // ── Component 4: Lokal na Payo (AI Business Insight) ─────────
                LokalNaPayoCard(
                  insights: businessTips,
                  accentColor: storeAccent,
                ),
                const SizedBox(height: 16),

                // ── Recent Transactions Quick Section ────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(Icons.history_rounded,
                                  size: 18, color: c.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                isFilipino
                                    ? 'Mga Huling Transaksyon'
                                    : 'Recent Transactions',
                                style: TextStyle(
                                  color: c.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: onOpenTransactions,
                            style: TextButton.styleFrom(
                              foregroundColor: storeAccent,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              isFilipino ? 'Tingnan Lahat' : 'View All',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (state.recentTransactions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              isFilipino
                                  ? 'Wala pang transaksyon na naitala.'
                                  : 'No recorded transactions yet.',
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ...state.recentTransactions.take(4).map((Transaction t) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _showTransactionDetail(context, t),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: c.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: c.border),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Icon(
                                          t.paymentMethod == 'cash'
                                              ? Icons.payments_outlined
                                              : Icons.qr_code_outlined,
                                          size: 16,
                                          color: storeAccent,
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              '#${t.transactionId.substring(0, 6.clamp(0, t.transactionId.length))}',
                                              style: TextStyle(
                                                color: c.text,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              DateFormat('MMM d – h:mm a')
                                                  .format(t.timestamp),
                                              style: TextStyle(
                                                color: c.textTertiary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '₱${t.totalAmount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: c.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangeTargetDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController targetCtrl =
        TextEditingController(text: state.dailyTarget.toStringAsFixed(0));
    final AppColors c = appColors(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Itakda ang Arawang Target (₱)'),
        content: TextField(
          controller: targetCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target na Benta',
            prefixText: '₱ ',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kanselahin'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? newTarget = double.tryParse(targetCtrl.text);
              if (newTarget != null && newTarget > 0) {
                ref.read(analyticsProvider.notifier).setDailyTarget(newTarget);
                Navigator.pop(ctx);
              }
            },
            child: const Text('I-save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final pw.Document doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text('SarE Sales Report',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                  'Period: ${state.period.label}  •  Generated: ${DateFormat('MMM d, y HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: <String>[
                  'Metric',
                  'Value',
                ],
                data: <List<String>>[
                  <String>[
                    'Revenue',
                    'PHP ${state.revenue.toStringAsFixed(2)}'
                  ],
                  <String>['COGS', 'PHP ${state.cogs.toStringAsFixed(2)}'],
                  <String>[
                    'Gross Profit',
                    'PHP ${state.grossProfit.toStringAsFixed(2)}'
                  ],
                  <String>[
                    'Profit Margin',
                    '${state.profitMargin.toStringAsFixed(1)}%'
                  ],
                  <String>['Transactions', '${state.txnCount}'],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Top Products',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: <String>['Product', 'Qty Sold', 'Revenue'],
                data: state.topProducts
                    .map((TopProduct p) => <String>[
                          p.name,
                          '${p.totalQty}',
                          'PHP ${p.totalRevenue.toStringAsFixed(2)}',
                        ])
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    try {
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'SarE_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final String filePath = '${dir.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(await doc.save());
      await OpenFile.open(filePath);
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            icon: Icon(Icons.check_circle_rounded,
                color: appColors(ctx).info, size: 36),
            title: const Text('PDF Saved'),
            content: Text('Report saved to:\n$filePath'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog<void>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            icon: Icon(Icons.error_outline,
                color: appColors(ctx).error, size: 36),
            title: const Text('PDF Error'),
            content: Text('Could not save PDF: $e'),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showTransactionDetail(
      BuildContext context, Transaction txn) async {
    final TransactionDao dao = TransactionDao();
    final List<TransactionLineItem> lineItems =
        await dao.getLineItems(txn.transactionId);

    if (!context.mounted) return;

    final AppColors c = appColors(context);
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Detalye: #${txn.transactionId.substring(0, 6.clamp(0, txn.transactionId.length))}'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (lineItems.isEmpty)
                Text('Walang items na nakalista.',
                    style: TextStyle(color: c.textTertiary))
              else
                ...lineItems.map((TransactionLineItem li) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${li.qty}× ${li.productName ?? li.productId}',
                            style: TextStyle(color: c.text, fontSize: 13),
                          ),
                        ),
                        Text(
                          '₱${li.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Divider(color: c.border),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Kabuuan:',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '₱${txn.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Isara'),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  const _AnalyticsKpiCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
  });

  final String label;
  final String value;
  final String sublabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color: c.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
