import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/agent_provider.dart';
import '../../application/auth_provider.dart';
import '../../domain/services/reorder_engine.dart';
import '../../theme/app_theme.dart';

class AiAgentScreen extends ConsumerStatefulWidget {
  const AiAgentScreen({super.key});

  @override
  ConsumerState<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends ConsumerState<AiAgentScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submitText(String text, bool isSeller) {
    if (text.trim().isEmpty) return;
    ref.read(agentProvider.notifier).submitQuery(text, isSeller: isSeller);
    _textCtrl.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AgentState agentState = ref.watch(agentProvider);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final bool isSeller = auth.user?.role != 'buyer';

    final List<String> chips = isSeller
        ? <String>[
            'Hulaan ang benta bukas',
            '7-Araw na Sales Forecast',
            'Kailan ang susunod na Peak Day?',
            'Ano ang kailangan kong i-restock?',
            'Mag-restock ng Lucky Me, good for 3 days',
            'Ilan ang naibenta ko ngayong araw?',
            'Ilista kay Aling Nena ang 120 pesos na utang',
            'Dagdag 20 na Lucky Me',
          ]
        : <String>[
            'Kulang sa bahay',
            'Mga paninda sa tindahan',
            'Magkano ang bigas?',
            'May itlog ba sa tindahan?',
            'Bumili ng 3 itlog',
            'I-order mo na yung cart ko',
          ];

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── AI Model Status Banner ──────────────────────────────────
            _buildModelStatusBanner(context, agentState),

            // ── Chat Messages Stream ────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: agentState.messages.length,
                itemBuilder: (BuildContext ctx, int i) {
                  final AgentMessage msg = agentState.messages[i];
                  return _buildMessageBubble(ctx, msg, isSeller);
                },
              ),
            ),

            // ── Voice Heard Confirmation Card ──────────────────────────
            if (agentState.heardText != null)
              _buildVoiceHeardCard(context, agentState.heardText!, isSeller),

            // ── Taglish Suggestion Chips ────────────────────────────────
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (BuildContext ctx, int i) {
                  final String chip = chips[i];
                  return ActionChip(
                    label: Text(
                      chip,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.primary,
                      ),
                    ),
                    backgroundColor: c.surface,
                    side: BorderSide(color: c.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () => _submitText(chip, isSeller),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // ── Command Bar & Push-to-Talk Mic ──────────────────────────
            _buildCommandBar(context, agentState, isSeller),
          ],
        ),
      ),
    );
  }

  void _showModelInfoDialog(BuildContext context) {
    const Color primaryRed = Color(0xFFD62828);
    const Color accentGold = Color(0xFFB45309);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: <Widget>[
              Icon(Icons.psychology, color: primaryRed, size: 24),
              SizedBox(width: 8),
              Text(
                'SARI AI Model Info',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Google DeepMind Gemma 4 E2B',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryRed,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• Architecture: Gemma4ForConditionalGeneration (Edge 2B)\n'
                '• Context Window: 128K (131,072 tokens)\n'
                '• Multimodal: Text, Vision ID, Audio PTT, Tool Calling\n'
                '• Local Weights: gemma-4-transformers-gemma-4-e2b-v1 (9.54 GB)\n'
                '• Privacy: Zero network calls sa agent path (100% offline)\n',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
              Divider(height: 16),
              Text(
                'SARI Daily Sales GBR Forecaster',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: accentGold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '• 30-Tree Gradient Boosting Regressor (GBR)\n'
                '• 15,446 real transactions · <2ms execution latency',
                style: TextStyle(fontSize: 12, height: 1.35),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Isara', style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModelStatusBanner(BuildContext context, AgentState state) {
    const Color primaryRed = Color(0xFFD62828);
    const Color accentGold = Color(0xFFB45309);

    if (state.downloadProgress != null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentGold),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(Icons.sync, color: accentGold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Sini-sync ang SARI GBR Sales Model (30 Trees)...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentGold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '${((state.downloadProgress ?? 0) * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: state.downloadProgress,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(accentGold),
                minHeight: 6,
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _showModelInfoDialog(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primaryRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primaryRed.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.auto_graph, color: primaryRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'SARI AI Engine: ${state.modelStatus}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      BuildContext context, AgentMessage msg, bool isSeller) {
    final AppColors c = appColors(context);
    const Color primaryRed = Color(0xFFD62828);

    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant / SARI bot response
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: primaryRed.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.psychology_alt_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    border: Border.all(color: c.borderSubtle),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (msg.risk != null) ...<Widget>[
                        _buildRiskBadge(msg.risk!),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 14,
                          color: c.text,
                          height: 1.4,
                        ),
                      ),
                      if (msg.draft != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _buildDraftCard(context, msg),
                      ],
                      if (!msg.isUser && (msg.intent != null || msg.explanation != null)) ...<Widget>[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _showTransparencySheet(context, msg),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(Icons.help_outline_rounded,
                                    size: 14,
                                    color: primaryRed.withValues(alpha: 0.8)),
                                const SizedBox(width: 4),
                                Text(
                                  'Bakit ito ang sagot?',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: primaryRed.withValues(alpha: 0.9),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransparencySheet(BuildContext context, AgentMessage msg) {
    const Color primaryRed = Color(0xFFD62828);
    const Color accentGold = Color(0xFFB45309);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Row(
                children: <Widget>[
                  Icon(Icons.shield_outlined, color: primaryRed, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Paliwanag ng AI (Transparency Audit)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentGold.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Text(
                          'Natukoy na Layunin (Intent):',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentGold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            msg.intent ?? 'Pangkalahatang Tanong',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Kaukulang Aksyon (Tool):',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          msg.tool ?? 'none',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Text(
                          'Antas ng Kumpiyansa:',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${((msg.confidence ?? 1.0) * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryRed,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                msg.explanation ??
                    'Pinroseso nang 100% offline sa iyong device gamit ang lokal na SARI NLU Engine at SQLite. Walang ipinadalang data sa cloud.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  child: const Text('Naintindihan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiskBadge(AgentRisk risk) {
    const Color primaryRed = Color(0xFFD62828);
    const Color accentGold = Color(0xFFB45309);
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (risk) {
      case AgentRisk.read:
        bg = primaryRed.withValues(alpha: 0.12);
        fg = primaryRed;
        label = 'READ ONLY · TALAAN';
        icon = Icons.visibility_outlined;
      case AgentRisk.draft:
        bg = const Color(0xFFFEF3C7);
        fg = accentGold;
        label = 'DRAFT · KAILANGAN NG CONFIRM';
        icon = Icons.edit_note;
      case AgentRisk.change:
        bg = primaryRed;
        fg = Colors.white;
        label = 'CHANGE · NAITALA';
        icon = Icons.check_circle_outline;
      case AgentRisk.blocked:
        bg = const Color(0xFF1E293B);
        fg = Colors.white;
        label = 'BLOCKED · SECURITY RULE';
        icon = Icons.lock_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftCard(BuildContext context, AgentMessage msg) {
    final AgentDraft draft = msg.draft!;
    final ReorderDraft? reorder = draft.reorderDraft;
    const Color accentGold = Color(0xFFB45309);
    const Color primaryRed = Color(0xFFD62828);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandAmber, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.assignment_outlined,
                  color: brandAmber, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${draft.title} · Draft pa lang',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: brandAmber,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: brandAmber, height: 16),

          // Reorder line items grouped by supplier
          if (reorder != null) ...<Widget>[
            for (final String supplier in reorder.suppliers) ...<Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.local_shipping_outlined,
                        size: 14, color: Colors.black87),
                    const SizedBox(width: 4),
                    Text(
                      supplier,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              for (final ReorderLine line in reorder.linesForSupplier(supplier))
                Padding(
                  padding: const EdgeInsets.only(left: 18, bottom: 4),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          '${line.name} × ${line.qtyPacks} ${line.unit}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '₱${line.totalCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ] else if (draft.kind == 'utang') ...<Widget>[
            Text(
              draft.note ?? 'Ledger Utang Entry',
              style: const TextStyle(fontSize: 13),
            ),
          ],

          if (draft.note != null && reorder != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              draft.note!,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'KABUUAN:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              Text(
                '₱${draft.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryRed,
                ),
              ),
            ],
          ),

          // Status & Action buttons
          const SizedBox(height: 10),
          if (msg.draftState == AgentDraftState.open) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(agentProvider.notifier).confirmDraft(msg.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text(
                      'Confirm Draft',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(agentProvider.notifier).undoDraft(msg.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentGold,
                      side: const BorderSide(color: accentGold, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text(
                      'I-edit / Kanselahin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (msg.draftState == AgentDraftState.secondConfirm) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Higit ito sa ₱500.00. Kumpirmahin muli upang magpatuloy.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(agentProvider.notifier).confirmDraft(msg.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Oo, Kumpirmahin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(agentProvider.notifier).undoDraft(msg.id);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Huwag Ituloy'),
                  ),
                ),
              ],
            ),
          ] else if (msg.draftState == AgentDraftState.confirmed) ...<Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.check_circle, color: primaryRed, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'Na-confirm na ng May-ari',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      ref.read(agentProvider.notifier).undoDraft(msg.id);
                    },
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo (6s)'),
                    style: TextButton.styleFrom(
                      foregroundColor: accentGold,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: <Widget>[
                ActionChip(
                  avatar: const Icon(Icons.share, size: 14, color: primaryRed),
                  label: const Text('I-share sa Messenger / SMS',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    final String text = reorder?.toShareableText() ??
                        'SARI Draft: ${draft.title} — ₱${draft.totalAmount}';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nakopya sa clipboard ang order list!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.print, size: 14, color: primaryRed),
                  label: const Text('I-print', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Handa para sa Bluetooth thermal printer.'),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.checklist,
                      size: 14, color: primaryRed),
                  label: const Text('Checklist sa Palengke',
                      style: TextStyle(fontSize: 11)),
                  onPressed: () {},
                ),
              ],
            ),
          ] else if (msg.draftState == AgentDraftState.undone) ...<Widget>[
            const Text(
              'Binawi ang pag-confirm (Na-undo). Walang binago sa database.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceHeardCard(
      BuildContext context, String heard, bool isSeller) {
    const Color primaryRed = Color(0xFFD62828);
    const Color accentGold = Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Narinig ko mula sa boses:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: accentGold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '"$heard"',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _submitText(heard, isSeller);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Tama, gawin'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  ref.read(agentProvider.notifier).clearHeard();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBar(
      BuildContext context, AgentState state, bool isSeller) {
    final AppColors c = appColors(context);
    const Color primaryRed = Color(0xFFD62828);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textCtrl,
              decoration: InputDecoration(
                hintText: isSeller
                    ? 'Sabihin o i-type ang kailangan ng tindahan…'
                    : 'Sabihin o i-type ang hinahanap…',
                hintStyle: TextStyle(fontSize: 13, color: c.textTertiary),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                filled: true,
                fillColor: c.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: c.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: primaryRed, width: 2),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (String val) => _submitText(val, isSeller),
            ),
          ),
          const SizedBox(width: 8),

          // Push-to-Talk Mic button
          GestureDetector(
            onTap: () {
              ref.read(agentProvider.notifier).startListening(isSeller);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: state.isListening ? const Color(0xFFB45309) : primaryRed,
                shape: BoxShape.circle,
                boxShadow: state.isListening
                    ? <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFFFFC93C).withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ]
                    : <BoxShadow>[
                        BoxShadow(
                          color: primaryRed.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                state.isListening ? Icons.graphic_eq : Icons.mic,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          GestureDetector(
            onTap: () => _submitText(_textCtrl.text, isSeller),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primaryRed,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: primaryRed.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
