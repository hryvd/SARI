import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/analytics_provider.dart';
import '../application/auth_provider.dart';
import '../application/inventory_provider.dart';
import '../application/listahan_provider.dart';
import '../application/locale_provider.dart';
import '../application/store_adapter_provider.dart';
import '../domain/adapters/store_adapter.dart';
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
import 'settings_screen.dart';
import 'transactions_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int? _index;

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

    // Calculate total alerts
    final invAsync = ref.watch(inventoryProvider);
    final listAsync = ref.watch(listahanProvider);
    final int lowStock =
        invAsync.value?.products.where((p) => p.isLowStock).length ?? 0;
    final int overdue =
        listAsync.value?.entries.where((e) => e.isOverdue).length ?? 0;
    final bool hasAlerts = (lowStock + overdue) > 0;

    final StoreAdapter storeAdapter = ref.watch(storeAdapterProvider);

    final String storeName = auth.user?.storeName.isNotEmpty == true
        ? auth.user!.storeName
        : (auth.storeNameHint ?? (isSeller ? 'Tindahan' : 'Mamimili'));
    final String initialLetter =
        storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';

    // ── 3 Canonical Tabs per Role ──────────────────────────────────────────
    // Seller: [0] AI Agent / Assistant, [1] Tindahan POS, [2] Buod / Summary
    // Buyer:  [0] AI Agent / Assistant, [1] Tindahan Shopping, [2] Orders & Profile
    final List<Widget> tabs = isSeller
        ? <Widget>[
            const AiAgentScreen(),
            storeAdapter.buildPosInterface(context),
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
        : <Widget>[
            const AiAgentScreen(),
            const BuyerKioskScreen(embedded: true),
            const BuyerProfileScreen(embedded: true),
          ];

    final int safeIndex =
        (_index ?? (isSeller ? 1 : 2)).clamp(0, tabs.length - 1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.primaryDark,
        elevation: 0,
        titleSpacing: 12,
        title: Row(
          children: <Widget>[
            // "S" Brand Squircle Avatar (Matches Image 1)
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initialLetter,
                style: TextStyle(
                  color: c.primaryDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Store Title & Subtitle in White
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    isSeller
                        ? 'TINDERA / TINDERO • ${activeStore.displayName.toUpperCase()}'
                        : 'MAMIMILI • SARI BUYER',
                    style: const TextStyle(
                      color: Color(0xFFFDE8E8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
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
              tooltip: t(locale, 'inventory'),
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.white,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const InventoryScreen(),
                ),
              ),
            ),
            _HeaderActionButton(
              tooltip: t(locale, 'notifications'),
              icon: Icons.notifications_none_rounded,
              iconColor: Colors.white,
              showDot: hasAlerts,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
          ],
          if (!isSeller) ...<Widget>[
            _HeaderActionButton(
              tooltip: 'Inbox ng Mamimili',
              icon: Icons.inbox_outlined,
              iconColor: Colors.white,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BuyerInboxScreen(),
                ),
              ),
            ),
            _HeaderActionButton(
              tooltip: t(locale, 'notifications'),
              icon: Icons.notifications_none_rounded,
              iconColor: Colors.white,
              showDot: hasAlerts,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
            ),
          ],
          // ── Top-Right User Avatar (Image 1 inspired) ────────────────────
          GestureDetector(
            onTap: () =>
                _showAvatarMenu(context, isSeller, activeStore, storeName),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 14, left: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline_rounded,
                color: Colors.white,
                size: 20,
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
                // Button 0: AI Agent / Assistant
                Expanded(
                  child: _BottomNavButton(
                    label: 'Assistant',
                    icon: Icons.auto_awesome_rounded,
                    isActive: safeIndex == 0,
                    activeColor: c.primary,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),

                // Button 1: Tindahan (Seller POS OR Buyer Shopping)
                Expanded(
                  child: _BottomNavButton(
                    label: 'Tindahan',
                    icon: isSeller
                        ? Icons.point_of_sale_rounded
                        : Icons.shopping_bag_outlined,
                    isActive: safeIndex == 1,
                    activeColor: c.primary,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),

                // Button 2: Buod (Seller) OR Profile & Orders (Buyer)
                Expanded(
                  child: _BottomNavButton(
                    label: isSeller ? 'Buod' : 'Profile',
                    icon: isSeller
                        ? Icons.bar_chart_rounded
                        : Icons.person_rounded,
                    isActive: safeIndex == 2,
                    activeColor: c.primary,
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

  void _showAvatarMenu(BuildContext context, bool isSeller,
      StoreType activeStore, String currentStoreName) {
    final AppLocale locale = ref.read(localeProvider);
    final Color primaryRed = appColors(context).primary;
    const Color accentGold = Color(0xFFB45309);

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
                      backgroundColor: primaryRed.withValues(alpha: 0.15),
                      child: Icon(
                        isSeller
                            ? Icons.storefront_rounded
                            : Icons.person_rounded,
                        color: primaryRed,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            currentStoreName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            isSeller
                                ? '${activeStore.displayName} · Tindahan'
                                : (locale == AppLocale.en
                                    ? 'Customer (Buyer)'
                                    : 'Mamimili (Buyer)'),
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
                    leading:
                        Icon(Icons.inventory_2_outlined, color: primaryRed),
                    title: Text(t(locale, 'inventory'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(locale == AppLocale.en
                        ? 'Manage items and inventory stock'
                        : 'Pamamahala ng mga paninda at stock'),
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
                    leading: Icon(Icons.menu_book_outlined, color: primaryRed),
                    title: Text(t(locale, 'kasaysayan_title'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(locale == AppLocale.en
                        ? 'Sales, credit, and repayments ledger'
                        : 'Pinag-isang talaan ng benta, utang at bayad'),
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
                    leading: const Icon(Icons.swap_horiz, color: accentGold),
                    title: Text(
                        locale == AppLocale.en
                            ? 'Switch Store Type'
                            : 'Palitan ang Uri ng Tindahan',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(locale == AppLocale.en
                        ? 'Current: ${activeStore.displayName}'
                        : 'Kasalukuyan: ${activeStore.displayName}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      _showStoreTypeDialog(context);
                    },
                  ),
                ],
                ListTile(
                  dense: true,
                  leading: Icon(Icons.settings_outlined, color: primaryRed),
                  title: Text(t(locale, 'settings'),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
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
                  title: Text(t(locale, 'logout'),
                      style: const TextStyle(
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
    const Color primaryRed = Color(0xFFD62828);
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
                  leading: const Icon(Icons.store_mall_directory_rounded,
                      color: primaryRed),
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
                color:
                    isActive ? Colors.white : appColors(context).textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : appColors(context).textSecondary,
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
                backgroundColor: Colors.white.withValues(alpha: 0.16),
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
