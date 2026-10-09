import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/analytics_provider.dart';
import '../application/auth_provider.dart';
import '../application/inventory_provider.dart';
import '../application/listahan_provider.dart';
import '../application/locale_provider.dart';
import '../theme/app_theme.dart';
import '../theme/store_theme.dart';
import '../widgets/liquid_background.dart';
import 'agent/ai_agent_screen.dart';
import 'analytics_screen.dart';
import 'buyer/buyer_inbox_screen.dart';
import 'buyer/buyer_kiosk_screen.dart';
import 'buyer/buyer_profile_screen.dart';
import 'inventory_screen.dart';
import 'ledger/kasaysayan_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 1; // Default to POS for sellers, Profile for buyers

  void _logout() {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
    ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final bool isSeller = auth.user?.role != 'buyer';
    final AppLocale locale = ref.watch(localeProvider);

    final StoreType activeStore = auth.storeType;
    final Color storeAccent = StoreColors.forType(activeStore);
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);

    // Calculate total alerts
    final invAsync = ref.watch(inventoryProvider);
    final listAsync = ref.watch(listahanProvider);
    final int lowStock =
        invAsync.value?.products.where((p) => p.isLowStock).length ?? 0;
    final int overdue =
        listAsync.value?.entries.where((e) => e.isOverdue).length ?? 0;
    final bool hasAlerts = (lowStock + overdue) > 0;

    // ── 3 Canonical Tabs per Role ──────────────────────────────────────────
    // Seller: [0] AI Agent, [1] POS, [2] Data Summary
    // Buyer:  [0] AI Agent, [1] Profile, [2] Inbox
    final List<Widget> tabs = isSeller
        ? <Widget>[
            const AiAgentScreen(),
            const ScannerScreen(),
            AnalyticsScreen(
              onOpenTransactions: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TransactionsScreen(),
                  ),
                );
              },
            ),
          ]
        : const <Widget>[
            AiAgentScreen(),
            BuyerProfileScreen(),
            BuyerInboxScreen(),
          ];

    final int safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: brandGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SARI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Store badge (seller) or Mamimili badge (buyer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSeller
                    ? storeAccent.withValues(alpha: 0.15)
                    : brandGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSeller
                      ? storeAccent.withValues(alpha: 0.4)
                      : brandGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    isSeller ? activeStore.emoji : '🛒',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSeller ? activeStore.displayName : 'Mamimili',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSeller ? storeAccent : brandGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          if (isSeller) ...<Widget>[
            _HeaderActionButton(
              tooltip: 'Mga Abiso',
              icon: Icons.notifications_none_rounded,
              iconColor: brandAmber,
              showDot: hasAlerts,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
            _HeaderActionButton(
              tooltip: 'Kiosk ng Mamimili',
              icon: Icons.shopping_basket_outlined,
              iconColor: storeAccent,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BuyerKioskScreen(),
                ),
              ),
            ),
          ],
          _HeaderActionButton(
            tooltip: 'Mga Setting',
            icon: Icons.settings_outlined,
            iconColor: c.textSecondary,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
          // ── Top-Right Avatar ──────────────────────────────────────────
          GestureDetector(
            onTap: () => _showAvatarMenu(context, isSeller, activeStore),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 12, left: 2),
              decoration: BoxDecoration(
                color: brandGreen,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                isSeller ? '🏪' : '👤',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: SolidGlowBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: KeyedSubtree(
            key: ValueKey<int>(safeIndex),
            child: tabs[safeIndex],
          ),
        ),
      ),

      // ── Canonical 3-Button Bottom Navigation Bar ──────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: <Widget>[
                // Button 0: AI Agent (Both Seller & Buyer)
                Expanded(
                  child: _BottomNavButton(
                    label: 'AI Agent',
                    icon: Icons.auto_awesome_rounded,
                    isActive: safeIndex == 0,
                    activeColor: brandGreen,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),

                // Button 1: POS (Seller) OR Profile (Buyer)
                Expanded(
                  child: _BottomNavButton(
                    label: isSeller ? 'POS' : 'Profile',
                    icon: isSeller
                        ? Icons.point_of_sale_rounded
                        : Icons.person_rounded,
                    isActive: safeIndex == 1,
                    activeColor: brandGreen,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),

                // Button 2: Data Summary (Seller) OR Inbox (Buyer)
                Expanded(
                  child: _BottomNavButton(
                    label: isSeller ? 'Data Summary' : 'Inbox',
                    icon: isSeller
                        ? Icons.bar_chart_rounded
                        : Icons.inbox_rounded,
                    isActive: safeIndex == 2,
                    activeColor: brandGreen,
                    onTap: () {
                      setState(() => _index = 2);
                      if (isSeller) {
                        ref.invalidate(analyticsProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvatarMenu(
      BuildContext context, bool isSeller, StoreType activeStore) {
    const Color brandGreen = Color(0xFF1E6E5A);
    const Color brandAmber = Color(0xFFC8861A);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: brandGreen.withValues(alpha: 0.15),
                      child: Text(
                        isSeller ? activeStore.emoji : '👤',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isSeller
                                ? 'Tindahan ni Aling Rosa'
                                : 'Harry V. Dimaano',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isSeller
                                ? '${activeStore.displayName} · Batangas City'
                                : 'Mamimili (Buyer) · Kumintang Ilaya',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (isSeller) ...<Widget>[
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.inventory_2_outlined,
                        color: brandGreen),
                    title: const Text('Imbentaryo (Inventory)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Pamamahala ng mga paninda at stock'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InventoryScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.menu_book_outlined,
                        color: brandGreen),
                    title: const Text('Kasaysayan (Ledger at Utang)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle:
                        const Text('Pinag-isang talaan ng benta, utang at bayad'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const KasaysayanScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.swap_horiz, color: brandAmber),
                    title: const Text('Palitan ang Uri ng Tindahan',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Kasalukuyan: ${activeStore.displayName}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showStoreTypeDialog(context);
                    },
                  ),
                ],

                ListTile(
                  dense: true,
                  leading:
                      const Icon(Icons.settings_outlined, color: brandGreen),
                  title: const Text('Mga Setting',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Mag-logout',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _logout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStoreTypeDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Pumili ng Uri ng Tindahan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final StoreType t in StoreType.values)
                ListTile(
                  leading: Text(t.emoji, style: const TextStyle(fontSize: 24)),
                  title: Text(t.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    ref.read(authProvider.notifier).setStoreType(t);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 22,
                color: isActive ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? Colors.white : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.showDot = false,
  });

  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tooltip,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: onTap,
              icon: Icon(icon, size: 18, color: iconColor),
              style: IconButton.styleFrom(
                backgroundColor: c.surfaceMuted,
                foregroundColor: iconColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            if (showDot)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface, width: 1.25),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
