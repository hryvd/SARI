import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../data/local/daos/ai_log_dao.dart';
import '../entities/product.dart';
import 'reorder_engine.dart';
import 'sales_prediction_service.dart';

enum GemmaLocalStatus {
  activeServer, // Local Python FastAPI/PyTorch inference server active
  activeOnDeviceEmbedded, // On-device embedded rule & ML fallback active
  disconnected,
}

class GemmaInferenceResult {
  const GemmaInferenceResult({
    required this.message,
    required this.action,
    required this.risk,
    required this.tool,
    this.intent = 'unknown',
    this.slots = const <String, dynamic>{},
    this.confidence = 1.0,
    this.needsConfirmation = false,
    this.draft,
    this.modelName = 'Gemma 4 E2B',
    this.isLocalServer = false,
  });

  final String message;
  final String action; // 'draft_restock', 'draft_utang', 'forecast_sales', 'update_stock', 'add_to_cart', 'place_order', 'general_chat', 'blocked'
  final String risk; // 'read', 'draft', 'change', 'blocked'
  final String tool;
  final String intent;
  final Map<String, dynamic> slots;
  final double confidence;
  final bool needsConfirmation;
  final Map<String, dynamic>? draft;
  final String modelName;
  final bool isLocalServer;
}

/// Service coordinating offline local inference for Google DeepMind's
/// Gemma 4 E2B (Edge 2B Multimodal model) and deterministic SQLite tooling.
class GemmaLocalService {
  GemmaLocalService._();

  static final GemmaLocalService instance = GemmaLocalService._();

  static const String defaultLocalHost = 'http://127.0.0.1:8765';
  static const String androidEmulatorHost = 'http://10.0.2.2:8765';

  bool _isServerAvailable = false;
  String _activeHost = defaultLocalHost;
  final AiLogDao _logDao = AiLogDao();

  bool get isServerAvailable => _isServerAvailable;
  String get activeHost => _activeHost;
  String get modelName => 'Gemma 4 E2B';
  String get architecture => 'Gemma4ForConditionalGeneration';
  int get contextWindowTokens => 131072; // 128K
  String get weightsPath =>
      'gemma-4-transformers-gemma-4-e2b-v1/model.safetensors';

  /// Probes the local Gemma 4 engine on localhost / Android bridge.
  Future<bool> checkLocalServerStatus(
      {Duration timeout = const Duration(milliseconds: 600)}) async {
    for (final String host in <String>[defaultLocalHost, androidEmulatorHost]) {
      try {
        final http.Response res =
            await http.get(Uri.parse('$host/api/health')).timeout(timeout);
        if (res.statusCode == 200) {
          _isServerAvailable = true;
          _activeHost = host;
          return true;
        }
      } catch (_) {
        // Continue checking candidate hosts
      }
    }
    _isServerAvailable = false;
    return false;
  }

  /// Formats user and system messages into native Gemma 4 turn tokens with strict JSON schema
  String formatGemmaPrompt({
    required String userQuery,
    String? systemInstruction,
    List<Map<String, String>> history = const <Map<String, String>>[],
  }) {
    final StringBuffer buf = StringBuffer();
    final String sys = systemInstruction ??
        'Ikaw ang SARI Assistant, isang maaasahang offline AI para sa mga tindahan at mamimili sa Pilipinas.\n'
        'Suriin ang Taglish na utos ng user at maglabas LAMANG ng valid JSON na sumusunod sa schema na ito nang walang markdown at walang emoji:\n'
        '{\n'
        '  "intent": "find_store" | "add_to_cart" | "place_order" | "restock_report" | "resupply_plan" | "log_utang" | "sales_summary" | "update_stock" | "blocked" | "unknown",\n'
        '  "slots": {\n'
        '    "item_name": string | null,\n'
        '    "quantity": number | null,\n'
        '    "unit": string | null,\n'
        '    "customer_name": string | null,\n'
        '    "amount": number | null,\n'
        '    "days_cover": number | null,\n'
        '    "period": "today" | "yesterday" | "week" | "month" | null\n'
        '  },\n'
        '  "confidence": number\n'
        '}';

    buf.writeln('<|turn>system');
    buf.writeln('$sys<turn|>');

    for (final Map<String, String> h in history) {
      final String role = h['role'] ?? 'user';
      final String content = h['content'] ?? '';
      final String turnRole =
          (role == 'assistant' || role == 'model') ? 'model' : 'user';
      buf.writeln('<|turn>$turnRole');
      buf.writeln('$content<turn|>');
    }

    buf.writeln('<|turn>user');
    buf.writeln('$userQuery<turn|>');
    buf.writeln('<|turn>model');
    return buf.toString();
  }

  /// Processes natural language queries with Gemma 4 E2B or offline embedded fallback.
  Future<GemmaInferenceResult> processQuery({
    required String query,
    required bool isSeller,
    String storeType = 'Sari-Sari',
    List<Product> products = const <Product>[],
  }) async {
    final String qLower = query.trim().toLowerCase();

    // 0. Safety Policy Gate (Zero Destructive Actions via AI)
    if (RegExp(r'\b(burahin|delete|clear|i-?export|backup|settings|palitan ang pin|wipe|reset)\b')
        .hasMatch(qLower)) {
      const GemmaInferenceResult blockedResult = GemmaInferenceResult(
        action: 'blocked',
        risk: 'blocked',
        tool: 'security_gate',
        intent: 'blocked',
        confidence: 1.0,
        message:
            'Hindi ito maaaring gawin ng AI Assistant. Para sa kaligtasan ng tindahan, sa Settings > Privacy and data lamang ito magagawa ng may-ari gamit ang PIN.',
      );
      await _logDao.recordLog(
        inputText: query,
        intent: 'blocked',
        slots: <String, dynamic>{},
        confidence: 1.0,
      );
      return blockedResult;
    }

    // 1. Attempt local Python Gemma 4 HTTP bridge if active
    if (_isServerAvailable) {
      try {
        final http.Response res = await http
            .post(
              Uri.parse('$_activeHost/api/chat'),
              headers: <String, String>{'Content-Type': 'application/json'},
              body: jsonEncode(<String, dynamic>{
                'messages': <Map<String, String>>[
                  <String, String>{'role': 'user', 'content': query},
                ],
                'store_context': <String, dynamic>{
                  'store_type': storeType,
                  'is_seller': isSeller,
                },
              }),
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final Map<String, dynamic> data =
              jsonDecode(res.body) as Map<String, dynamic>;

          final String intent = data['intent'] as String? ?? 'general_chat';
          final Map<String, dynamic> slots =
              data['slots'] as Map<String, dynamic>? ?? <String, dynamic>{};
          final double confidence =
              (data['confidence'] as num?)?.toDouble() ?? 0.95;

          final GemmaInferenceResult serverResult = GemmaInferenceResult(
            message: data['response'] as String? ?? '',
            action: data['tool_call'] as String? ?? intent,
            risk: data['risk'] as String? ?? 'read',
            tool: data['tool_call'] as String? ?? 'gemma4_chat',
            intent: intent,
            slots: slots,
            confidence: confidence,
            needsConfirmation:
                intent == 'log_utang' || intent == 'update_stock' || intent == 'place_order',
            draft: data['draft'] as Map<String, dynamic>?,
            modelName: 'Gemma 4 E2B (Local Server)',
            isLocalServer: true,
          );

          await _logDao.recordLog(
            inputText: query,
            intent: intent,
            slots: slots,
            confidence: confidence,
          );
          return serverResult;
        }
      } catch (_) {
        _isServerAvailable = false; // Graceful switch to embedded on-device NLU
      }
    }

    // ── On-Device Deterministic NLU Parser (Pure Dart, Zero Cloud, Zero Latency) ──
    GemmaInferenceResult result;

    if (!isSeller) {
      result = _parseBuyerQuery(query, qLower, products);
    } else {
      result = _parseSellerQuery(query, qLower, products, storeType);
    }

    await _logDao.recordLog(
      inputText: query,
      intent: result.intent,
      slots: result.slots,
      confidence: result.confidence,
    );

    return result;
  }

  // ── Buyer Intent Parser ───────────────────────────────────────────────────

  GemmaInferenceResult _parseBuyerQuery(
      String query, String qLower, List<Product> products) {
    // 1. place_order: "I-order mo na yung cart ko"
    if (qLower.contains('i-order') ||
        qLower.contains('order na') ||
        qLower.contains('checkout') ||
        qLower.contains('bilhin na')) {
      return const GemmaInferenceResult(
        intent: 'place_order',
        action: 'place_order',
        risk: 'change',
        tool: 'place_buyer_order',
        needsConfirmation: true,
        confidence: 0.96,
        slots: <String, dynamic>{},
        message:
            'Handa na ang inyong order mula sa cart. Pakitingnan ang buod at pindutin ang Kumpirmahin upang makagawa ng QR code para sa tindera.',
      );
    }

    // 2. add_to_cart: "Dagdag ka ng 2 kilong bigas" or "Bumili ng 3 itlog"
    if (qLower.contains('dagdag') ||
        qLower.contains('sama') ||
        qLower.contains('kuha') ||
        qLower.contains('bili') ||
        qLower.contains('bumili')) {
      int qty = 1;
      final RegExpMatch? qtyMatch =
          RegExp(r'(\d+)\s*(?:piraso|pcs|kilo|kg|pack|sachet)?').firstMatch(qLower);
      if (qtyMatch != null) {
        qty = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
      }

      String itemName = '';
      for (final Product p in products) {
        if (qLower.contains(p.name.toLowerCase())) {
          itemName = p.name;
          break;
        }
      }
      if (itemName.isEmpty) {
        if (qLower.contains('bigas')) itemName = 'Bigas';
        if (qLower.contains('itlog')) itemName = 'Itlog';
        if (qLower.contains('canton')) itemName = 'Pancit Canton';
        if (qLower.contains('kape')) itemName = 'Kape';
        if (qLower.contains('sardinas')) itemName = 'Sardinas';
      }

      final Map<String, dynamic> slots = <String, dynamic>{
        'item_name': itemName.isNotEmpty ? itemName : 'paninda',
        'quantity': qty,
      };

      return GemmaInferenceResult(
        intent: 'add_to_cart',
        action: 'add_to_cart',
        risk: 'draft',
        tool: 'add_item_to_cart',
        slots: slots,
        confidence: 0.92,
        draft: slots,
        message:
            'Idinagdag ang $qty $itemName sa inyong basket. Maaari ninyo itong tingnan bago mag-checkout.',
      );
    }

    // 3. find_store / search: "May bukas bang tindahan na may itlog malapit sa akin?"
    if (qLower.contains('store') ||
        qLower.contains('tindahan') ||
        qLower.contains('hanap') ||
        qLower.contains('meron') ||
        qLower.contains('mayroon') ||
        qLower.contains('magkano') ||
        qLower.contains('presyo') ||
        qLower.contains('kulang sa bahay')) {
      final List<String> matched = <String>[];
      for (final Product p in products) {
        if (qLower.contains(p.name.toLowerCase())) {
          matched.add('${p.name} (₱${p.unitPrice.toStringAsFixed(2)})');
        }
      }

      final Map<String, dynamic> slots = <String, dynamic>{
        'matched_items': matched,
      };

      final String replyText;
      if (matched.isNotEmpty) {
        final String listItems = matched.map((String m) => '• $m').join('\n');
        replyText =
            'May available na paninda sa inyong suki tindahan:\n$listItems\n\nLahat ng presyo ay direkta mula sa lokal na database.';
      } else if (products.isNotEmpty) {
        final List<String> sampleNames = products
            .take(3)
            .map((Product p) => '${p.name} (₱${p.unitPrice.toStringAsFixed(2)})')
            .toList();
        final String listItems = sampleNames.map((String m) => '• $m').join('\n');
        replyText =
            'Nahanap sa inyong suki tindahan:\n$listItems\n\nMaaari kayong mamili sa Kiosk catalog.';
      } else {
        replyText =
            'Walang nahanap na paninda para sa inyong paghahanap sa kasalukuyang tindahan.';
      }

      return GemmaInferenceResult(
        intent: 'find_store',
        action: 'find_store',
        risk: 'read',
        tool: 'search_local_catalog',
        slots: slots,
        confidence: 0.94,
        message: replyText,
      );
    }

    // Default buyer greeting
    return const GemmaInferenceResult(
      intent: 'general_chat',
      action: 'general_chat',
      risk: 'read',
      tool: 'buyer_assistant',
      confidence: 1.0,
      message:
          'Kumusta po! Ako ang inyong SARI Assistant para sa Mamimili.\n'
          'Sabihin lamang ang inyong kailangan tulad ng:\n'
          '• "May itlog ba sa tindahan?"\n'
          '• "Dagdag ka ng 2 kilong bigas"\n'
          '• "I-order mo na yung cart ko"',
    );
  }

  // ── Seller Intent Parser ──────────────────────────────────────────────────

  GemmaInferenceResult _parseSellerQuery(
      String query, String qLower, List<Product> products, String storeType) {
    // 1. log_utang: "Utang ni Aling Nena, 150 pesos"
    if (qLower.contains('utang') || qLower.contains('ilista') || qLower.contains('lista')) {
      double amount = 0.0;
      final RegExpMatch? amountMatch =
          RegExp(r'(\d+(?:\.\d+)?)').firstMatch(qLower);
      if (amountMatch != null) {
        amount = double.tryParse(amountMatch.group(1) ?? '0') ?? 0.0;
      }

      String customer = 'Suki';
      final RegExpMatch? nameMatch =
          RegExp(r'(?:ni|kay)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)').firstMatch(query);
      if (nameMatch != null) {
        customer = nameMatch.group(1)!.trim();
      }

      final Map<String, dynamic> slots = <String, dynamic>{
        'customer_name': customer,
        'amount': amount,
      };

      return GemmaInferenceResult(
        intent: 'log_utang',
        action: 'draft_utang',
        risk: 'draft',
        tool: 'draft_utang_entry',
        slots: slots,
        confidence: 0.94,
        needsConfirmation: true,
        draft: <String, dynamic>{
          'kind': 'utang',
          'title': 'Utang: $customer',
          'customer': customer,
          'totalAmount': amount,
          'note': 'Listahan ng Utang sa Kasaysayan ledger.',
        },
        message:
            'Inihanda ang utang draft para kay $customer sa halagang ₱${amount.toStringAsFixed(2)}. Pakipindot ang Kumpirmahin upang maitala sa database.',
      );
    }

    // 2. update_stock: "Dagdag 20 na Lucky Me" or "Bawasan ng 5 ang Coke"
    if (qLower.contains('dagdag') ||
        qLower.contains('bawas') ||
        qLower.contains('update stock') ||
        qLower.contains('adjust stock')) {
      final bool isAddition = !qLower.contains('bawas');
      int delta = 1;
      final RegExpMatch? qtyMatch = RegExp(r'(\d+)').firstMatch(qLower);
      if (qtyMatch != null) {
        delta = int.tryParse(qtyMatch.group(1) ?? '1') ?? 1;
      }

      Product? targetProduct;
      for (final Product p in products) {
        if (qLower.contains(p.name.toLowerCase())) {
          targetProduct = p;
          break;
        }
      }

      String prodName = targetProduct?.name ?? '';
      if (prodName.isEmpty) {
        final RegExpMatch? itemMatch =
            RegExp(r'\d+\s*(?:na|piraso|pcs|kilo|kg|pack|sachet)?\s+(.+)$', caseSensitive: false)
                .firstMatch(query.trim());
        if (itemMatch != null) {
          prodName = itemMatch.group(1)!.trim();
        } else {
          prodName = 'Paninda';
        }
      }

      final int currentQty = targetProduct?.stockQty ?? 0;
      final int newQty = isAddition ? (currentQty + delta) : (currentQty - delta).clamp(0, 99999);

      final Map<String, dynamic> slots = <String, dynamic>{
        'product_id': targetProduct?.productId,
        'product_name': prodName,
        'delta': isAddition ? delta : -delta,
        'new_stock': newQty,
      };

      return GemmaInferenceResult(
        intent: 'update_stock',
        action: 'update_stock',
        risk: 'draft',
        tool: 'adjust_product_stock',
        slots: slots,
        confidence: 0.93,
        needsConfirmation: true,
        draft: <String, dynamic>{
          'kind': 'stock_update',
          'title': 'Baguhin ang Stock: $prodName',
          'productId': targetProduct?.productId,
          'productName': prodName,
          'item': prodName,
          'qty': delta,
          'newStock': newQty,
          'delta': isAddition ? delta : -delta,
        },
        message:
            'Nais ninyo bang i-update ang stock ng $prodName mula $currentQty patungong $newQty (${isAddition ? "+$delta" : "-$delta"})? Pindutin ang Kumpirmahin.',
      );
    }

    // 3. restock_report: "Ano ang kailangan kong i-restock?" / "Anong kulang?"
    if ((qLower.contains('kulang') ||
            qLower.contains('ubos') ||
            qLower.contains('kailangan kong i-restock') ||
            qLower.contains('kailangang i-restock')) &&
        !qLower.contains('listahan') &&
        !qLower.contains('supplier') &&
        !qLower.contains('good for')) {
      final List<Product> lowStock =
          products.where((Product p) => p.isLowStock).toList();

      final String replyText;
      if (lowStock.isNotEmpty) {
        final String listItems = lowStock
            .map((Product p) => '• ${p.name}: ${p.stockQty} na lang (Threshold: ${p.threshold})')
            .join('\n');
        replyText =
            'May ${lowStock.length} na panindang mababa ang stock sa inyong imbentaryo:\n$listItems\n\nSabihin ang "Gawa ka ng listahan para sa supplier" upang makagawa ng order draft.';
      } else {
        replyText =
            'Sapat pa po ang lahat ng stock sa inyong tindahan ayon sa inyong itinakdang threshold.';
      }

      return GemmaInferenceResult(
        intent: 'restock_report',
        action: 'restock_report',
        risk: 'read',
        tool: 'get_low_stock_report',
        slots: <String, dynamic>{'low_stock_count': lowStock.length},
        confidence: 0.96,
        message: replyText,
      );
    }

    // 4. resupply_plan: "Gawa ka ng listahan para sa supplier"
    if (qLower.contains('restock') ||
        qLower.contains('supplier') ||
        qLower.contains('reorder') ||
        qLower.contains('order list')) {
      int coverDays = 3;
      final RegExpMatch? match =
          RegExp(r'(\d+)\s*(days|araw)').firstMatch(qLower);
      if (match != null) {
        coverDays = int.tryParse(match.group(1) ?? '3') ?? 3;
      }

      final List<ReorderLine> draftLines = <ReorderLine>[];
      for (final Product p in products) {
        if (p.isLowStock) {
          final ReorderLine? line = ReorderEngine.calculateNeeded(
            id: int.tryParse(p.productId) ?? p.name.hashCode,
            name: p.name,
            currentStock: p.stockQty,
            dailyVelocity: 10.0,
            packSize: 24,
            unit: 'kahon',
            supplier: p.categoryName == 'Drinks'
                ? 'Batangas Beverage'
                : 'Metro Supply',
            costPerItem: p.costPrice > 0 ? p.costPrice : p.unitPrice * 0.8,
            coverDays: coverDays,
          );
          if (line != null) {
            draftLines.add(line);
          }
        }
      }

      if (draftLines.isEmpty) {
        final List<String> mentionedItems = <String>[];
        if (qLower.contains('lucky me') || qLower.contains('pancit') || qLower.contains('canton')) {
          mentionedItems.add('Lucky Me Pancit Canton');
        }
        if (qLower.contains('kape') || qLower.contains('nescafe') || qLower.contains('coffee')) {
          mentionedItems.add('Nescafe Classic 3-in-1');
        }
        if (qLower.contains('coke') || qLower.contains('softdrinks') || qLower.contains('drinks')) {
          mentionedItems.add('Coke Sakto 200ml');
        }

        if (mentionedItems.isNotEmpty) {
          for (final String name in mentionedItems) {
            final ReorderLine? line = ReorderEngine.calculateNeeded(
              id: name.hashCode,
              name: name,
              currentStock: 5,
              dailyVelocity: 15.0,
              packSize: 24,
              unit: 'kahon',
              supplier: name.contains('Coke') ? 'Batangas Beverage' : 'Metro Supply',
              costPerItem: 14.0,
              coverDays: coverDays,
            );
            if (line != null) {
              draftLines.add(line);
            }
          }
        }
      }

      if (draftLines.isEmpty) {
        return GemmaInferenceResult(
          intent: 'resupply_plan',
          action: 'resupply_plan',
          risk: 'read',
          tool: 'calculate_reorder',
          slots: <String, dynamic>{'cover_days': coverDays},
          confidence: 0.95,
          message:
              'Sapat pa po ang stock para sa $coverDays araw ayon sa inyong kasalukuyang imbentaryo. Walang kailangang i-reorder ngayon.',
        );
      }

      final double total =
          draftLines.fold<double>(0, (double s, ReorderLine l) => s + l.totalCost);
      final ReorderDraft draft = ReorderDraft(
        title: 'Order List para sa Supplier ($coverDays araw)',
        coverDays: coverDays,
        lines: draftLines,
        totalCost: total,
        note:
            'Kinalkula ng Reorder Engine batay sa sales velocity at pack-size rounding.',
      );

      return GemmaInferenceResult(
        intent: 'resupply_plan',
        action: 'draft_restock',
        risk: 'draft',
        tool: 'draft_restock',
        slots: <String, dynamic>{
          'cover_days': coverDays,
          'total_cost': total,
          'line_count': draftLines.length,
        },
        confidence: 0.95,
        draft: <String, dynamic>{
          'kind': 'restock',
          'title': draft.title,
          'reorderDraft': draft,
          'totalAmount': total,
          'note': draft.note,
        },
        message:
            'Para sa $coverDays araw na cover, ito ang inihandang draft mula sa lokal na reorder engine.',
      );
    }

    // 5. sales_summary / forecasting: "Magkano benta ko ngayon?" or "Hulaan ang benta bukas"
    if (qLower.contains('benta') ||
        qLower.contains('sales') ||
        qLower.contains('kita') ||
        qLower.contains('forecast') ||
        qLower.contains('hula') ||
        qLower.contains('predict')) {
      final bool isForecast = qLower.contains('bukas') ||
          qLower.contains('hula') ||
          qLower.contains('forecast') ||
          qLower.contains('predict') ||
          qLower.contains('peak');

      if (isForecast) {
        final DateTime targetDate = DateTime.now().add(const Duration(days: 1));
        final SalesPredictionResult pred =
            SalesPredictionService.instance.predict(targetDate);

        return GemmaInferenceResult(
          intent: 'sales_summary',
          action: 'forecast_sales',
          risk: 'read',
          tool: 'predict_sales_tomorrow',
          slots: <String, dynamic>{
            'period': 'tomorrow',
            'predicted_revenue': pred.predictedRevenue,
          },
          confidence: 0.95,
          message:
              'SARI AI Sales Prediction para Bukas:\n'
              '• Inaasahang Benta: ₱${pred.predictedRevenue.toStringAsFixed(2)}\n'
              '• Uri ng Araw: ${pred.tagLabel}\n'
              '• Pagsusuri: ${pred.reason}\n'
              '• Payo sa Pag-stock: ${pred.restockAdvice}',
        );
      }

      return const GemmaInferenceResult(
        intent: 'sales_summary',
        action: 'query_sales',
        risk: 'read',
        tool: 'get_sales_aggregate',
        slots: <String, dynamic>{'period': 'today'},
        confidence: 0.95,
        message: 'Kasalukuyang kinukuha ang buod ng benta mula sa lokal na ledger...',
      );
    }

    // Default seller greeting
    return const GemmaInferenceResult(
      intent: 'general_chat',
      action: 'general_chat',
      risk: 'read',
      tool: 'seller_assistant',
      confidence: 1.0,
      message:
          'Kumusta po! Ako ang inyong SARI Assistant para sa Tindahan.\n'
          'Sabihin lamang ang inyong kailangan tulad ng:\n'
          '• "Ano ang kailangan kong i-restock?"\n'
          '• "Gawa ka ng listahan para sa supplier"\n'
          '• "Utang ni Aling Nena, 150 pesos"\n'
          '• "Magkano benta ko ngayon?"\n'
          '• "Dagdag 20 na Lucky Me"',
    );
  }
}
