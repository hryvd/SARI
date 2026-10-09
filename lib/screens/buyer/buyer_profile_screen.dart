import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../settings_screen.dart';

class BuyerProfileScreen extends ConsumerWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = appColors(context);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: <Widget>[
          // ── Buyer Profile Header Card ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: c.borderSubtle),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 34,
                  backgroundColor: brandGreen.withValues(alpha: 0.15),
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
                          fontWeight: FontWeight.bold,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: brandAmber),
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
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: brandGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'MAMIMILI (BUYER ACCOUNT)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: brandGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Utang Balance Sheet (Read-Only) ──────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: brandAmber, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.receipt_long_outlined,
                        color: brandAmber, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Balanse sa Utang sa Tindahan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: brandAmber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '₱120.00',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Aling Rosa Sari-Sari Store: ₱120.00 (Due: Sabado)\n'
                  '• Lipa Rice Mill: ₱0.00 (Walang utang)',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Paalala: Read-only ang talaan dito. Ang tindera lamang ang nagtatala sa Kasaysayan.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Navigational Rows ─────────────────────────────────────────
          _buildRowCard(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Aking mga Order',
            subtitle: 'Tingnan ang QR code at nakaraang listahan',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pumunta sa Inbox > Mga Order para sa QR code.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildRowCard(
            context,
            icon: Icons.storefront_outlined,
            title: 'Mga Paboritong Tindahan',
            subtitle: 'Aling Rosa, Lipa Rice Depot, Nanay Soling',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildRowCard(
            context,
            icon: Icons.map_outlined,
            title: 'Mga Address at Lokasyon',
            subtitle: 'Kumintang Ilaya, Batangas City',
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _buildRowCard(
            context,
            icon: Icons.settings_outlined,
            title: 'Mga Setting',
            subtitle: 'Wika, privacy, seguridad ng account',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(height: 20),

          // ── Switch to Seller Mode Button ──────────────────────────────
          ElevatedButton.icon(
            onPressed: () {
              ref.read(authProvider.notifier).updateRole('owner');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lumipat sa Mode: May-ari ng Tindahan (Seller)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.store, size: 20),
            label: const Text(
              'Lumipat sa Tindera (Seller Mode)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final AppColors c = appColors(context);
    const Color brandGreen = Color(0xFF1E6E5A);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: brandGreen, size: 24),
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
            Icon(Icons.chevron_right, color: c.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
