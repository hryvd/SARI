import 'package:sqflite/sqflite.dart';

import '../../../domain/entities/ledger_entry.dart';
import '../database.dart';

class LedgerDao {
  Future<Database> get _db => AppDatabase.instance;

  Future<void> insertEntry(LedgerEntry entry) async {
    final Database db = await _db;
    await db.insert(
      'ledger_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LedgerEntry>> getAllEntries({int limit = 100}) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT
        l.*,
        c.name AS customer_name
      FROM ledger_entries l
      LEFT JOIN customers c ON l.customer_id = c.customer_id
      ORDER BY l.timestamp DESC
      LIMIT ?
    ''', <int>[limit]);
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<List<LedgerEntry>> getEntriesByCustomer(String customerId) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT
        l.*,
        c.name AS customer_name
      FROM ledger_entries l
      LEFT JOIN customers c ON l.customer_id = c.customer_id
      WHERE l.customer_id = ?
      ORDER BY l.timestamp DESC
    ''', <String>[customerId]);
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<List<LedgerEntry>> getEntriesByType(String entryType) async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT
        l.*,
        c.name AS customer_name
      FROM ledger_entries l
      LEFT JOIN customers c ON l.customer_id = c.customer_id
      WHERE l.entry_type = ?
      ORDER BY l.timestamp DESC
    ''', <String>[entryType]);
    return rows.map(LedgerEntry.fromMap).toList();
  }

  Future<void> syncFromHistoricalTables() async {
    final Database db = await _db;

    // 1. Backfill from transactions
    final List<Map<String, dynamic>> txns = await db.rawQuery('''
      SELECT t.transaction_id, t.total_amount, t.payment_method, t.timestamp
      FROM transactions t
      WHERE NOT EXISTS (
        SELECT 1 FROM ledger_entries l WHERE l.transaction_id = t.transaction_id
      )
    ''');
    for (final Map<String, dynamic> row in txns) {
      await db.insert(
        'ledger_entries',
        <String, dynamic>{
          'id': 'LE_TXN_${row['transaction_id']}',
          'transaction_id': row['transaction_id'],
          'customer_id': null,
          'entry_type': 'CASH_SALE',
          'amount': (row['total_amount'] as num).toDouble(),
          'balance_after': 0.0,
          'timestamp': row['timestamp'],
          'note': 'Sale via ${row['payment_method']}',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 2. Backfill from credit_entries
    final List<Map<String, dynamic>> credits = await db.rawQuery('''
      SELECT c.entry_id, c.customer_id, c.amount, c.created_at, c.items, cust.name as customer_name, cust.credit_balance
      FROM credit_entries c
      LEFT JOIN customers cust ON c.customer_id = cust.customer_id
      WHERE NOT EXISTS (
        SELECT 1 FROM ledger_entries l WHERE l.id = ('LE_CRD_' || c.entry_id)
      )
    ''');
    for (final Map<String, dynamic> row in credits) {
      await db.insert(
        'ledger_entries',
        <String, dynamic>{
          'id': 'LE_CRD_${row['entry_id']}',
          'transaction_id': null,
          'customer_id': row['customer_id'],
          'entry_type': 'UTANG_ISSUED',
          'amount': (row['amount'] as num).toDouble(),
          'balance_after': ((row['credit_balance'] as num?) ?? (row['amount'] as num)).toDouble(),
          'timestamp': row['created_at'],
          'note': row['items']?.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    // 3. Backfill from repayment_records
    final List<Map<String, dynamic>> repayments = await db.rawQuery('''
      SELECT r.repayment_id, r.amount_paid, r.timestamp, r.notes, c.customer_id, cust.name as customer_name, cust.credit_balance
      FROM repayment_records r
      JOIN credit_entries c ON r.entry_id = c.entry_id
      LEFT JOIN customers cust ON c.customer_id = cust.customer_id
      WHERE NOT EXISTS (
        SELECT 1 FROM ledger_entries l WHERE l.id = ('LE_REP_' || r.repayment_id)
      )
    ''');
    for (final Map<String, dynamic> row in repayments) {
      await db.insert(
        'ledger_entries',
        <String, dynamic>{
          'id': 'LE_REP_${row['repayment_id']}',
          'transaction_id': null,
          'customer_id': row['customer_id'],
          'entry_type': 'UTANG_PAYMENT',
          'amount': (row['amount_paid'] as num).toDouble(),
          'balance_after': ((row['credit_balance'] as num?) ?? 0.0).toDouble(),
          'timestamp': row['timestamp'],
          'note': row['notes']?.toString() ?? 'Repayment',
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<Map<String, double>> getLedgerTotals() async {
    final Database db = await _db;
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT entry_type, COALESCE(SUM(amount), 0.0) as sum_amount
      FROM ledger_entries
      GROUP BY entry_type
    ''');

    double cashSale = 0.0;
    double utangIssued = 0.0;
    double utangPayment = 0.0;

    for (final Map<String, dynamic> r in rows) {
      final String type = r['entry_type'] as String;
      final double total = ((r['sum_amount'] as num?) ?? 0.0).toDouble();
      if (type == 'CASH_SALE') {
        cashSale = total;
      } else if (type == 'UTANG_ISSUED') {
        utangIssued = total;
      } else if (type == 'UTANG_PAYMENT') {
        utangPayment = total;
      }
    }

    return <String, double>{
      'cash_sale': cashSale,
      'utang_issued': utangIssued,
      'utang_payment': utangPayment,
      'net_outstanding': (utangIssued - utangPayment).clamp(0.0, double.infinity),
    };
  }

  String generateCsv(List<LedgerEntry> entries) {
    final StringBuffer sb = StringBuffer();
    sb.writeln('entry_id,timestamp,entry_type,customer_name,amount_php,customer_remaining_balance,payment_ref');
    for (final LedgerEntry e in entries) {
      final String id = e.id;
      final String ts = e.timestamp.toIso8601String();
      final String type = e.entryType;
      final String cust = (e.customerName ?? '').replaceAll(',', ' ');
      final String amt = e.amount.toStringAsFixed(2);
      final String bal = e.balanceAfter.toStringAsFixed(2);
      final String ref = (e.transactionId ?? e.note ?? '').replaceAll(',', ' ');
      sb.writeln('$id,$ts,$type,$cust,$amt,$bal,$ref');
    }
    return sb.toString();
  }
}

