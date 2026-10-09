import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/buyer_provider.dart';
import '../../domain/entities/buyer_order.dart';
import '../../theme/app_theme.dart';
import 'widgets/buyer_qr_dialog.dart';

class BuyerInboxScreen extends ConsumerStatefulWidget {
  const BuyerInboxScreen({super.key});

  @override
  ConsumerState<BuyerInboxScreen> createState() => _BuyerInboxScreenState();
}

class _BuyerInboxScreenState extends ConsumerState<BuyerInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    const Color brandGreen = Color(0xFF1E6E5A);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text(
          'Inbox',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: brandGreen,
          labelColor: brandGreen,
          unselectedLabelColor: c.textSecondary,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const <Widget>[
            Tab(text: 'Mensahe (3)'),
            Tab(text: 'Mga Order'),
            Tab(text: 'Alerto'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: <Widget>[
          _buildMessagesTab(context),
          _buildOrdersTab(context),
          _buildAlertsTab(context),
        ],
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context) {
    final AppColors c = appColors(context);
    const Color brandGreen = Color(0xFF1E6E5A);

    final List<Map<String, dynamic>> threads = <Map<String, dynamic>>[
      <String, dynamic>{
        'name': 'Aling Rosa Sari-Sari Store',
        'area': 'Kumintang Ilaya, Batangas City',
        'msg': 'Handa na po ang inyong order ng Lucky Me at mantika! Pwede nang kunin.',
        'time': '5m ago',
        'unread': true,
        'avatar': '🏪',
      },
      <String, dynamic>{
        'name': 'Lipa Rice Mill & Grains',
        'area': 'Poblacion Market',
        'msg': 'May bagong dating na Sinandomeng 50kg sako.',
        'time': '2h ago',
        'unread': false,
        'avatar': '🌾',
      },
      <String, dynamic>{
        'name': 'Nanay Soling Carinderia',
        'area': 'Near BSU Main Gate',
        'msg': 'Available na po ang Pork Adobo at Sinigang for lunch!',
        'time': 'Yesterday',
        'unread': false,
        'avatar': '🍲',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext ctx, int i) {
        final Map<String, dynamic> th = threads[i];
        final bool unread = th['unread'] as bool;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Binubuksan ang mensahe mula sa ${th['name']}'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: unread
                  ? brandGreen.withValues(alpha: 0.05)
                  : c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unread
                    ? brandGreen.withValues(alpha: 0.3)
                    : c.borderSubtle,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.background,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    th['avatar'] as String,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              th['name'] as String,
                              style: TextStyle(
                                fontWeight: unread
                                    ? FontWeight.w900
                                    : FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            th['time'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: unread ? brandGreen : c.textTertiary,
                              fontWeight: unread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        th['msg'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: unread ? c.text : c.textSecondary,
                          fontWeight: unread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread) ...<Widget>[
                  const SizedBox(width: 8),
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: brandGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrdersTab(BuildContext context) {
    final AppColors c = appColors(context);
    final BuyerState buyer = ref.watch(buyerProvider);
    final BuyerOrder? recent = buyer.stagedOrder;
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: <Widget>[
        if (recent != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: brandGreen.withValues(alpha: 0.4)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'NAIPADALA · HANDA NANG I-SCAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: brandAmber,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ID: ${recent.orderId.substring(0, 8)}',
                      style: TextStyle(fontSize: 11, color: c.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Aling Rosa Sari-Sari Store',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 6),
                for (final BuyerOrderItem item in recent.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• ${item.name} × ${item.qty} (₱${(item.unitPrice * item.qty).toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: <Widget>[
                    const Text('KABUUAN:',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      '₱${recent.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: brandGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => BuyerQrDialog(order: recent),
                      );
                    },
                    icon: const Icon(Icons.qr_code, size: 20),
                    label: const Text('Ipakita ang QR sa Tindera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Past order history mock
        _buildPastOrderCard(
          context,
          store: 'Nanay Soling Carinderia',
          date: 'Oktubre 8, 2026',
          itemsSummary: '2x Pork Adobo, 2x Kanin',
          total: 180.0,
          status: 'Na-scan at Natanggap',
        ),
        const SizedBox(height: 10),
        _buildPastOrderCard(
          context,
          store: 'Lipa Rice Mill & Grains',
          date: 'Oktubre 5, 2026',
          itemsSummary: '5kg Bigas Dinorado',
          total: 310.0,
          status: 'Na-scan at Natanggap',
        ),
      ],
    );
  }

  Widget _buildPastOrderCard(
    BuildContext context, {
    required String store,
    required String date,
    required String itemsSummary,
    required double total,
    required String status,
  }) {
    final AppColors c = appColors(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                store,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(date,
                  style: TextStyle(fontSize: 11, color: c.textTertiary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(itemsSummary,
              style: TextStyle(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
              const Spacer(),
              Text(
                '₱${total.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(BuildContext context) {
    final AppColors c = appColors(context);
    const Color brandAmber = Color(0xFFC8861A);

    final List<Map<String, String>> alerts = <Map<String, String>>[
      <String, String>{
        'title': 'Bagong Benta sa Gulayan',
        'body': 'May sariwang talong, sitaw, at kamatis mula sa Aling Rosa Farm.',
        'time': 'Ngayon, 8:00 AM',
      },
      <String, String>{
        'title': 'Oras ng Pagsasara',
        'body': 'Bukas ang Mang Tomas Store hanggang 9:00 PM ngayong gabi.',
        'time': 'Kahapon, 5:30 PM',
      },
      <String, String>{
        'title': 'Offline Handoff Aktibo',
        'body': 'Kahit walang internet signal sa inyong lugar, gagana pa rin ang QR order pass.',
        'time': 'Oktubre 7, 2026',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: alerts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext ctx, int i) {
        final Map<String, String> a = alerts[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.borderSubtle),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.notifications_active_outlined,
                  color: brandAmber, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      a['title']!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['body']!,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['time']!,
                      style: TextStyle(fontSize: 11, color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
