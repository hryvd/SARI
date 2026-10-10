import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/buyer_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/store_profile.dart';
import '../../theme/app_theme.dart';
import 'widgets/buyer_cart_sheet.dart';
import 'widgets/credibility_badge_sheet.dart';

class BuyerKioskScreen extends ConsumerStatefulWidget {
  const BuyerKioskScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<BuyerKioskScreen> createState() => _BuyerKioskScreenState();
}

class _BuyerKioskScreenState extends ConsumerState<BuyerKioskScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final BuyerState state = ref.watch(buyerProvider);
    final BuyerNotifier notifier = ref.read(buyerProvider.notifier);
    final StoreProfile? profile = state.storeProfile;

    final String storeName = profile?.storeName ?? 'SARI Tindahan';
    final List<Product> items = state.filteredCatalog;

    // Distinct categories
    final List<String> categories = state.catalog
        .map((Product p) => p.categoryName ?? '')
        .where((String cat) => cat.isNotEmpty)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            // Main scrollable content with strict 16dp horizontal padding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 12),
                  // The app shell owns store branding when this screen is embedded.
                  if (!widget.embedded)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: c.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.storefront,
                                  color: c.primary, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  storeName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: c.text,
                                  ),
                                ),
                                Text(
                                  'Kiosk ng Mamimili (Self-Serve)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.exit_to_app, color: c.textSecondary),
                          tooltip: 'Bumalik sa Cashier',
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  if (!widget.embedded) const SizedBox(height: 12),
                  // Trust details are only shown in the standalone kiosk route.
                  if (!widget.embedded)
                    InkWell(
                      onTap: () => CredibilityBadgeSheet.show(context, profile),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: c.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: c.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.verified, color: c.accent, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dokumento ay Nakakabit sa Telepono',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.accent,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: c.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: notifier.search,
                      style: TextStyle(fontSize: 13, color: c.text),
                      decoration: InputDecoration(
                        hintText: 'Maghanap ng bilihin...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: c.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: c.textSecondary,
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  notifier.search('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category Chips
                  if (categories.isNotEmpty) ...<Widget>[
                    SizedBox(
                      height: 32,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length + 1,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (BuildContext ctx, int index) {
                          if (index == 0) {
                            final bool isAllSelected =
                                state.selectedCategory == null;
                            return ChoiceChip(
                              label: const Text('Lahat'),
                              selected: isAllSelected,
                              onSelected: (_) => notifier.selectCategory(null),
                              selectedColor: c.primary,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isAllSelected ? Colors.white : c.text,
                              ),
                              visualDensity: VisualDensity.compact,
                            );
                          }
                          final String cat = categories[index - 1];
                          final bool isSelected = state.selectedCategory == cat;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => notifier.selectCategory(cat),
                            selectedColor: c.primary,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : c.text,
                            ),
                            visualDensity: VisualDensity.compact,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Catalog Grid
                  Expanded(
                    child: state.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                            ? Center(
                                child: Text(
                                  'Walang nahanap na paninda.',
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              )
                            : GridView.builder(
                                padding: EdgeInsets.only(
                                  top: 4,
                                  bottom: state.isCartEmpty ? 16 : 80,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.82,
                                ),
                                itemCount: items.length,
                                itemBuilder: (BuildContext ctx, int index) {
                                  final Product p = items[index];
                                  return _buildProductBox(p, c, notifier);
                                },
                              ),
                  ),
                ],
              ),
            ),
            // Floating Cart Action Bar at bottom
            if (!state.isCartEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.cartCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Text(
                                'Kabuuang Order',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                '₱${state.cartTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => BuyerCartSheet.show(context),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text(
                          'Tingnan ang Basket',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: c.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductBox(Product p, AppColors c, BuyerNotifier notifier) {
    final bool isOutOfStock = p.stockQty <= 0;
    final bool isLowStock = p.stockQty > 0 && p.stockQty <= 3;

    return Container(
      decoration: BoxDecoration(
        color: isOutOfStock ? c.surface.withValues(alpha: 0.5) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutOfStock
              ? c.error.withValues(alpha: 0.5)
              : isLowStock
                  ? c.warning.withValues(alpha: 0.8)
                  : c.border,
          width: isLowStock || isOutOfStock ? 1.5 : 1.0,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Product category icon / thumbnail
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Icon(
                      Icons.shopping_bag,
                      size: 38,
                      color: isOutOfStock ? c.textSecondary : c.primary,
                    ),
                  ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: c.error,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'UBOS NA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (isLowStock)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: c.warning,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Konti na lang',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '₱${p.unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: c.primary,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_shopping_cart,
                        size: 18,
                        color: isOutOfStock ? c.textSecondary : c.primary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isOutOfStock
                          ? null
                          : () {
                              notifier.addToCart(p);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Naidagdag sa basket: ${p.name}'),
                                  duration: const Duration(milliseconds: 900),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
