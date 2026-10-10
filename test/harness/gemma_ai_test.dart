import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sare/application/agent_provider.dart';
import 'package:sare/domain/services/gemma_local_service.dart';
import 'package:sare/domain/entities/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sar-E Local AI: Gemma 4 E2B Service Suite', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'agent_confirm_threshold': 500.0,
        'agent_require_confirm': true,
      });
    });

    test('GemmaLocalService returns correct DeepMind Gemma 4 architecture metadata', () {
      final GemmaLocalService service = GemmaLocalService.instance;
      expect(service.modelName, 'Gemma 4 E2B');
      expect(service.architecture, 'Gemma4ForConditionalGeneration');
      expect(service.contextWindowTokens, 131072); // 128K context
      expect(service.weightsPath, contains('gemma-4-transformers-gemma-4-e2b-v1'));
    });

    test('formatGemmaPrompt uses native Gemma 4 turn tokens', () {
      final GemmaLocalService service = GemmaLocalService.instance;
      final String prompt = service.formatGemmaPrompt(
        userQuery: 'Mag-restock ng kape para sa 3 araw',
        systemInstruction: 'Sar-E Store Assistant',
      );

      expect(prompt, contains('<|turn>system\nSar-E Store Assistant<turn|>'));
      expect(prompt, contains('<|turn>user\nMag-restock ng kape para sa 3 araw<turn|>'));
      expect(prompt, contains('<|turn>model\n'));
    });

    test('processQuery blocks malicious administrative queries under security policy gate', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Burahin ang lahat ng transaksyon sa database',
        isSeller: true,
      );

      expect(result.action, 'blocked');
      expect(result.risk, 'blocked');
      expect(result.tool, 'security_gate');
      expect(result.message, contains('Settings > Privacy and data'));
    });

    test('processQuery creates restock draft with pack size rounding', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final List<Product> mockCatalog = <Product>[
        Product(
          productId: '101',
          name: 'Lucky Me Pancit Canton Kalamansi',
          categoryName: 'Snacks',
          unitPrice: 18.0,
          costPrice: 13.0,
          stockQty: 5,
          threshold: 10,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final GemmaInferenceResult result = await service.processQuery(
        query: 'Mag-restock ng 2 kahon ng canton para sa 3 araw',
        isSeller: true,
        products: mockCatalog,
      );

      expect(result.action, 'draft_restock');
      expect(result.risk, 'draft');
      expect(result.draft, isNotNull);
      expect(result.draft?['kind'], 'restock');
      expect(result.draft?['totalAmount'], greaterThan(0));
    });

    test('processQuery creates utang draft with customer and amount', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Ilista ang utang ni Aling Marites na ₱250',
        isSeller: true,
      );

      expect(result.action, 'draft_utang');
      expect(result.risk, 'draft');
      expect(result.draft?['customer'], 'Aling Marites');
      expect(result.draft?['totalAmount'], 250.0);
    });

    test('processQuery triggers sales forecasting on peak/benta query', () async {
      final GemmaLocalService service = GemmaLocalService.instance;
      final GemmaInferenceResult result = await service.processQuery(
        query: 'Hulaan ang benta para bukas',
        isSeller: true,
      );

      expect(result.action, 'forecast_sales');
      expect(result.risk, 'read');
      expect(result.tool, 'predict_sales_tomorrow');
    });

    test('AgentNotifier initializes with Gemma 4 E2B model active', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AgentState state = container.read(agentProvider);
      expect(state.modelReady, isTrue);
      expect(state.modelStatus, contains('Gemma 4 E2B'));
    });
  });
}
