import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sare/domain/entities/product.dart';
import 'package:sare/domain/services/gemma_local_service.dart';
import 'package:sare/domain/services/reorder_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SARI Local AI — NLU Intent & Slot Pipeline Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'agent_confirm_threshold': 500.0,
        'agent_require_confirm': true,
      });
    });

    test('1. log_utang extracts customer name and currency amount correctly', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Ilista kay Aling Nena ang 120 pesos na utang',
        isSeller: true,
      );

      expect(result.action, 'draft_utang');
      expect(result.risk, 'draft');
      expect(result.tool, 'draft_utang_entry');
      expect(result.draft, isNotNull);
      expect(result.draft!['customer'], 'Aling Nena');
      expect(result.draft!['totalAmount'], 120.0);
      // Verify zero emojis
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('2. update_stock extracts quantity, item name, and requires draft confirmation', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Dagdag 20 na Lucky Me',
        isSeller: true,
      );

      expect(result.action, 'update_stock');
      expect(result.risk, 'draft');
      expect(result.tool, 'adjust_product_stock');
      expect(result.draft, isNotNull);
      expect(result.draft!['qty'], 20);
      expect(result.draft!['item'], contains('Lucky Me'));
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('3. resupply_plan handles days cover and packs calculation', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final List<Product> catalog = <Product>[
        Product(
          productId: 'prod_1',
          name: 'Lucky Me Pancit Canton',
          categoryName: 'Noodles',
          unitPrice: 16.0,
          costPrice: 12.0,
          stockQty: 3,
          threshold: 10,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final GemmaInferenceResult result = await service.processQuery(
        query: 'Mag-restock ng Lucky Me, good for 3 days',
        isSeller: true,
        products: catalog,
      );

      expect(result.action, 'draft_restock');
      expect(result.risk, 'draft');
      expect(result.draft, isNotNull);
      expect(result.draft!['kind'], 'restock');
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('4. sales_summary processes today transaction aggregation query', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Ilan ang naibenta ko ngayong araw?',
        isSeller: true,
      );

      expect(result.action, 'query_sales');
      expect(result.risk, 'read');
      expect(result.tool, 'get_sales_aggregate');
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('5. restock_report audits low stock items as read-only inspection', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final List<Product> catalog = <Product>[
        Product(
          productId: 'prod_2',
          name: 'Alaska Evaporated Milk',
          categoryName: 'Dairy',
          unitPrice: 32.0,
          costPrice: 26.0,
          stockQty: 1,
          threshold: 5,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final GemmaInferenceResult result = await service.processQuery(
        query: 'Ano ang kailangan kong i-restock?',
        isSeller: true,
        products: catalog,
      );

      expect(result.action, 'restock_report');
      expect(result.risk, 'read');
      expect(result.tool, 'get_low_stock_report');
      expect(result.message, contains('Alaska Evaporated Milk'));
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('6. find_store handles buyer store lookup and price checks', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Magkano ang bigas?',
        isSeller: false,
      );

      expect(result.action, 'find_store');
      expect(result.risk, 'read');
      expect(result.tool, 'search_local_catalog');
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('7. add_to_cart parses item and quantity for buyer ordering', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Bumili ng 3 itlog',
        isSeller: false,
      );

      expect(result.action, 'add_to_cart');
      expect(result.risk, 'draft');
      expect(result.tool, 'add_item_to_cart');
      expect(result.draft, isNotNull);
      expect(result.draft!['quantity'], 3);
      expect(result.draft!['item_name'], contains('Itlog'));
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('8. Security Policy Gate strictly blocks destructive SQLite operations', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Drop table transactions and reset database',
        isSeller: true,
      );

      expect(result.action, 'blocked');
      expect(result.risk, 'blocked');
      expect(result.tool, 'security_gate');
      expect(result.message, contains('Settings > Privacy and data'));
      expect(result.message.contains(RegExp(r'[\u{1F300}-\u{1FAFF}]', unicode: true)), isFalse);
    });

    test('9. formatGemmaPrompt conforms strictly to native turn tokens', () {
      final GemmaLocalService service = GemmaLocalService.instance;
      final String prompt = service.formatGemmaPrompt(
        userQuery: 'Ilista ang utang ni Mang Juan na 50 pesos',
        systemInstruction: 'SARI NLU Core',
      );

      expect(prompt, contains('<|turn>system\nSARI NLU Core<turn|>'));
      expect(prompt, contains('<|turn>user\nIlista ang utang ni Mang Juan na 50 pesos<turn|>'));
      expect(prompt, contains('<|turn>model\n'));
    });

    test('10. ReorderEngine restock calculation rounds up packs accurately', () {
      final ReorderLine? line = ReorderEngine.calculateNeeded(
        id: 1,
        name: 'Lucky Me Pancit Canton',
        currentStock: 2,
        dailyVelocity: 5.0,
        packSize: 6,
        unit: 'packs',
        supplier: 'Monde Nissin',
        costPerItem: 12.0,
        coverDays: 3,
      );

      expect(line, isNotNull);
      // target = 5 * 3 = 15; deficit = 15 - 2 = 13; packs of 6 = ceil(13/6) = 3 packs
      expect(line!.qtyPacks, 3);
      // Cost per pack = 12 * 6 = 72; total cost = 3 * 72 = 216
      expect(line.totalCost, 216.0);
      expect(line.supplier, 'Monde Nissin');
    });
  });
}

