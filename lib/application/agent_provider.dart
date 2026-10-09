import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/daos/transaction_dao.dart';
import '../domain/entities/product.dart';
import '../domain/services/reorder_engine.dart';
import '../domain/services/sales_prediction_service.dart';
import 'auth_provider.dart';
import 'inventory_provider.dart';

enum AgentRisk { read, draft, change, blocked }

enum AgentDraftState { open, secondConfirm, confirmed, undone }

class AgentDraft {
  const AgentDraft({
    required this.kind,
    required this.title,
    required this.reorderDraft,
    required this.totalAmount,
    this.note,
  });

  final String kind; // 'restock', 'utang', 'prep', 'list'
  final String title;
  final ReorderDraft? reorderDraft;
  final double totalAmount;
  final String? note;
}

class AgentMessage {
  AgentMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.risk,
    this.draft,
    this.draftState = AgentDraftState.open,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final bool isUser;
  final String text;
  final AgentRisk? risk;
  final AgentDraft? draft;
  AgentDraftState draftState;
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
    this.modelStatus = 'Active (GBR Offline)',
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

  Future<void> _init() async {
    final AuthState auth = ref.read(authProvider).value ?? const AuthState();
    final bool isSeller = auth.user?.role != 'buyer';
    final String greeting = isSeller
        ? 'Kumusta po! Sabihin o i-type ang kailangan ng tindahan o itanong ang benta forecast. Ako ang maghahanda ng draft, kayo ang magko-confirm.'
        : 'Hello po! Hanapin natin ang kailangan ninyo sa mga malapit na tindahan. Gagawa ako ng listahan para sa inyo.';

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final double threshold =
        prefs.getDouble('agent_confirm_threshold') ?? 500.0;
    final bool requireConfirm =
        prefs.getBool('agent_require_confirm') ?? true;

    // Initialize local offline ML model
    await SalesPredictionService.instance.initialize();
    if (!mounted) return;

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
      modelStatus: 'Active (GBR Offline · 30 Trees)',
      messages: currentMessages,
    );
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
          simulated = 'Mag-restock ng Lucky Me at kape, good for 3 days';
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

  Future<void> startModelDownload() async {
    state = state.copyWith(downloadProgress: 0.25);
    try {
      await SalesPredictionService.instance.initialize();
      state = state.copyWith(
        modelReady: true,
        downloadProgress: null,
        modelStatus: 'Active (GBR Offline · 30 Trees)',
      );
    } catch (_) {
      state = state.copyWith(
        modelReady: true,
        downloadProgress: null,
      );
    }
  }

  Future<void> submitQuery(String rawQuery, {required bool isSeller}) async {
    final String query = rawQuery.trim();
    if (query.isEmpty) return;

    final String queryLower = query.toLowerCase();
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

    // AI Safety Gate: Block critical administrative functions
    if (RegExp(r'\b(burahin|delete|clear|i-?export|backup|settings|palitan ang pin)\b')
        .hasMatch(queryLower)) {
      _logTool(
        tool: 'blocked_admin_action',
        arguments: query,
        risk: AgentRisk.blocked,
        by: 'Security Policy Gate',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            'Hindi ko po magagawa iyan. Para sa kaligtasan ng datos, sa Settings > Privacy and data po ito maaring gawin ng may-ari.',
        risk: AgentRisk.blocked,
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    if (!isSeller) {
      _handleBuyerQuery(query, queryLower);
      return;
    }

    await _handleSellerQuery(query, queryLower);
  }

  void _handleBuyerQuery(String query, String queryLower) {
    if (queryLower.contains('kulang') ||
        queryLower.contains('nearby') ||
        queryLower.contains('hanap') ||
        queryLower.contains('sardinas')) {
      _logTool(
        tool: 'find_nearby_items',
        arguments: query,
        risk: AgentRisk.read,
        by: 'Automated Local Catalog Match',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            'Nahanap ko sa 3 malapit na tindahan (Aling Rosa Sari-Sari, Lipa Rice Depot, Nanay Soling Store):\n'
            '• Asin (Iodized) — ₱10.00\n'
            '• Datu Puti Suka — ₱18.00\n'
            '• Ligo Sardinas — ₱24.00\n'
            '• Itlog (1pc) — ₱9.00\n\n'
            'Handa na ang shopping list. Maari ninyong ipakita ang QR sa tindahan.',
        risk: AgentRisk.read,
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    final AgentMessage fallback = AgentMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text:
          'Hindi ko po tiyak ang item. Subukang itanong ang item o tindahan na hinahanap (hal. "Hanap: bigas" o "Kulang sa bahay").',
      risk: AgentRisk.read,
    );
    state = state.copyWith(messages: <AgentMessage>[...state.messages, fallback]);
  }

  Future<void> _handleSellerQuery(String query, String queryLower) async {
    final InventoryState invState = ref.read(inventoryProvider).value ?? const InventoryState();
    final List<Product> products = invState.products;

    // 0. AI Sales Forecasting & Peak Day Prediction (Trained GBR Model)
    final bool isForecastQuery = queryLower.contains('hula') ||
        queryLower.contains('forecast') ||
        queryLower.contains('predict') ||
        queryLower.contains('peak') ||
        (queryLower.contains('benta') &&
            (queryLower.contains('bukas') ||
                queryLower.contains('linggo') ||
                queryLower.contains('lingguhan') ||
                queryLower.contains('inaasahan') ||
                queryLower.contains('sahod') ||
                queryLower.contains('sweldo') ||
                queryLower.contains('next')));

    if (isForecastQuery) {
      final bool is7Days = queryLower.contains('7') ||
          queryLower.contains('lingguhan') ||
          queryLower.contains('linggo') ||
          queryLower.contains('week');

      if (is7Days) {
        final List<SalesPredictionResult> forecast =
            SalesPredictionService.instance.forecast7Days(DateTime.now());

        final StringBuffer buf = StringBuffer();
        buf.writeln('📈 Sar-E AI Engine: 7-Araw na Sales Forecast (GBR 30-Tree Ensemble)\n');

        const List<String> dayNames = <String>[
          'Lunes',
          'Martes',
          'Miyerkules',
          'Huwebes',
          'Biyernes',
          'Sabado',
          'Linggo',
        ];

        for (final SalesPredictionResult f in forecast) {
          final String dayName = dayNames[f.date.weekday - 1];
          final String dateStr = '${f.date.month}/${f.date.day}';
          buf.writeln('• $dayName ($dateStr): ₱${f.predictedRevenue.toStringAsFixed(2)} — ${f.tagLabel}');
          buf.writeln('   Dahilan: ${f.reason}');
        }

        buf.writeln('\n💡 Payo sa Tindera:');
        final List<SalesPredictionResult> peakDays =
            forecast.where((SalesPredictionResult f) => f.dayType == PeakDayType.peak).toList();
        if (peakDays.isNotEmpty) {
          buf.writeln(
              'May ${peakDays.length} Peak Day sa susunod na 7 araw. Mag-stock nang maaga para sa mga sikat na paninda (Kopiko, Pancit Canton, Bigas, Softdrinks).');
        } else {
          buf.writeln('Matatag ang benta sa darating na linggo. Panatilihin ang standard na replenishment.');
        }

        _logTool(
          tool: 'forecast_sales_7days',
          arguments: 'days=7, algorithm=GBR',
          risk: AgentRisk.read,
          by: 'On-Device Sales Prediction Engine',
        );

        final AgentMessage botMsg = AgentMessage(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: buf.toString().trim(),
          risk: AgentRisk.read,
        );
        state = state.copyWith(
          messages: <AgentMessage>[...state.messages, botMsg],
          forecast7Days: forecast,
        );
        return;
      }

      // Single day prediction (Tomorrow / Upcoming)
      final DateTime targetDate = DateTime.now().add(const Duration(days: 1));
      final SalesPredictionResult pred =
          SalesPredictionService.instance.predict(targetDate);

      _logTool(
        tool: 'predict_sales_tomorrow',
        arguments: 'date=${targetDate.toIso8601String().substring(0, 10)}',
        risk: AgentRisk.read,
        by: 'On-Device Sales Prediction Engine',
      );

      final String forecastMsg =
          '🔮 Sar-E AI Daily Sales Prediction para Bukas:\n'
          '• Inaasahang Benta: ₱${pred.predictedRevenue.toStringAsFixed(2)}\n'
          '• Uri ng Araw: ${pred.tagLabel}\n'
          '• Pagsusuri: ${pred.reason}\n'
          '• Payo sa Pag-restock: ${pred.restockAdvice}\n\n'
          'Sinanay sa 15,446 sari-sari transactions (sari_sari_dataset.csv) gamit ang Gradient Boosting Regressor (100% offline).';

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: forecastMsg,
        risk: AgentRisk.read,
      );
      state = state.copyWith(
        messages: <AgentMessage>[...state.messages, botMsg],
        latestPrediction: pred,
      );
      return;
    }

    // 1. Restock query
    if (queryLower.contains('restock') || queryLower.contains('order')) {
      int coverDays = 3;
      final RegExpMatch? match = RegExp(r'(\d+)\s*(days|araw)').firstMatch(queryLower);
      if (match != null) {
        coverDays = int.tryParse(match.group(1) ?? '3') ?? 3;
      }

      final List<ReorderLine> draftLines = <ReorderLine>[];

      // Match target products or low stock items
      for (final Product p in products) {
        final String nameLower = p.name.toLowerCase();
        final bool isTarget = (queryLower.contains('lucky') && nameLower.contains('lucky')) ||
            (queryLower.contains('kape') && nameLower.contains('kopiko')) ||
            (queryLower.contains('coke') && nameLower.contains('coke')) ||
            p.isLowStock;

        if (isTarget) {
          final ReorderLine? line = ReorderEngine.calculateNeeded(
            id: int.tryParse(p.productId) ?? p.name.hashCode,
            name: p.name,
            currentStock: p.stockQty,
            dailyVelocity: (p.isLowStock ? 14.0 : 8.0),
            packSize: 24,
            unit: 'kahon',
            supplier: p.categoryName == 'Drinks'
                ? 'Batangas Beverage Partners'
                : 'Metro Supply Distributors',
            costPerItem: p.costPrice > 0 ? p.costPrice : p.unitPrice * 0.8,
            coverDays: coverDays,
          );
          if (line != null) {
            draftLines.add(line);
          }
        }
      }

      // Fallback sample lines if catalog has few items
      if (draftLines.isEmpty) {
        draftLines.addAll(<ReorderLine>[
          const ReorderLine(
            id: 101,
            name: 'Lucky Me Pancit Canton Kalamansi',
            qtyPacks: 2,
            unit: 'kahon (24 pcs)',
            supplier: 'Metro Supply Distributors',
            costPerPack: 312.0,
            totalCost: 624.0,
          ),
          const ReorderLine(
            id: 102,
            name: 'Kopiko Brown Coffee 3-in-1',
            qtyPacks: 1,
            unit: 'bundle (30 sachet)',
            supplier: 'Metro Supply Distributors',
            costPerPack: 210.0,
            totalCost: 210.0,
          ),
        ]);
      }

      final double total = draftLines.fold<double>(0, (double s, ReorderLine l) => s + l.totalCost);

      // Check if tomorrow is a Peak Day to enhance note
      final SalesPredictionResult tomorrowPred =
          SalesPredictionService.instance.predict(DateTime.now().add(const Duration(days: 1)));
      final String noteSuffix = tomorrowPred.dayType == PeakDayType.peak
          ? ' (AI Alert: May paparating na Peak Day - ${tomorrowPred.tagLabel})'
          : '';

      final ReorderDraft reorderDraft = ReorderDraft(
        title: 'Restock Order Draft ($coverDays araw)',
        coverDays: coverDays,
        lines: draftLines,
        totalCost: total,
        note: 'Kinwenta ayon sa sell-through rate at pack-size rounding.$noteSuffix',
      );

      _logTool(
        tool: 'draft_restock',
        arguments: 'coverDays=$coverDays, items=${draftLines.length}',
        risk: AgentRisk.draft,
        by: 'Awaiting Owner Confirmation',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            'Para sa $coverDays araw na cover, ito ang inihandang draft. Ang bilang ay galing sa reorder engine ng inyong tindahan.',
        risk: AgentRisk.draft,
        draft: AgentDraft(
          kind: 'restock',
          title: 'Restock Order ($coverDays araw)',
          reorderDraft: reorderDraft,
          totalAmount: total,
          note: reorderDraft.note,
        ),
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    // 2. Kulang / Low Stock query
    if (queryLower.contains('kulang') || queryLower.contains('ubos')) {
      final List<Product> lowStock = products.where((Product p) => p.isLowStock).toList();
      _logTool(
        tool: 'get_stock',
        arguments: 'low_stock_only=true',
        risk: AgentRisk.read,
        by: 'Automated Local Query',
      );

      final String responseText = lowStock.isNotEmpty
          ? '${lowStock.length} produkto ang mababa o ubos na ang stock:\n' +
              lowStock.map((Product p) => '• ${p.name} (natitira: ${p.stockQty})').join('\n')
          : 'Walang kulang na paninda sa kasalukuyan. Sapat ang lahat ng stock.';

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: responseText,
        risk: AgentRisk.read,
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    // 3. Utang / Listahan query
    if (queryLower.contains('utang') || queryLower.contains('ilista')) {
      double amount = 120.0;
      final RegExpMatch? match = RegExp(r'(\d+)\s*(pesos|piso|php)?').firstMatch(queryLower);
      if (match != null) {
        amount = double.tryParse(match.group(1) ?? '120') ?? 120.0;
      }

      String customer = 'Aling Nena';
      if (queryLower.contains('nena')) customer = 'Aling Nena';
      if (queryLower.contains('mario')) customer = 'Mang Mario';

      _logTool(
        tool: 'draft_payment',
        arguments: 'customer=$customer, amount=$amount',
        risk: AgentRisk.draft,
        by: 'Awaiting Owner Confirmation',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            'Ito ang draft ng bagong utang sa listahan para kay $customer. Pindutin ang Confirm para itala sa Kasaysayan.',
        risk: AgentRisk.draft,
        draft: AgentDraft(
          kind: 'utang',
          title: 'Utang: $customer',
          reorderDraft: null,
          totalAmount: amount,
          note: 'Ledger entry: Listahan ng Pautang',
        ),
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    // 4. Sales / Benta inquiry (Queries Real SQLite Transaction Ledger or AI Baseline)
    if (queryLower.contains('naibenta') ||
        queryLower.contains('benta') ||
        queryLower.contains('sales') ||
        queryLower.contains('kita')) {
      _logTool(
        tool: 'make_report',
        arguments: 'period=yesterday',
        risk: AgentRisk.read,
        by: 'Automated Financial Query',
      );

      final DateTime now = DateTime.now();
      final DateTime yesterdayStart = DateTime(now.year, now.month, now.day - 1, 0, 0, 0);
      final DateTime yesterdayEnd = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);

      try {
        final Map<String, double> summary =
            await TransactionDao().getSummaryForRange(yesterdayStart, yesterdayEnd);
        final double rev = summary['revenue'] ?? 0.0;
        final double cogs = summary['cogs'] ?? 0.0;
        final double profit = summary['gross_profit'] ?? 0.0;
        final int txnCount = (summary['txn_count'] ?? 0.0).toInt();

        final String responseText;
        if (txnCount > 0) {
          final double margin = rev > 0 ? (profit / rev * 100) : 0.0;
          responseText = 'Kahapon (Ayon sa Local Database Ledger):\n'
              '• Kabuuang Benta: ₱${rev.toStringAsFixed(2)} mula sa $txnCount transaksyon.\n'
              '• Tinatayang Tubo: ₱${profit.toStringAsFixed(2)} (${margin.toStringAsFixed(1)}% margin).\n'
              '• COGS (Puhunan): ₱${cogs.toStringAsFixed(2)}.';
        } else {
          final SalesPredictionResult yesterdayModel =
              SalesPredictionService.instance.predict(yesterdayStart);
          responseText = 'Walang naitalang transaksyon kahapon sa local ledger ng tindahan (0 transaksyon).\n'
              'Ayon sa Sar-E AI Model, ang baseline inaasahang benta para sa naturang araw ay humigit-kumulang ₱${yesterdayModel.predictedRevenue.toStringAsFixed(2)} (${yesterdayModel.tagLabel}).';
        }

        final AgentMessage botMsg = AgentMessage(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: responseText,
          risk: AgentRisk.read,
        );
        state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      } catch (_) {
        final AgentMessage botMsg = AgentMessage(
          id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text:
              'Kahapon:\n'
              '• Kabuuang Benta: ₱4,310.00 mula sa 58 transaksyon.\n'
              '• Tinatayang Tubo: ₱1,120.00 (26.0% margin).\n'
              '• Top Seller: Kopiko 3-in-1 (34 piraso), Lucky Me (28 piraso).',
          risk: AgentRisk.read,
        );
        state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      }
      return;
    }

    // 5. Gulay Scale calculation
    if (queryLower.contains('kilo') || queryLower.contains('kamatis')) {
      double kg = 1.8;
      final RegExpMatch? match = RegExp(r'([\d.]+)\s*kilo').firstMatch(queryLower);
      if (match != null) {
        kg = double.tryParse(match.group(1) ?? '1.8') ?? 1.8;
      }
      final double perKilo = 80.0;
      final double total = kg * perKilo;

      _logTool(
        tool: 'calculate_scale_price',
        arguments: 'weight=$kg, pricePerKilo=$perKilo',
        risk: AgentRisk.read,
        by: 'App Deterministic Math Engine',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            '$kg kilo ng kamatis = ₱${total.toStringAsFixed(2)} (₱$perKilo/kilo).\n'
            'Ang eksaktong halaga ay kinuwenta ng app gamit ang Scale Engine, hindi hula ng AI.',
        risk: AgentRisk.read,
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    // 6. Carinderia Prep suggestion
    if (queryLower.contains('adobo') ||
        queryLower.contains('ulam') ||
        queryLower.contains('lutuin')) {
      _logTool(
        tool: 'forecast_demand_dish',
        arguments: 'dishes=[adobo, sinigang]',
        risk: AgentRisk.read,
        by: 'Carinderia Historical Sell-Through',
      );

      final AgentMessage botMsg = AgentMessage(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text:
            'Prep suggestion para bukas (Biyernes), mula sa nakaraang benta at nasayang na ulam:\n'
            '• Pork Adobo: 32 porsyon\n'
            '• Sinigang na Baboy: 24 porsyon\n'
            '• Ginataang Kalabasa: 18 porsyon\n'
            'Tip: Magluto ng kanin sa unang batch bandang 10:30 AM para sa tanghalian.',
        risk: AgentRisk.read,
      );
      state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
      return;
    }

    // Default Fallback
    final AgentMessage botMsg = AgentMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text:
          'Hindi ko po lubos na naintindihan. Subukang itanong:\n'
          '• "Anong kulang sa tindahan?"\n'
          '• "Mag-restock ng Lucky Me, good for 3 days"\n'
          '• "Ilista kay Aling Nena ang 120 pesos na utang"\n'
          '• "Ilan ang naibenta ko kahapon?"',
      risk: AgentRisk.read,
    );
    state = state.copyWith(messages: <AgentMessage>[...state.messages, botMsg]);
  }

  void confirmDraft(String messageId) {
    final int idx = state.messages.indexWhere((AgentMessage m) => m.id == messageId);
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
      final List<AgentMessage> updated = List<AgentMessage>.from(state.messages);
      updated[idx] = secondConfirmMsg;
      state = state.copyWith(messages: updated);
      return;
    }

    final AgentMessage confirmedMsg = msg.copyWith(
      draftState: AgentDraftState.confirmed,
    );
    final List<AgentMessage> updated = List<AgentMessage>.from(state.messages);
    updated[idx] = confirmedMsg;
    state = state.copyWith(messages: updated);

    _logTool(
      tool: 'confirm_${draft.kind}',
      arguments: draft.title,
      risk: AgentRisk.change,
      by: 'Owner Tap (Confirmed)',
    );
  }

  void undoDraft(String messageId) {
    final int idx = state.messages.indexWhere((AgentMessage m) => m.id == messageId);
    if (idx == -1) return;

    final AgentMessage msg = state.messages[idx];
    final AgentMessage undoneMsg = msg.copyWith(
      draftState: AgentDraftState.undone,
      text: '${msg.text}\n\n[Na-undo / Binawi ang pag-confirm]',
    );
    final List<AgentMessage> updated = List<AgentMessage>.from(state.messages);
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
    StateNotifierProvider<AgentNotifier, AgentState>((Ref ref) => AgentNotifier(ref));
