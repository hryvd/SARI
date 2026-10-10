import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../data/local/daos/credit_dao.dart';
import '../data/local/daos/customer_dao.dart';
import '../data/local/daos/product_dao.dart';
import '../data/local/daos/restock_draft_dao.dart';
import '../data/local/daos/transaction_dao.dart';
import '../domain/entities/credit_entry.dart';
import '../domain/entities/customer.dart';
import '../domain/entities/product.dart';
import '../domain/services/gemma_local_service.dart';
import '../domain/services/nightly_reorder_worker.dart';
import '../domain/services/reorder_engine.dart';
import '../domain/services/sales_prediction_service.dart';
import '../theme/store_theme.dart';
import 'auth_provider.dart';
import 'inventory_provider.dart';

enum AgentRisk { read, draft, change, blocked }

enum AgentDraftState { open, secondConfirm, confirmed, undone }

class AgentDraft {
  const AgentDraft({
    required this.kind, // 'restock', 'utang', 'stock_update', 'prep', 'list'
    required this.title,
    this.reorderDraft,
    required this.totalAmount,
    this.note,
    this.customerId,
    this.customerName,
    this.productId,
    this.productName,
    this.newStock,
  });

  final String kind;
  final String title;
  final ReorderDraft? reorderDraft;
  final double totalAmount;
  final String? note;
  final String? customerId;
  final String? customerName;
  final String? productId;
  final String? productName;
  final int? newStock;
}

class AgentMessage {
  AgentMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.risk,
    this.draft,
    this.draftState = AgentDraftState.open,
    this.intent,
    this.tool,
    this.confidence,
    this.explanation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final bool isUser;
  final String text;
  final AgentRisk? risk;
  final AgentDraft? draft;
  final AgentDraftState draftState;
  final String? intent;
  final String? tool;
  final double? confidence;
  final String? explanation;
  final DateTime timestamp;

  AgentMessage copyWith({
    AgentDraftState? draftState,
    String? text,
  }) =>
      AgentMessage(
        id: id,
        isUser: isUser,
        text: text ?? this.text,
        risk: risk,
        draft: draft,
        draftState: draftState ?? this.draftState,
        intent: intent,
        tool: tool,
        confidence: confidence,
        explanation: explanation,
        timestamp: timestamp,
      );
}

class AgentActivityLogEntry {
  const AgentActivityLogEntry({
    required this.timestamp,
    required this.tool,
    required this.arguments,
    required this.risk,
    required this.by,
  });

  final DateTime timestamp;
  final String tool;
  final String arguments;
  final AgentRisk risk;
  final String by;
}

class AgentState {
  const AgentState({
    this.messages = const <AgentMessage>[],
    this.activityLogs = const <AgentActivityLogEntry>[],
    this.modelReady = true,
    this.isListening = false,
    this.downloadProgress,
    this.heardText,
    this.doubleConfirmThreshold = 500.0,
    this.requireConfirmBeforeChange = true,
    this.aliases = const <String, String>{
      'canton': 'Lucky Me Pancit Canton',
      'kape': 'Kopiko 3-in-1',
      'sardinas': 'Ligo Sardinas',
      'toyo': 'Silver Swan Toyo',
      'suka': 'Datu Puti Suka',
    },
    this.latestPrediction,
    this.forecast7Days = const <SalesPredictionResult>[],
    this.modelStatus = 'Active (Gemma 4 E2B + GBR Offline · 128K)',
  });

  final List<AgentMessage> messages;
  final List<AgentActivityLogEntry> activityLogs;
  final bool modelReady;
  final bool isListening;
  final double? downloadProgress;
  final String? heardText;
  final double doubleConfirmThreshold;
  final bool requireConfirmBeforeChange;
  final Map<String, String> aliases;
  final SalesPredictionResult? latestPrediction;
  final List<SalesPredictionResult> forecast7Days;
  final String modelStatus;

  AgentState copyWith({
    List<AgentMessage>? messages,
    List<AgentActivityLogEntry>? activityLogs,
    bool? modelReady,
    bool? isListening,
    double? downloadProgress,
    String? heardText,
    bool clearHeardText = false,
    double? doubleConfirmThreshold,
    bool? requireConfirmBeforeChange,
    Map<String, String>? aliases,
    SalesPredictionResult? latestPrediction,
    List<SalesPredictionResult>? forecast7Days,
    String? modelStatus,
  }) =>
      AgentState(
        messages: messages ?? this.messages,
        activityLogs: activityLogs ?? this.activityLogs,
        modelReady: modelReady ?? this.modelReady,
        isListening: isListening ?? this.isListening,
        downloadProgress: downloadProgress,
        heardText: clearHeardText ? null : (heardText ?? this.heardText),
        doubleConfirmThreshold:
            doubleConfirmThreshold ?? this.doubleConfirmThreshold,
        requireConfirmBeforeChange:
            requireConfirmBeforeChange ?? this.requireConfirmBeforeChange,
        aliases: aliases ?? this.aliases,
        latestPrediction: latestPrediction ?? this.latestPrediction,
        forecast7Days: forecast7Days ?? this.forecast7Days,
        modelStatus: modelStatus ?? this.modelStatus,
      );
}

class AgentNotifier extends StateNotifier<AgentState> {
  AgentNotifier(this.ref) : super(const AgentState()) {
    _init();
  }

  final Ref ref;
  static const Uuid _uuid = Uuid();

  Future<void> _init() async {
    final AuthState auth = ref.read(authProvider).value ?? const AuthState();
    final bool isSeller = auth.user?.role != 'buyer';
    final String greeting = isSeller
        ? 'Kumusta po! Ako ang inyong SARI Assistant para sa Tindahan. Sabihin o i-type ang inyong kailangan tulad ng restock, benta, o paglista ng utang.'
        : 'Hello po! Ako ang inyong SARI Assistant para sa Mamimili. Sabihin lamang ang inyong kailangan tulad ng paghahanap ng paninda o pag-order.';

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final double threshold =
        prefs.getDouble('agent_confirm_threshold') ?? 500.0;
    final bool requireConfirm =
        prefs.getBool('agent_require_confirm') ?? true;

    // Initialize local offline ML models (GBR and Gemma 4 E2B)
    await SalesPredictionService.instance.initialize();
    final bool isServerOnline =
        await GemmaLocalService.instance.checkLocalServerStatus();
    if (!mounted) return;

    final String initialStatus = isServerOnline
        ? 'Active (Gemma 4 E2B Local Server · 128K)'
        : 'Active (Gemma 4 E2B + GBR Offline · 128K)';

    final List<AgentMessage> currentMessages = state.messages.isEmpty
        ? <AgentMessage>[
            AgentMessage(
              id: 'initial_msg',
              isUser: false,
              text: greeting,
            ),
          ]
        : state.messages;

    state = state.copyWith(
      doubleConfirmThreshold: threshold,
      requireConfirmBeforeChange: requireConfirm,
      modelReady: true,
      modelStatus: initialStatus,
      messages: currentMessages,
    );

    // Run nightly / startup reorder evaluation in background
    if (isSeller) {
      unawaited(const NightlyReorderWorker().run().catchError((_) => null));
    }
  }

  void startListening(bool isSeller) {
    state = state.copyWith(isListening: true, clearHeardText: true);
    Timer(const Duration(milliseconds: 700), () {
      final String simulated;
      if (isSeller) {
        final InventoryState invState =
            ref.read(inventoryProvider).value ?? const InventoryState();
        final List<Product> lowStock =
            invState.products.where((Product p) => p.isLowStock).toList();
        if (lowStock.isNotEmpty) {
          simulated = 'Mag-restock ng ${lowStock.first.name}, good for 3 days';
        } else {
          simulated = 'Ano ang kailangan kong i-restock?';
        }
      } else {
        simulated = 'Kulang sa bahay';
      }
      state = state.copyWith(
        isListening: false,
        heardText: simulated,
      );
    });
  }

  void clearHeard() {
    state = state.copyWith(clearHeardText: true);
  }

  Future<void> submitQuery(String rawQuery, {required bool isSeller}) async {
    final String query = rawQuery.trim();
    if (query.isEmpty) return;

    final String userMsgId = 'user_${DateTime.now().millisecondsSinceEpoch}';

    final List<AgentMessage> updated = List<AgentMessage>.from(state.messages)
      ..add(
        AgentMessage(
          id: userMsgId,
          isUser: true,
          text: query,
        ),
      );
    state = state.copyWith(messages: updated, clearHeardText: true);

    final AsyncValue<InventoryState> inv = ref.read(inventoryProvider);
    final List<Product> products = inv.value?.products ?? <Product>[];
    final StoreType storeType =
        ref.read(authProvider).value?.storeType ?? StoreType.sariSari;

    // Process via on-device Gemma 4 / NLU Engine
    final GemmaInferenceResult result =
        await GemmaLocalService.instance.processQuery(
      query: query,
      isSeller: isSeller,
      storeType: storeType.displayName,
      products: products,
    );

    AgentDraft? draft;
    String responseText = result.message;

    // Deterministic SQLite Execution based on parsed intent
    if (result.intent == 'sales_summary' && result.action == 'query_sales') {
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime todayEnd =
          DateTime(now.year, now.month, now.day, 23, 59, 59);

      try {
        final Map<String, double> summary =
            await TransactionDao().getSummaryForRange(todayStart, todayEnd);
        final double rev = summary['revenue'] ?? 0.0;
        final int txnCount = (summary['txn_count'] ?? 0.0).toInt();
        final double profit = summary['gross_profit'] ?? 0.0;

        if (txnCount > 0) {
          final double margin = rev > 0 ? (profit / rev * 100) : 0.0;
          responseText = 'Benta Ngayong Araw (Ayon sa Lokal na Database):\n'
              '• Kabuuang Benta: ₱${rev.toStringAsFixed(2)} mula sa $txnCount transaksyon.\n'
              '• Tinatayang Tubo: ₱${profit.toStringAsFixed(2)} (${margin.toStringAsFixed(1)}% margin).';
        } else {
          responseText =
              'Walang naitalang transaksyon sa lokal na database ngayong araw (0 transaksyon).';
        }
      } catch (_) {
        responseText =
            'Walang naitalang transaksyon sa tindahan ngayong araw.';
      }
    } else if (result.intent == 'log_utang' && result.draft != null) {
      final String cust =
          result.slots['customer_name'] as String? ?? 'Suki';
      final double amt =
          (result.slots['amount'] as num?)?.toDouble() ?? 0.0;
      draft = AgentDraft(
        kind: 'utang',
        title: 'Utang: $cust',
        customerName: cust,
        totalAmount: amt,
        note: 'Listahan ng Utang sa Kasaysayan ledger.',
      );
    } else if (result.intent == 'update_stock' && result.draft != null) {
      final String prod =
          result.slots['product_name'] as String? ?? 'Paninda';
      final String? prodId = result.slots['product_id'] as String?;
      final int newStock =
          (result.slots['new_stock'] as num?)?.toInt() ?? 0;
      draft = AgentDraft(
        kind: 'stock_update',
        title: 'Baguhin ang Stock: $prod',
        productId: prodId,
        productName: prod,
        newStock: newStock,
        totalAmount: 0.0,
        note: 'Baguhin ang stock sa $newStock.',
      );
    } else if (result.intent == 'resupply_plan' && result.draft != null) {
      final dynamic d = result.draft!['reorderDraft'];
      if (d is ReorderDraft) {
        draft = AgentDraft(
          kind: 'restock',
          title: d.title,
          reorderDraft: d,
          totalAmount: d.totalCost,
          note: d.note,
        );
      }
    }

    AgentRisk riskLevel = AgentRisk.read;
    if (result.risk == 'blocked') {
      riskLevel = AgentRisk.blocked;
    } else if (result.risk == 'draft') {
      riskLevel = AgentRisk.draft;
    } else if (result.risk == 'change') {
      riskLevel = AgentRisk.change;
    }

    _logTool(
      tool: result.tool,
      arguments: query,
      risk: riskLevel,
      by: result.isLocalServer
          ? 'Gemma 4 Local Server'
          : 'On-Device NLU Engine',
    );

    final AgentMessage botMsg = AgentMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: responseText,
      risk: riskLevel,
      draft: draft,
      intent: result.intent,
      tool: result.tool,
      confidence: result.confidence,
      explanation:
          'Pinroseso gamit ang SARI Offline NLU (${result.isLocalServer ? 'Gemma 4 Edge 2B Local Server' : 'On-Device Rule & Slot Parser'}). Natukoy ang layunin: "${result.intent}" (${((result.confidence) * 100).toInt()}% confidence).',
    );
    state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
  }

  Future<void> confirmDraft(String messageId) async {
    final int idx =
        state.messages.indexWhere((AgentMessage m) => m.id == messageId);
    if (idx == -1) return;

    final AgentMessage msg = state.messages[idx];
    final AgentDraft? draft = msg.draft;
    if (draft == null) return;

    // High value threshold double confirm check
    if (state.requireConfirmBeforeChange &&
        draft.totalAmount > state.doubleConfirmThreshold &&
        msg.draftState == AgentDraftState.open) {
      final AgentMessage secondConfirmMsg = msg.copyWith(
        draftState: AgentDraftState.secondConfirm,
      );
      final List<AgentMessage> updated =
          List<AgentMessage>.from(state.messages);
      updated[idx] = secondConfirmMsg;
      state = state.copyWith(messages: updated);
      return;
    }

    final AgentMessage confirmedMsg = msg.copyWith(
      draftState: AgentDraftState.confirmed,
    );
    final List<AgentMessage> updated =
        List<AgentMessage>.from(state.messages);
    updated[idx] = confirmedMsg;
    state = state.copyWith(messages: updated);

    _logTool(
      tool: 'confirm_${draft.kind}',
      arguments: draft.title,
      risk: AgentRisk.change,
      by: 'Owner Tap (Confirmed)',
    );

    // Execute real SQLite persistence in background
    if (draft.kind == 'utang') {
      try {
        final CustomerDao custDao = CustomerDao();
        final CreditDao creditDao = CreditDao();
        String custId = draft.customerId ?? '';
        if (custId.isEmpty) {
          final List<Customer> existing = await custDao.getAll();
          final Customer? found = existing
              .where((Customer c) =>
                  c.name.toLowerCase() ==
                  (draft.customerName ?? '').toLowerCase())
              .firstOrNull;
          if (found != null) {
            custId = found.customerId;
          } else {
            custId = _uuid.v4();
            await custDao.insert(Customer(
              customerId: custId,
              name: draft.customerName ?? 'Suki',
              creditBalance: draft.totalAmount,
              isActive: true,
              createdAt: DateTime.now(),
            ));
          }
        }
        await creditDao.insert(CreditEntry(
          entryId: _uuid.v4(),
          customerId: custId,
          items: draft.note ?? 'Inilista ng SARI Assistant',
          amount: draft.totalAmount,
          amountPaid: 0.0,
          status: 'active',
          reminderCount: 0,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          createdAt: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('Failed to save credit entry: $e');
      }
    } else if (draft.kind == 'stock_update') {
      try {
        if (draft.productId != null && draft.newStock != null) {
          await ProductDao().updateStock(draft.productId!, draft.newStock!);
          ref.read(inventoryProvider.notifier).refresh();
        }
      } catch (e) {
        debugPrint('Failed to update stock: $e');
      }
    } else if (draft.kind == 'restock' && draft.reorderDraft != null) {
      try {
        final List<Map<String, dynamic>> lines =
            draft.reorderDraft!.lines.map((ReorderLine l) => <String, dynamic>{
                  'name': l.name,
                  'qty': l.qtyPacks,
                  'unit': l.unit,
                  'cost': l.totalCost,
                  'supplier': l.supplier,
                }).toList();
        await RestockDraftDao().saveDraft(
          title: draft.title,
          lines: lines,
          totalCost: draft.totalAmount,
        );
      } catch (e) {
        debugPrint('Failed to save restock draft: $e');
      }
    }
  }

  void undoDraft(String messageId) {
    final int idx =
        state.messages.indexWhere((AgentMessage m) => m.id == messageId);
    if (idx == -1) return;

    final AgentMessage msg = state.messages[idx];
    final AgentMessage undoneMsg = msg.copyWith(
      draftState: AgentDraftState.undone,
      text: '${msg.text}\n\n[Na-undo / Binawi ang pag-confirm]',
    );
    final List<AgentMessage> updated =
        List<AgentMessage>.from(state.messages);
    updated[idx] = undoneMsg;
    state = state.copyWith(messages: updated);

    _logTool(
      tool: 'undo_draft',
      arguments: msg.draft?.title ?? '',
      risk: AgentRisk.change,
      by: 'Owner Tap (Undo Window)',
    );
  }

  void _logTool({
    required String tool,
    required String arguments,
    required AgentRisk risk,
    required String by,
  }) {
    final AgentActivityLogEntry entry = AgentActivityLogEntry(
      timestamp: DateTime.now(),
      tool: tool,
      arguments: arguments,
      risk: risk,
      by: by,
    );
    state = state.copyWith(
      activityLogs: <AgentActivityLogEntry>[entry, ...state.activityLogs],
    );
  }

  Future<void> updateSettings({
    double? threshold,
    bool? requireConfirm,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (threshold != null) {
      await prefs.setDouble('agent_confirm_threshold', threshold);
    }
    if (requireConfirm != null) {
      await prefs.setBool('agent_require_confirm', requireConfirm);
    }
    state = state.copyWith(
      doubleConfirmThreshold: threshold,
      requireConfirmBeforeChange: requireConfirm,
    );
  }
}

final StateNotifierProvider<AgentNotifier, AgentState> agentProvider =
    StateNotifierProvider<AgentNotifier, AgentState>(
        (Ref ref) => AgentNotifier(ref));
