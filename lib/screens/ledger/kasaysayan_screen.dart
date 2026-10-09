import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/auth_provider.dart';
import '../../application/ledger_provider.dart';
import '../../application/locale_provider.dart';
import '../../data/local/daos/transaction_dao.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/ledger_entry.dart';
import '../../domain/entities/transaction.dart';
import '../../theme/app_theme.dart';
import '../../theme/store_theme.dart';

class KasaysayanScreen extends ConsumerStatefulWidget {
  const KasaysayanScreen({super.key});

  @override
  ConsumerState<KasaysayanScreen> createState() => _KasaysayanScreenState();
}

class _KasaysayanScreenState extends ConsumerState<KasaysayanScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showCustomersList = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AppLocale locale = ref.watch(localeProvider);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final Color storeAccent = StoreColors.forType(auth.storeType);

    final ledgerAsync = ref.watch(ledgerProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: ledgerAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error: $err',
              style: TextStyle(color: c.error),
            ),
          ),
          data: (LedgerState state) {
            return RefreshIndicator(
              onRefresh: () async => ref.read(ledgerProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: <Widget>[
                  // ── Screen Header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    t(locale, 'kasaysayan_title'),
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    t(locale, 'kasaysayan_subtitle'),
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
                                    tooltip: 'CSV Export',
                                    onPressed: () => _exportCsv(context),
                                    icon: const Icon(Icons.download_rounded, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: c.surface,
                                      foregroundColor: c.text,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    tooltip: 'Magdagdag ng Utang',
                                    onPressed: () => _showAddCreditDialog(context, state.customers),
                                    icon: const Icon(Icons.add, size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: storeAccent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ── Summary Metrics Bar ──────────────────────────────
                          _buildSummaryMetrics(state, c, storeAccent),
                          const SizedBox(height: 16),

                          // ── Search & Filter Chips ────────────────────────────
                          _buildSearchAndFilters(state, c, storeAccent),
                        ],
                      ),
                    ),
                  ),

                  // ── Main Content: Customers View or Timeline List ────────────
                  if (_showCustomersList)
                    _buildCustomersSliver(state, c, storeAccent)
                  else
                    _buildTimelineSliver(state, c, storeAccent),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 40),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Summary KPI Cards ───────────────────────────────────────────────────────
  Widget _buildSummaryMetrics(
      LedgerState state, AppColors c, Color accent) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryBox(
            title: 'Benta (Cash)',
            amount: '₱${state.totalCashSales.toStringAsFixed(2)}',
            color: const Color(0xFF2E7D32), // Green
            icon: Icons.payments_outlined,
            bgColor: c.surface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryBox(
            title: 'Utang (Pautang)',
            amount: '₱${state.totalOutstandingCredit.toStringAsFixed(2)}',
            color: const Color(0xFFFFB300), // Amber
            icon: Icons.assignment_late_outlined,
            bgColor: c.surface,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryBox(
            title: 'Nasingil (Bayad)',
            amount: '₱${state.totalCollectedPayments.toStringAsFixed(2)}',
            color: const Color(0xFF0288D1), // Sky Blue
            icon: Icons.check_circle_outline,
            bgColor: c.surface,
          ),
        ),
      ],
    );
  }

  // ── Search & Timeline Filters ───────────────────────────────────────────────
  Widget _buildSearchAndFilters(
      LedgerState state, AppColors c, Color accent) {
    return Column(
      children: <Widget>[
        // Search Input
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (q) => ref.read(ledgerProvider.notifier).setSearch(q),
            style: TextStyle(color: c.text, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Maghanap ng transaksyon, customer, o gamit...',
              hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
              prefixIcon: Icon(Icons.search, size: 20, color: c.textTertiary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        ref.read(ledgerProvider.notifier).setSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips row + Customer switch
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    _FilterChip(
                      label: 'Lahat',
                      isSelected: !_showCustomersList &&
                          state.filter == LedgerTimelineFilter.lahat,
                      onTap: () {
                        setState(() => _showCustomersList = false);
                        ref
                            .read(ledgerProvider.notifier)
                            .setFilter(LedgerTimelineFilter.lahat);
                      },
                      accentColor: accent,
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Benta',
                      isSelected: !_showCustomersList &&
                          state.filter == LedgerTimelineFilter.benta,
                      onTap: () {
                        setState(() => _showCustomersList = false);
                        ref
                            .read(ledgerProvider.notifier)
                            .setFilter(LedgerTimelineFilter.benta);
                      },
                      accentColor: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Utang',
                      isSelected: !_showCustomersList &&
                          state.filter == LedgerTimelineFilter.utang,
                      onTap: () {
                        setState(() => _showCustomersList = false);
                        ref
                            .read(ledgerProvider.notifier)
                            .setFilter(LedgerTimelineFilter.utang);
                      },
                      accentColor: const Color(0xFFFFB300),
                    ),
                    const SizedBox(width: 6),
                    _FilterChip(
                      label: 'Bayad',
                      isSelected: !_showCustomersList &&
                          state.filter == LedgerTimelineFilter.bayad,
                      onTap: () {
                        setState(() => _showCustomersList = false);
                        ref
                            .read(ledgerProvider.notifier)
                            .setFilter(LedgerTimelineFilter.bayad);
                      },
                      accentColor: const Color(0xFF0288D1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Toggle Customers List
            ActionChip(
              avatar: Icon(
                _showCustomersList
                    ? Icons.list_alt_rounded
                    : Icons.people_alt_outlined,
                size: 16,
                color: _showCustomersList ? Colors.white : c.textSecondary,
              ),
              label: Text(
                _showCustomersList ? 'Timeline' : 'Mga Tao',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _showCustomersList ? Colors.white : c.textSecondary,
                ),
              ),
              backgroundColor:
                  _showCustomersList ? accent : c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _showCustomersList ? accent : c.border,
                ),
              ),
              onPressed: () {
                setState(() => _showCustomersList = !_showCustomersList);
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Timeline Sliver ────────────────────────────────────────────────────────
  Widget _buildTimelineSliver(
      LedgerState state, AppColors c, Color accent) {
    final List<LedgerEntry> entries = state.filteredEntries;

    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Column(
            children: <Widget>[
              Icon(Icons.history_toggle_off_rounded,
                  size: 54, color: c.textTertiary),
              const SizedBox(height: 12),
              Text(
                'Walang nakitang transaksyon sa kasaysayan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext ctx, int i) {
            final LedgerEntry entry = entries[i];
            final bool showDateHeader = i == 0 ||
                !_isSameDay(entries[i - 1].timestamp, entry.timestamp);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (showDateHeader) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Text(
                      _formatDateHeader(entry.timestamp),
                      style: TextStyle(
                        color: c.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                _LedgerTimelineCard(
                  entry: entry,
                  colors: c,
                  onTap: () => _handleEntryTap(ctx, entry, c),
                ),
                const SizedBox(height: 10),
              ],
            );
          },
          childCount: entries.length,
        ),
      ),
    );
  }

  // ── Customers List Sliver ──────────────────────────────────────────────────
  Widget _buildCustomersSliver(
      LedgerState state, AppColors c, Color accent) {
    final List<Customer> customers = state.customers;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext ctx, int i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Talaan ng mga Customer (${customers.length})',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddCustomerDialog(ctx),
                      icon: const Icon(Icons.person_add_alt_1, size: 16),
                      label: const Text('Bagong Tao', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: accent),
                    ),
                  ],
                ),
              );
            }

            final Customer cust = customers[i - 1];
            final bool hasBalance = cust.creditBalance > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasBalance
                      ? const Color(0xFFFFB300).withValues(alpha: 0.6)
                      : c.border,
                ),
                boxShadow: hasBalance
                    ? <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFFB300).withValues(alpha: 0.08),
                          blurRadius: 10,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: hasBalance
                        ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                        : c.border.withValues(alpha: 0.5),
                    child: Text(
                      cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: hasBalance ? const Color(0xFFFFB300) : c.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          cust.name,
                          style: TextStyle(
                            color: c.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (cust.mobileNumber != null)
                          Text(
                            cust.mobileNumber!,
                            style: TextStyle(
                              color: c.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '₱${cust.creditBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: hasBalance ? const Color(0xFFFFB300) : c.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          InkWell(
                            onTap: () => _showCustomerStatementSheet(ctx, cust, c, accent),
                            child: Text(
                              'Kasaysayan',
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (hasBalance) ...<Widget>[
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => _showPaymentDialog(ctx, cust, c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0288D1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Magbayad',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: customers.length + 1,
        ),
      ),
    );
  }

  // ── Actions & Dialogs ──────────────────────────────────────────────────────
  void _handleEntryTap(BuildContext context, LedgerEntry entry, AppColors c) {
    if (entry.isSale && entry.transactionId != null) {
      _showTransactionReceipt(context, entry.transactionId!, c);
    } else if (entry.customerId != null) {
      final Customer? customer = ref
          .read(ledgerProvider)
          .value
          ?.customers
          .firstWhere((cust) => cust.customerId == entry.customerId,
              orElse: () => Customer(
                    customerId: entry.customerId!,
                    name: entry.customerName ?? 'Customer',
                    creditBalance: 0.0,
                    isActive: true,
                    createdAt: DateTime.now(),
                  ));
      if (customer != null) {
        final AuthState auth = ref.read(authProvider).value ?? const AuthState();
        _showCustomerStatementSheet(context, customer, c, StoreColors.forType(auth.storeType));
      }
    }
  }

  Future<void> _showTransactionReceipt(
      BuildContext context, String txnId, AppColors c) async {
    final TransactionDao dao = TransactionDao();
    final List<TransactionLineItem> items = await dao.getLineItems(txnId);

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: <Widget>[
            Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Detalye ng Resibo', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (items.isEmpty)
                Text('Walang nakitang listahan ng binili.',
                    style: TextStyle(color: c.textTertiary))
              else
                ...items.map((TransactionLineItem it) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              '${it.qty}x ${it.productName ?? it.productId}',
                              style: TextStyle(color: c.text, fontSize: 13),
                            ),
                          ),
                          Text(
                            '₱${it.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 12),
              Divider(color: c.border),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Kabuuan:',
                      style: TextStyle(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '₱${items.fold<double>(0.0, (sum, i) => sum + i.subtotal).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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

  void _showCustomerStatementSheet(
      BuildContext context, Customer customer, AppColors c, Color accent) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(ledgerProvider).value;
            final List<LedgerEntry> customerEntries = state?.entries
                    .where((e) => e.customerId == customer.customerId)
                    .toList() ??
                <LedgerEntry>[];

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.92,
              expand: false,
              builder: (_, scrollCtrl) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    children: <Widget>[
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: c.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Customer Info Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: c.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  customer.name,
                                  style: TextStyle(
                                    color: c.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (customer.mobileNumber != null)
                                  Text(
                                    customer.mobileNumber!,
                                    style: TextStyle(
                                      color: c.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                const Text(
                                  'Kasalukuyang Utang',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                Text(
                                  '₱${customer.creditBalance.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Color(0xFFFFB300),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Pay Button
                      if (customer.creditBalance > 0)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showPaymentDialog(context, customer, c);
                            },
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Magbayad ng Utang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Customer History
                      Expanded(
                        child: ListView.builder(
                          controller: scrollCtrl,
                          itemCount: customerEntries.length,
                          itemBuilder: (context, idx) {
                            final entry = customerEntries[idx];
                            return _LedgerTimelineCard(
                              entry: entry,
                              colors: c,
                              onTap: () {},
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPaymentDialog(BuildContext context, Customer customer, AppColors c) {
    final TextEditingController amtCtrl =
        TextEditingController(text: customer.creditBalance.toStringAsFixed(2));
    final TextEditingController noteCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Bayad mula kay ${customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Halaga ng Bayad (₱)',
                prefixText: '₱ ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Tala / Note (Optional)',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kanselahin'),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? amt = double.tryParse(amtCtrl.text);
              if (amt != null && amt > 0) {
                await ref.read(ledgerProvider.notifier).recordRepayment(
                      customerId: customer.customerId,
                      amountPaid: amt,
                      note: noteCtrl.text.isNotEmpty ? noteCtrl.text : null,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Itala ang Bayad'),
          ),
        ],
      ),
    );
  }

  void _showAddCreditDialog(BuildContext context, List<Customer> customers) {
    if (customers.isEmpty) {
      _showAddCustomerDialog(context);
      return;
    }

    String selectedCustId = customers.first.customerId;
    final TextEditingController amtCtrl = TextEditingController();
    final TextEditingController itemsCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final c = appColors(context);
          return AlertDialog(
            backgroundColor: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('Bagong Utang (Credit)'),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      initialValue: selectedCustId,
                      decoration: const InputDecoration(labelText: 'Pangalan ng Customer'),
                      items: customers
                          .map((cust) => DropdownMenuItem(
                                value: cust.customerId,
                                child: Text(cust.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCustId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amtCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Kabuuang Halaga (₱)',
                        prefixText: '₱ ',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: itemsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mga Gamit / Items (e.g. 2kg Bigas, Sardinas)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Petsa ng Singilan (Due Date)'),
                      subtitle: Text(DateFormat('MMM d, y').format(dueDate)),
                      trailing: IconButton(
                        icon: const Icon(Icons.calendar_month),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setDialogState(() => dueDate = picked);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Kanselahin'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final double? amt = double.tryParse(amtCtrl.text);
                  if (amt != null && amt > 0) {
                    final items = itemsCtrl.text.isNotEmpty
                        ? itemsCtrl.text.split(',').map((s) => s.trim()).toList()
                        : <String>['Utang'];
                    await ref.read(ledgerProvider.notifier).addCredit(
                          customerId: selectedCustId,
                          items: items,
                          amount: amt,
                          dueDate: dueDate,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB300),
                  foregroundColor: Colors.black,
                ),
                child: const Text('I-save ang Utang'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController phoneCtrl = TextEditingController();
    final c = appColors(context);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Magdagdag ng Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Pangalan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Numero ng Telepono (Optional)'),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kanselahin'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                await ref.read(ledgerProvider.notifier).addCustomer(
                      nameCtrl.text.trim(),
                      mobile: phoneCtrl.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Idagdag'),
          ),
        ],
      ),
    );
  }

  void _exportCsv(BuildContext context) {
    final String csvData = ref.read(ledgerProvider.notifier).exportCsv();
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Kasaysayan CSV Export'),
        content: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Handa na ang ulat ng Kasaysayan:'),
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csvData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateHeader(DateTime dt) {
    final DateTime now = DateTime.now();
    if (_isSameDay(dt, now)) {
      return 'NGAYON – ${DateFormat('MMMM d, y').format(dt).toUpperCase()}';
    }
    final DateTime yesterday = now.subtract(const Duration(days: 1));
    if (_isSameDay(dt, yesterday)) {
      return 'KAHAPON – ${DateFormat('MMMM d, y').format(dt).toUpperCase()}';
    }
    return DateFormat('EEEE – MMMM d, y').format(dt).toUpperCase();
  }
}

// ── Supporting Stateless Widgets ─────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.bgColor,
  });

  final String title;
  final String amount;
  final Color color;
  final IconData icon;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : c.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LedgerTimelineCard extends StatelessWidget {
  const _LedgerTimelineCard({
    required this.entry,
    required this.colors,
    required this.onTap,
  });

  final LedgerEntry entry;
  final AppColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String typeBadge;
    final Color badgeColor;
    final String amountPrefix;
    final String title;
    final String subtitle;

    if (entry.isSale) {
      typeBadge = '[BENTA]';
      badgeColor = const Color(0xFF2E7D32); // Green
      amountPrefix = '+₱';
      title = entry.transactionId != null
          ? 'Cash Sale #${entry.transactionId!.substring(0, 6.clamp(0, entry.transactionId!.length))}'
          : 'Benta';
      subtitle = entry.note ?? 'Cash Received';
    } else if (entry.isUtang) {
      typeBadge = '[UTANG]';
      badgeColor = const Color(0xFFFFB300); // Amber
      amountPrefix = '+₱';
      title = entry.customerName ?? 'Customer';
      final String balStr = 'Bal: ₱${entry.balanceAfter.toStringAsFixed(2)}';
      final String noteStr = entry.note != null ? ' • ${entry.note}' : '';
      subtitle = '$balStr$noteStr';
    } else {
      typeBadge = '[BAYAD]';
      badgeColor = const Color(0xFF0288D1); // Blue
      amountPrefix = '-₱';
      title = entry.customerName != null
          ? '${entry.customerName} (Payment)'
          : 'Bayad sa Utang';
      subtitle = entry.note ?? 'Repayment';
    }

    final String timeStr = DateFormat('h:mm a').format(entry.timestamp);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Badge tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                typeBadge,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '$amountPrefix${entry.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
