import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_provider.dart';
import '../../domain/entities/buyer_order.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';
import 'widgets/buyer_qr_dialog.dart';

class BuyerProfileScreen extends ConsumerWidget {
  final bool embedded;
  const BuyerProfileScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = appColors(context);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);
    const Color brandTeal = Color(0xFF0D9488);

    final Widget content = ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: <Widget>[
        // ── 1. Buyer Profile Header Fill Container ────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.borderSubtle),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: brandGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: brandGreen.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'HD',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: brandGreen,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      auth.user?.storeName.isNotEmpty == true
                          ? auth.user!.storeName
                          : 'Harry V. Dimaano',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: brandAmber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Brgy. Kumintang Ilaya, Batangas City',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 12,
                            color: brandGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'MAMIMILI (BUYER)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: brandGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 2. Quick Stat Filled Containers ──────────────────────────────
        Row(
          children: <Widget>[
            // Metric 1: Utang Balance
            Expanded(
              child: _buildMetricFillBox(
                context,
                title: 'Balanse sa Utang',
                value: '₱120.00',
                subtitle: '1 may utang',
                accentColor: brandAmber,
                bgColor: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                icon: Icons.receipt_long_rounded,
              ),
            ),
            const SizedBox(width: 8),
            // Metric 2: Active Orders
            Expanded(
              child: _buildMetricFillBox(
                context,
                title: 'Aktibong Order',
                value: '1 Order',
                subtitle: 'Handa na',
                accentColor: brandGreen,
                bgColor: brandGreen.withValues(alpha: 0.08),
                icon: Icons.local_mall_rounded,
              ),
            ),
            const SizedBox(width: 8),
            // Metric 3: Favorite Stores
            Expanded(
              child: _buildMetricFillBox(
                context,
                title: 'Suki Tindahan',
                value: '3 Suki',
                subtitle: 'Konektado',
                accentColor: brandTeal,
                bgColor: brandTeal.withValues(alpha: 0.08),
                icon: Icons.storefront_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── 3. Utang Balance Sheet Fill Container ─────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: brandAmber.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(
                        Icons.receipt_long_rounded,
                        color: brandAmber,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Talaan ng Utang (Listahan)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB45309),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: brandAmber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'READ-ONLY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '₱120.00',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 8),
              _buildStoreCreditRow('Aling Rosa Sari-Sari Store', '₱120.00', 'Due: Sabado'),
              const Divider(height: 14, color: Color(0xFFFDE68A)),
              _buildStoreCreditRow('Lipa Rice Mill & Depot', '₱0.00', 'Walang utang'),
              const SizedBox(height: 10),
              const Text(
                'Paalala: Read-only ang talaang ito para sa mamimili. Ang tindera lamang ang nagtatala sa Kasaysayan ledger.',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── 4. Action / Service Filled Containers ────────────────────────
        _buildFillActionCard(
          context,
          icon: Icons.qr_code_2_rounded,
          iconColor: brandGreen,
          title: 'Aking QR Code at mga Order',
          subtitle: 'Ipakita sa tindera para sa mabilisang checkout',
          badgeText: '1 Handa',
          badgeColor: brandGreen,
          onTap: () {
            // Open active order QR code dialog
            final BuyerOrder sampleOrder = BuyerOrder(
              orderId: 'ORD-8821',
              storeId: 'store-1',
              timestamp: DateTime.now(),
              items: const <BuyerOrderItem>[
                BuyerOrderItem(
                  id: 'item-1',
                  name: 'Lucky Me Pancit Canton',
                  qty: 3,
                  unitPrice: 15.0,
                ),
                BuyerOrderItem(
                  id: 'item-2',
                  name: 'Coke Sakto 200ml',
                  qty: 2,
                  unitPrice: 12.0,
                ),
              ],
              totalAmount: 69.0,
              notes: 'Handa para sa checkout',
            );
            BuyerQrDialog.show(context, sampleOrder);
          },
        ),
        const SizedBox(height: 10),

        _buildFillActionCard(
          context,
          icon: Icons.storefront_rounded,
          iconColor: brandAmber,
          title: 'Mga Paboritong Tindahan',
          subtitle: 'Aling Rosa, Lipa Rice Depot, Nanay Soling Carinderia',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('3 tindahan ang nakakonekta sa iyong account.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 10),

        _buildFillActionCard(
          context,
          icon: Icons.place_outlined,
          iconColor: brandTeal,
          title: 'Address at Lokasyon',
          subtitle: 'Brgy. Kumintang Ilaya, Batangas City',
          onTap: () {},
        ),
        const SizedBox(height: 18),

        // ── 5. Switch to Seller Mode Fill Button ──────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: brandGreen.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).updateRole('owner');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lumipat sa Mode: May-ari ng Tindahan (Seller)'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.store_rounded, size: 20),
            label: const Text(
              'Lumipat sa Tindera (Seller Mode)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text(
          'Aking Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildMetricFillBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: accentColor),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCreditRow(String storeName, String amount, String detail) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                storeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB45309),
          ),
        ),
      ],
    );
  }

  Widget _buildFillActionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    final AppColors c = appColors(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderSubtle),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...<Widget>[
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? iconColor,
                  ),
                ),
              ),
            ],
            Icon(Icons.chevron_right, color: c.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
