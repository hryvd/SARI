import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_provider.dart';
import '../../application/buyer_provider.dart';
import '../../domain/entities/buyer_order.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';
import 'buyer_kiosk_screen.dart';
import 'widgets/buyer_qr_dialog.dart';

/// Buyer Profile & Orders Screen
/// Tailored for the Buyer persona with:
///   • Identity & Suki status header
///   • Metric summary (Utang balance, Active orders, Suki stores)
///   • Active order card with full itemized details & QR code action
///   • Self-serve Kiosk launcher banner
///   • Recent order history with detailed receipt modals
///   • Read-only Utang credit sheet per store
///   • Connected Suki stores
///   • Switch to Seller mode button
class BuyerProfileScreen extends ConsumerWidget {
  final bool embedded;
  const BuyerProfileScreen({super.key, this.embedded = false});

  static const Color _brandRed = Color(0xFFD62828);
  static const Color _brandAmber = Color(0xFFB45309);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final BuyerState buyer = ref.watch(buyerProvider);
    final BuyerOrder? stagedOrder = buyer.stagedOrder;
    final String buyerName = auth.user?.role == 'buyer' &&
            auth.user?.userId != 'buyer_guest' &&
            auth.user?.storeName.trim().isNotEmpty == true
        ? auth.user!.storeName.trim()
        : 'Mamimili';

    final Widget content = Container(
      color: const Color(0xFFF9F7F5),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: <Widget>[
          // ── 1. Buyer Profile Header ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEDE8E1)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: _brandRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _brandRed.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'HD',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _brandRed,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              auth.user?.storeName.isNotEmpty == true
                                  ? buyerName
                                  : 'Mamimili',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F1A17),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: const Text(
                              'BUYER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: _brandAmber,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              auth.storeNameHint != null
                                  ? 'Konektado: ${auth.storeNameHint!}'
                                  : 'Lokal na Pamayanan',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A7269),
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
                          color: _brandRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 12,
                              color: _brandRed,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'MAMIMILI (BUYER)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _brandRed,
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

          // ── 2. Metric Boxes ───────────────────────────────────────────────
          Row(
            children: <Widget>[
              // Metric 1: Utang Balance
              Expanded(
                child: _buildMetricBox(
                  title: 'Mga item sa basket',
                  value: '${buyer.cartCount}',
                  subtitle: buyer.cartCount == 1 ? '1 item' : 'Kabuuang item',
                  accentColor: _brandRed,
                  bgColor: const Color(0xFFFFF5F5),
                  icon: Icons.shopping_bag_outlined,
                ),
              ),
              const SizedBox(width: 8),
              // Metric 2: Active Orders
              Expanded(
                child: _buildMetricBox(
                  title: 'Aktibong Order',
                  value: stagedOrder == null ? 'Wala' : '1 Order',
                  subtitle:
                      stagedOrder == null ? 'Walang aktibo' : 'May QR order',
                  accentColor: _brandRed,
                  bgColor: const Color(0xFFFFF5F5),
                  icon: Icons.local_mall_rounded,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 14),

          // ── 3. Active Order Card (Full Details & QR) ──────────────────────
          _buildActiveOrderCard(context, stagedOrder),
          const SizedBox(height: 14),

          // ── 4. Self-Serve Kiosk Quick Action Banner ────────────────────────
          _buildKioskLauncherBanner(context),
          const SizedBox(height: 14),

          // ── 5. Order History with Details ─────────────────────────────────
          _buildOrderHistorySection(context),
          const SizedBox(height: 14),

          const SizedBox(height: 18),

          // ── 8. Secure Logout Button ───────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text(
                'Mag-log out',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandRed,
                side: const BorderSide(color: _brandRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (embedded) {
      return content;
    }

    final AppColors c = appColors(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: const Text(
          'Aking Profile at mga Order',
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

  // ─── Active Order Card ──────────────────────────────────────────────────────

  Widget _buildActiveOrderCard(BuildContext context, BuyerOrder? order) {
    if (order == null) {
      final AppColors c = appColors(context);
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: <Widget>[
            Icon(Icons.receipt_long_outlined, color: c.textTertiary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Kapag gumawa ka ng QR order, lalabas ito rito.'),
            ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDE8E1)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header row with status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                const Icon(Icons.local_mall_rounded,
                    color: _brandRed, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Kasalukuyang Order: ${order.orderId}',
                        style: const TextStyle(
                          color: Color(0xFF1F1A17),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Store ID: ${order.storeId}',
                        style: const TextStyle(
                          color: Color(0xFF7A7269),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Text(
                    'Handa na 🛍️',
                    style: TextStyle(
                      color: Color(0xFF166534),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEDE8E1), height: 1),

          // Items breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: order.items.map((BuyerOrderItem item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F2EB),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.qty}x',
                              style: const TextStyle(
                                color: Color(0xFF5A524C),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF1F1A17),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₱${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1F1A17),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Color(0xFFEDE8E1), height: 1),

          // Subtotal row & QR action button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Kabuuang Babayaran:',
                      style: TextStyle(color: Color(0xFF7A7269), fontSize: 11),
                    ),
                    Text(
                      '₱${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFF1F1A17),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => BuyerQrDialog.show(context, order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                  label: const Text(
                    'Ipakita ang QR',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Kiosk Launcher Banner ──────────────────────────────────────────────────

  Widget _buildKioskLauncherBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Mamili sa Suki Kiosk',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pumili ng mga paninda sa digital catalog para sa self-serve basket.',
                  style: TextStyle(
                    color: Color(0xFFC2410C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BuyerKioskScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Buksan 🛒',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Order History Section ──────────────────────────────────────────────────

  Widget _buildOrderHistorySection(BuildContext context) {
    final AppColors c = appColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.history_rounded, color: c.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Wala pang naka-save na order',
                    style:
                        TextStyle(color: c.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  'Hindi pa available ang history ng mga nakaraang order.',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Metric Box Widget ─────────────────────────────────────────────────────

  Widget _buildMetricBox({
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
          Icon(icon, size: 16, color: accentColor),
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
              color: Color(0xFF5A524C),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
