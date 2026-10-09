import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sare/application/agent_provider.dart';
import 'package:sare/domain/services/reorder_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('SARI v4: ReorderEngine Math & Pack Rounding', () {
    test('calculateNeeded returns correct pack rounding and total cost', () {
      // Current stock: 14 pcs, daily velocity: 18 pcs/day, cover days: 3
      // Target = 18 * 3 = 54 pcs. Deficit = 54 - 14 = 40 pcs.
      // Pack size: 24 pcs (box). Needed packs = ceil(40 / 24) = 2 boxes.
      // Cost per item = ₱12.50. Cost per pack = 12.50 * 24 = ₱300.00.
      // Total cost = 2 * 300 = ₱600.00.
      final ReorderLine? line = ReorderEngine.calculateNeeded(
        id: 1,
        name: 'Lucky Me Pancit Canton',
        currentStock: 14,
        dailyVelocity: 18.0,
        packSize: 24,
        unit: 'box',
        supplier: 'Metro Supply',
        costPerItem: 12.5,
        coverDays: 3,
      );

      expect(line, isNotNull);
      expect(line!.qtyPacks, 2);
      expect(line.costPerPack, 300.0);
      expect(line.totalCost, 600.0);
      expect(line.supplier, 'Metro Supply');
    });

    test('calculateNeeded returns null when stock is sufficient', () {
      final ReorderLine? line = ReorderEngine.calculateNeeded(
        id: 2,
        name: 'Kopiko 3-in-1',
        currentStock: 100,
        dailyVelocity: 10.0,
        packSize: 30,
        unit: 'pack',
        supplier: 'Metro Supply',
        costPerItem: 6.2,
        coverDays: 3,
      );

      expect(line, isNull);
    });

    test('ReorderDraft groups lines by supplier and formats shareable text', () {
      const ReorderLine l1 = ReorderLine(
        id: 1,
        name: 'Lucky Me Pancit Canton',
        qtyPacks: 2,
        unit: 'box',
        supplier: 'Metro Supply',
        costPerPack: 300.0,
        totalCost: 600.0,
      );
      const ReorderLine l2 = ReorderLine(
        id: 2,
        name: 'Coke Sakto',
        qtyPacks: 1,
        unit: 'case',
        supplier: 'Batangas Beverage',
        costPerPack: 288.0,
        totalCost: 288.0,
      );

      final ReorderDraft draft = ReorderDraft(
        title: 'Restock Order',
        coverDays: 3,
        lines: const <ReorderLine>[l1, l2],
        totalCost: 888.0,
      );

      expect(draft.suppliers, containsAll(<String>['Metro Supply', 'Batangas Beverage']));
      final String shareText = draft.toShareableText(storeName: 'Tindahan ni Aling Rosa');
      expect(shareText, contains('SARI RESTOCK ORDER'));
      expect(shareText, contains('Batangas Beverage'));
      expect(shareText, contains('Metro Supply'));
      expect(shareText, contains('₱888.00'));
    });
  });

  group('SARI v4: Agent Security Policy Gate & NLU Rules', () {
    test('Security Policy Gate blocks destructive operations', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AgentNotifier notifier = container.read(agentProvider.notifier);
      await notifier.submitQuery('burahin lahat ng history', isSeller: true);

      final AgentState state = container.read(agentProvider);
      final AgentMessage lastMsg = state.messages.last;

      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.risk, AgentRisk.blocked);
      expect(lastMsg.text, contains('Settings > Privacy and data'));
      expect(state.activityLogs.first.risk, AgentRisk.blocked);
    });

    test('Restock query triggers draft with reorder lines', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AgentNotifier notifier = container.read(agentProvider.notifier);
      await notifier.submitQuery('Mag-restock ng Lucky Me at kape, good for 3 days', isSeller: true);

      final AgentState state = container.read(agentProvider);
      final AgentMessage lastMsg = state.messages.last;

      expect(lastMsg.isUser, isFalse);
      expect(lastMsg.risk, AgentRisk.draft);
      expect(lastMsg.draft, isNotNull);
      expect(lastMsg.draft!.reorderDraft, isNotNull);
      expect(lastMsg.draftState, AgentDraftState.open);
    });

    test('Double confirmation required when total exceeds threshold', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AgentNotifier notifier = container.read(agentProvider.notifier);
      await notifier.submitQuery('Mag-restock ng Lucky Me at kape, good for 3 days', isSeller: true);

      final AgentState state = container.read(agentProvider);
      final AgentMessage draftMsg = state.messages.last;
      expect(draftMsg.draft!.totalAmount, greaterThan(state.doubleConfirmThreshold));

      // First tap on confirm should request second confirmation
      notifier.confirmDraft(draftMsg.id);

      final AgentState afterFirstTap = container.read(agentProvider);
      final AgentMessage updatedMsg = afterFirstTap.messages.firstWhere((AgentMessage m) => m.id == draftMsg.id);
      expect(updatedMsg.draftState, AgentDraftState.secondConfirm);

      // Second tap confirms the draft
      notifier.confirmDraft(draftMsg.id);
      final AgentState afterSecondTap = container.read(agentProvider);
      final AgentMessage confirmedMsg = afterSecondTap.messages.firstWhere((AgentMessage m) => m.id == draftMsg.id);
      expect(confirmedMsg.draftState, AgentDraftState.confirmed);
    });

    test('Undo reverses draft confirmation', () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      final AgentNotifier notifier = container.read(agentProvider.notifier);
      await notifier.submitQuery('Ilista kay Aling Nena ang 120 pesos na utang', isSeller: true);

      final AgentState state = container.read(agentProvider);
      final AgentMessage draftMsg = state.messages.last;

      notifier.confirmDraft(draftMsg.id);
      expect(container.read(agentProvider).messages.last.draftState, AgentDraftState.confirmed);

      // Tap undo
      notifier.undoDraft(draftMsg.id);
      expect(container.read(agentProvider).messages.last.draftState, AgentDraftState.undone);
    });
  });
}
