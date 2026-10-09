/// Domain entity – ledger_entries table (Kasaysayan).
/// No Flutter imports. Pure Dart data class.
class LedgerEntry {
  const LedgerEntry({
    required this.id,
    this.transactionId,
    this.customerId,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    required this.timestamp,
    this.note,
    this.customerName,
  });

  final String id;
  final String? transactionId;
  final String? customerId;
  final String entryType; // 'CASH_SALE', 'UTANG_ISSUED', 'UTANG_PAYMENT'
  final double amount;
  final double balanceAfter;
  final DateTime timestamp;
  final String? note;

  // Joined display field
  final String? customerName;

  bool get isSale => entryType == 'CASH_SALE';
  bool get isUtang => entryType == 'UTANG_ISSUED';
  bool get isPayment => entryType == 'UTANG_PAYMENT';

  LedgerEntry copyWith({
    String? id,
    String? transactionId,
    String? customerId,
    String? entryType,
    double? amount,
    double? balanceAfter,
    DateTime? timestamp,
    String? note,
    String? customerName,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      customerName: customerName ?? this.customerName,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'transaction_id': transactionId,
        'customer_id': customerId,
        'entry_type': entryType,
        'amount': amount,
        'balance_after': balanceAfter,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  factory LedgerEntry.fromMap(Map<String, dynamic> m) => LedgerEntry(
        id: m['id'] as String,
        transactionId: m['transaction_id'] as String?,
        customerId: m['customer_id'] as String?,
        entryType: m['entry_type'] as String? ?? 'CASH_SALE',
        amount: (m['amount'] as num).toDouble(),
        balanceAfter: (m['balance_after'] as num? ?? 0.0).toDouble(),
        timestamp: m['timestamp'] != null
            ? DateTime.parse(m['timestamp'] as String)
            : DateTime.now(),
        note: m['note'] as String?,
        customerName: m['customer_name'] as String?,
      );
}
