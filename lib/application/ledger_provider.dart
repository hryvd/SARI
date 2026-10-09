import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/daos/credit_dao.dart';
import '../data/local/daos/customer_dao.dart';
import '../data/local/daos/ledger_dao.dart';
import '../domain/entities/credit_entry.dart';
import '../domain/entities/customer.dart';
import '../domain/entities/ledger_entry.dart';
import 'auth_provider.dart';
import 'sync_provider.dart';

const Uuid _uuid = Uuid();

enum LedgerTimelineFilter {
  lahat, // All
  benta, // Cash sales
  utang, // Credit issued
  bayad, // Payments received
}

class LedgerState {
  const LedgerState({
    this.entries = const <LedgerEntry>[],
    this.customers = const <Customer>[],
    this.filter = LedgerTimelineFilter.lahat,
    this.searchQuery = '',
    this.selectedCustomerId,
    this.totalCashSales = 0.0,
    this.totalOutstandingCredit = 0.0,
    this.totalCollectedPayments = 0.0,
    this.isLoading = false,
  });

  final List<LedgerEntry> entries;
  final List<Customer> customers;
  final LedgerTimelineFilter filter;
  final String searchQuery;
  final String? selectedCustomerId;
  final double totalCashSales;
  final double totalOutstandingCredit;
  final double totalCollectedPayments;
  final bool isLoading;

  List<LedgerEntry> get filteredEntries {
    Iterable<LedgerEntry> list = entries;

    // 1. Filter by entry type
    switch (filter) {
      case LedgerTimelineFilter.lahat:
        break;
      case LedgerTimelineFilter.benta:
        list = list.where((LedgerEntry e) => e.isSale);
        break;
      case LedgerTimelineFilter.utang:
        list = list.where((LedgerEntry e) => e.isUtang);
        break;
      case LedgerTimelineFilter.bayad:
        list = list.where((LedgerEntry e) => e.isPayment);
        break;
    }

    // 2. Filter by search query
    if (searchQuery.isNotEmpty) {
      final String q = searchQuery.toLowerCase();
      list = list.where((LedgerEntry e) {
        final String name = (e.customerName ?? '').toLowerCase();
        final String note = (e.note ?? '').toLowerCase();
        final String id = e.id.toLowerCase();
        final String amountStr = e.amount.toString();
        return name.contains(q) ||
            note.contains(q) ||
            id.contains(q) ||
            amountStr.contains(q);
      });
    }

    // 3. Filter by selected customer if any
    if (selectedCustomerId != null) {
      list = list.where((LedgerEntry e) => e.customerId == selectedCustomerId);
    }

    return list.toList();
  }

  Customer? get selectedCustomer {
    if (selectedCustomerId == null) return null;
    try {
      return customers.firstWhere((c) => c.customerId == selectedCustomerId);
    } catch (_) {
      return null;
    }
  }

  LedgerState copyWith({
    List<LedgerEntry>? entries,
    List<Customer>? customers,
    LedgerTimelineFilter? filter,
    String? searchQuery,
    String? selectedCustomerId,
    bool clearSelectedCustomer = false,
    double? totalCashSales,
    double? totalOutstandingCredit,
    double? totalCollectedPayments,
    bool? isLoading,
  }) {
    return LedgerState(
      entries: entries ?? this.entries,
      customers: customers ?? this.customers,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCustomerId: clearSelectedCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
      totalCashSales: totalCashSales ?? this.totalCashSales,
      totalOutstandingCredit:
          totalOutstandingCredit ?? this.totalOutstandingCredit,
      totalCollectedPayments:
          totalCollectedPayments ?? this.totalCollectedPayments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LedgerNotifier extends AsyncNotifier<LedgerState> {
  final LedgerDao _ledgerDao = LedgerDao();
  final CustomerDao _customerDao = CustomerDao();
  final CreditDao _creditDao = CreditDao();

  @override
  Future<LedgerState> build() async => _load();

  bool get _isOffline => ref.read(authProvider).value?.isOfflineMode ?? false;

  Future<LedgerState> _load() async {
    // Synchronize historical records into ledger table to guarantee completeness
    await _ledgerDao.syncFromHistoricalTables();

    final List<LedgerEntry> entries = await _ledgerDao.getAllEntries(limit: 300);
    final List<Customer> customers = await _customerDao.getAll();
    final Map<String, double> totals = await _ledgerDao.getLedgerTotals();

    // Also fetch outstanding credit total from customers table
    final double outstandingFromCustomers = customers.fold<double>(
      0.0,
      (sum, c) => sum + c.creditBalance,
    );

    return LedgerState(
      entries: entries,
      customers: customers,
      totalCashSales: totals['cash_sale'] ?? 0.0,
      totalOutstandingCredit: outstandingFromCustomers > 0
          ? outstandingFromCustomers
          : (totals['net_outstanding'] ?? 0.0),
      totalCollectedPayments: totals['utang_payment'] ?? 0.0,
    );
  }

  Future<void> refresh() async {
    state = AsyncData<LedgerState>(
      (state.value ?? const LedgerState()).copyWith(isLoading: true),
    );
    state = AsyncData<LedgerState>(await _load());
  }

  void setFilter(LedgerTimelineFilter filter) {
    if (state.value == null) return;
    state = AsyncData<LedgerState>(state.value!.copyWith(filter: filter));
  }

  void setSearch(String query) {
    if (state.value == null) return;
    state = AsyncData<LedgerState>(state.value!.copyWith(searchQuery: query));
  }

  void selectCustomer(String? customerId) {
    if (state.value == null) return;
    state = AsyncData<LedgerState>(
      state.value!.copyWith(
        selectedCustomerId: customerId,
        clearSelectedCustomer: customerId == null,
      ),
    );
  }

  // ── Unified Operations ───────────────────────────────────────────────────

  /// Add a new customer
  Future<Customer> addCustomer(String name, {String? mobile}) async {
    final Customer customer = Customer(
      customerId: _uuid.v4(),
      name: name,
      mobileNumber: mobile?.isEmpty == true ? null : mobile,
      creditBalance: 0,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await _customerDao.insert(customer);

    if (!_isOffline) {
      try {
        await SyncNotifier.enqueue(
          entityType: 'customers',
          entityId: customer.customerId,
          operation: 'create',
          payload: customer.toMap(),
        );
        ref.read(syncProvider.notifier).sync();
      } catch (_) {}
    }

    await refresh();
    return customer;
  }

  /// Record new credit entry (Utang)
  Future<void> addCredit({
    required String customerId,
    required List<String> items,
    required double amount,
    required DateTime dueDate,
  }) async {
    final DateTime now = DateTime.now();
    final String entryId = _uuid.v4();

    // 1. Insert to credit_entries for due date & reminder tracking
    final CreditEntry creditEntry = CreditEntry(
      entryId: entryId,
      customerId: customerId,
      items: jsonEncode(items),
      amount: amount,
      amountPaid: 0,
      dueDate: dueDate,
      status: 'active',
      reminderCount: 0,
      createdAt: now,
    );
    await _creditDao.insert(creditEntry);

    // 2. Update customer balance
    final Customer? customer = await _customerDao.getById(customerId);
    final double updatedBalance = (customer?.creditBalance ?? 0.0) + amount;
    if (customer != null) {
      await _customerDao.updateCreditBalance(customerId, updatedBalance);
    }

    // 3. Insert directly to unified ledger_entries
    final LedgerEntry ledgerEntry = LedgerEntry(
      id: _uuid.v4(),
      customerId: customerId,
      entryType: 'UTANG_ISSUED',
      amount: amount,
      balanceAfter: updatedBalance,
      timestamp: now,
      note: items.join(', '),
      customerName: customer?.name,
    );
    await _ledgerDao.insertEntry(ledgerEntry);

    if (!_isOffline) {
      try {
        await SyncNotifier.enqueue(
          entityType: 'credit_entries',
          entityId: creditEntry.entryId,
          operation: 'create',
          payload: creditEntry.toMap(),
        );
        ref.read(syncProvider.notifier).sync();
      } catch (_) {}
    }

    await refresh();
  }

  /// Record payment against customer credit (Bayad)
  Future<void> recordRepayment({
    required String customerId,
    required double amountPaid,
    String? note,
  }) async {
    final DateTime now = DateTime.now();
    final Customer? customer = await _customerDao.getById(customerId);
    if (customer == null) return;

    final double newBalance =
        (customer.creditBalance - amountPaid).clamp(0.0, double.infinity);
    await _customerDao.updateCreditBalance(customerId, newBalance);

    // Settle or partially pay oldest active credit entries
    final List<CreditEntry> entries = await _creditDao.getByCustomer(customerId);
    double remainingToPay = amountPaid;
    for (final CreditEntry entry in entries) {
      if (remainingToPay <= 0) break;
      if (entry.isSettled) continue;

      final double needed = entry.amount - entry.amountPaid;
      final double apply = needed < remainingToPay ? needed : remainingToPay;
      remainingToPay -= apply;

      final double newPaid = entry.amountPaid + apply;
      final String newStatus =
          newPaid >= entry.amount ? 'settled' : entry.status;
      await _creditDao.update(
        entry.copyWith(amountPaid: newPaid, status: newStatus),
      );

      final RepaymentRecord record = RepaymentRecord(
        repaymentId: _uuid.v4(),
        entryId: entry.entryId,
        amountPaid: apply,
        timestamp: now,
        notes: note,
      );
      await _creditDao.insertRepayment(record);
    }

    // Insert directly into unified ledger
    final LedgerEntry ledgerEntry = LedgerEntry(
      id: _uuid.v4(),
      customerId: customerId,
      entryType: 'UTANG_PAYMENT',
      amount: amountPaid,
      balanceAfter: newBalance,
      timestamp: now,
      note: note ?? 'Bayad kay ${customer.name}',
      customerName: customer.name,
    );
    await _ledgerDao.insertEntry(ledgerEntry);

    await refresh();
  }

  /// Export unified ledger entries to CSV string
  String exportCsv() {
    final List<LedgerEntry> current = state.value?.filteredEntries ?? <LedgerEntry>[];
    return _ledgerDao.generateCsv(current);
  }
}

final AsyncNotifierProvider<LedgerNotifier, LedgerState> ledgerProvider =
    AsyncNotifierProvider<LedgerNotifier, LedgerState>(LedgerNotifier.new);
