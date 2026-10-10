import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sqflite/sqflite.dart' as sql;

import '../application/locale_provider.dart';
import '../data/local/daos/transaction_dao.dart';
import '../data/local/database.dart';
import '../domain/entities/transaction.dart';
import '../theme/app_theme.dart';

final AutoDisposeFutureProvider<List<Transaction>> allTransactionsProvider =
    FutureProvider.autoDispose<List<Transaction>>((Ref ref) async {
  final TransactionDao dao = TransactionDao();
  return dao.getRecent(limit: 200);
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  /// Format payment method for display
  String _formatPaymentMethod(String method, AppLocale locale) {
    if (method.startsWith('ewallet:')) {
      return method.substring(8);
    }
    switch (method) {
      case 'cash':
        return t(locale, 'cash');
      case 'ewallet':
        return t(locale, 'ewallet_qr');
      default:
        return method;
    }
  }

  Future<PaymentRecord?> _getPayment(String transactionId) async {
    // Get payment record from DB
    final sql.Database db = await AppDatabase.instance;
    final List<Map<String, dynamic>> rows = await db.query(
      'payment_records',
      where: 'transaction_id = ?',
      whereArgs: <String>[transactionId],
    );
    if (rows.isEmpty) return null;
    return PaymentRecord.fromMap(rows.first);
  }

  void _showQrSlipDialog(
      BuildContext context, Receipt receipt, Transaction txn, AppColors c) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD62828).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_2, color: Color(0xFFD62828), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Digital Receipt QR',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B1B1B),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: QrImageView(
                data: receipt.qrPayload,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ref: ${receipt.receiptId}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Halaga: ₱${txn.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Color(0xFFD62828),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y – h:mm a').format(txn.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Isara', style: TextStyle(color: Color(0xFFD62828), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showTransactionDetail(
      BuildContext context, Transaction txn, AppLocale locale, AppColors c) async {
    final TransactionDao dao = TransactionDao();
    final List<TransactionLineItem> lineItems =
        await dao.getLineItems(txn.transactionId);
    final PaymentRecord? payment = await _getPayment(txn.transactionId);
    final Receipt? receipt = await dao.getReceipt(txn.transactionId);

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(children: <Widget>[
                  const Icon(Icons.receipt_long_outlined,
                      color: Colors.white, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    t(locale, 'transaction_detail'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, y – h:mm a').format(txn.timestamp),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ]),
              ),

              // Line items
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (lineItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(t(locale, 'no_line_items'),
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 13)),
                        )
                      else
                        ...lineItems.map((TransactionLineItem li) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: <Widget>[
                              Expanded(
                                child: Text(
                                  '${li.qty}× ${li.productName ?? li.productId}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '₱${li.subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          );
                        }),
                      Divider(color: c.border, height: 20),
                      // Payment method
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(t(locale, 'payment'),
                              style: const TextStyle(fontSize: 12)),
                          Text(
                            _formatPaymentMethod(
                                payment?.method ?? txn.paymentMethod, locale),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(t(locale, 'total').toUpperCase(),
                              style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          Text(
                            '₱${txn.totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: c.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18),
                          ),
                        ],
                      ),
                      if (txn.changeDue > 0) ...<Widget>[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(t(locale, 'change'),
                                style:
                                    TextStyle(color: c.info, fontSize: 12)),
                            Text(
                              '₱${txn.changeDue.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: c.info,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Reference code if available
                      if (receipt != null) ...<Widget>[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFFC93C)),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.receipt, size: 16, color: Color(0xFFB45309)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ref: ${receipt.receiptId}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1B1B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Status
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: txn.status == 'completed'
                                ? c.info.withValues(alpha: 0.12)
                                : c.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            txn.status.toUpperCase(),
                            style: TextStyle(
                              color: txn.status == 'completed'
                                  ? c.info
                                  : c.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: <Widget>[
                    if (receipt != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showQrSlipDialog(context, receipt, txn, c);
                          },
                          icon: const Icon(Icons.qr_code_2, size: 18),
                          label: const Text('Ipakita ang QR Slip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD62828),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (receipt != null) const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: c.border),
                        ),
                        child: Text(t(locale, 'close')),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = appColors(context);
    final AppLocale locale = ref.watch(localeProvider);
    final AsyncValue<List<Transaction>> txnsAsync =
        ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(locale, 'transactions')),
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('${t(locale, 'error')}: $e')),
        data: (List<Transaction> txns) {
          if (txns.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(allTransactionsProvider),
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 80),
                  Icon(Icons.receipt_long_outlined,
                      size: 56, color: c.textTertiary),
                  const SizedBox(height: 12),
                  Text(t(locale, 'no_data'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary)),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(t(locale, 'refresh'),
                        style: TextStyle(color: c.textTertiary, fontSize: 12)),
                  ),
                ],
              ),
            );
          }

          final TransactionDao dao = TransactionDao();

          return RefreshIndicator(
              onRefresh: () async => ref.invalidate(allTransactionsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: txns.length,
                itemBuilder: (BuildContext context, int i) {
                  final Transaction tObj = txns[i];
                  final String refCode = (tObj.receiptId ?? tObj.transactionId.substring(0, 8)).toUpperCase();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => _showTransactionDetail(context, tObj, locale, c),
                      leading: CircleAvatar(
                        backgroundColor: tObj.status == 'completed'
                            ? const Color(0xFFD62828).withValues(alpha: 0.12)
                            : c.warning.withValues(alpha: 0.15),
                        child: Icon(
                          tObj.paymentMethod == 'cash'
                              ? Icons.payments_outlined
                              : Icons.qr_code_outlined,
                          color: tObj.status == 'completed' ? const Color(0xFFD62828) : c.warning,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: <Widget>[
                          Text(
                            'PHP ${tObj.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD62828).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD62828).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '#$refCode',
                              style: const TextStyle(
                                color: Color(0xFFD62828),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(DateFormat('MMM d, y – h:mm a')
                              .format(tObj.timestamp)),
                          Text(_formatPaymentMethod(tObj.paymentMethod, locale).toUpperCase(),
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 11)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.qr_code, size: 22, color: Color(0xFFD62828)),
                            tooltip: 'QR Slip',
                            onPressed: () async {
                              final Receipt? r = await dao.getReceipt(tObj.transactionId);
                              if (!context.mounted) return;
                              if (r != null) {
                                _showQrSlipDialog(context, r, tObj, c);
                              } else {
                                final Receipt fallback = Receipt(
                                  receiptId: tObj.receiptId ?? 'REF-${tObj.transactionId.substring(0, 8).toUpperCase()}',
                                  transactionId: tObj.transactionId,
                                  storeName: 'SARI Tindahan',
                                  timestamp: tObj.timestamp,
                                  qrPayload: 'https://sare-580de.web.app/#ref=${tObj.receiptId ?? tObj.transactionId}',
                                  deliveryStatus: 'sent',
                                );
                                _showQrSlipDialog(context, fallback, tObj, c);
                              }
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tObj.status == 'completed'
                                  ? const Color(0xFFD62828).withValues(alpha: 0.12)
                                  : c.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tObj.status.toUpperCase(),
                              style: TextStyle(
                                color: tObj.status == 'completed' ? const Color(0xFFD62828) : c.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ));
        },
      ),
    );
  }
}
