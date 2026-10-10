import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/combo_engine.dart';
import '../../theme/app_theme.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import 'combo_builder.dart';

/// Carinderia Kiosk POS Screen
/// Designed to match the POS inspiration layout:
///   • Clean warm canvas background
///   • Search bar with quick clear
///   • Horizontal category pills (Lahat, Ulam, Kanin, Silog, etc.)
///   • Responsive dish blocks grid with amber in-cart badges and portion counters
///   • Sticky bottom checkout dock (Offline notice + payment pills + red Bayaran button)
///   • Clean white checkout basket / tender bottom sheet (NO black container!)
class CarinderiaPosScreen extends ConsumerStatefulWidget {
  const CarinderiaPosScreen({super.key});

  @override
  ConsumerState<CarinderiaPosScreen> createState() =>
      _CarinderiaPosScreenState();
}

class _CarinderiaPosScreenState extends ConsumerState<CarinderiaPosScreen> {
  static const Color _brand = StoreColors.carinderia;

  static const List<String> _categories = <String>[
    'Lahat',
    'Ulam',
    'Kanin',
    'Silog',
    'Gulay',
    'Sabaw',
    'Inumin',
    'Meryenda',
  ];

  String _selectedCategory = 'Lahat';
  final TextEditingController _searchCtrl = TextEditingController();
  List<CartLine> _cart = <CartLine>[];
  String _orderType = 'Dine-in';
  String _paymentMethod = 'Cash'; // Cash, GCash, Utang

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── cart helpers ───────────────────────────────────────────────────────────

  double get _total => ComboEngine.cartTotal(_cart);
  int get _itemCount =>
      _cart.fold<int>(0, (int s, CartLine l) => s + l.quantity);

  int _cartQtyFor(String id) {
    for (final CartLine line in _cart) {
      if (line.id == id) return line.quantity;
    }
    return 0;
  }

  void _addDish(Product p) {
    setState(() {
      _cart = ComboEngine.addToCart(
        _cart,
        CartLine(
          id: p.productId,
          name: p.name,
          unitPrice: p.unitPrice,
          category: p.categoryName ?? 'Ulam',
        ),
      );
    });
  }

  void _addCombo(ComboMeal combo) {
    setState(() {
      _cart = ComboEngine.addToCart(
        _cart,
        CartLine(
          id: combo.comboId,
          name: combo.name,
          unitPrice: combo.comboPrice,
          category: combo.category,
          isCombo: true,
          comboItems: combo.items,
        ),
      );
    });
  }

  void _removeOne(String id) =>
      setState(() => _cart = ComboEngine.removeOne(_cart, id));

  void _clearCart() => setState(() => _cart = <CartLine>[]);

  // ── checkout bottom sheet (clean white container) ──────────────────────────

  void _showCartSheet() {
    final AppColors c = appColors(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModal) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.92,
              minChildSize: 0.4,
              expand: false,
              builder: (_, ScrollController scroll) {
                return SafeArea(
                  top: false,
                  child: Container(
                    color: c.surface,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 12),
                        // Grab handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDD5CE),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.restaurant_rounded,
                                  color: _brand, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Order Basket ($_itemCount)',
                                style: const TextStyle(
                                  color: Color(0xFF1F1A17),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              if (_cart.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _clearCart();
                                    setModal(() {});
                                  },
                                  child: const Text(
                                    'I-clear',
                                    style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Color(0xFF7A7269)),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Order type toggle (Dine-in / Take-out)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _OrderTypeChip(
                                  label: 'Dine-in 🍽️',
                                  selected: _orderType == 'Dine-in',
                                  onTap: () {
                                    setState(() => _orderType = 'Dine-in');
                                    setModal(() {});
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _OrderTypeChip(
                                  label: 'Take-out 📦',
                                  selected: _orderType == 'Take-out',
                                  onTap: () {
                                    setState(() => _orderType = 'Take-out');
                                    setModal(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFEDE8E1), height: 1),

                        // Cart items list
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Walang order pa sa basket.',
                                    style: TextStyle(
                                      color: Color(0xFF7A7269),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scroll,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  itemCount: _cart.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      color: Color(0xFFF3EFEA), height: 1),
                                  itemBuilder: (_, int i) {
                                    final CartLine line = _cart[i];
                                    return _CartLineRow(
                                      line: line,
                                      brand: _brand,
                                      onRemove: () {
                                        _removeOne(line.id);
                                        setModal(() {});
                                      },
                                      onAdd: () {
                                        setState(() {
                                          _cart = ComboEngine.addToCart(
                                            _cart,
                                            CartLine(
                                              id: line.id,
                                              name: line.name,
                                              unitPrice: line.unitPrice,
                                              category: line.category,
                                              isCombo: line.isCombo,
                                              comboItems: line.comboItems,
                                            ),
                                          );
                                        });
                                        setModal(() {});
                                      },
                                    );
                                  },
                                ),
                        ),
                        const Divider(color: Color(0xFFEDE8E1), height: 1),

                        // Subtotal summary
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '$_orderType · $_itemCount item${_itemCount == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Color(0xFF7A7269),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '₱${_total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1F1A17),
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F2EB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFEDE8E1)),
                                ),
                                child: Text(
                                  'Paraan: $_paymentMethod',
                                  style: const TextStyle(
                                    color: Color(0xFF5A524C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cash Tender Panel
                        _TenderPanel(
                          total: _total,
                          paymentMethod: _paymentMethod,
                          onCheckout: (double change) {
                            _clearCart();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '✅ Bayad natanggap! Sukli: ₱${change.toStringAsFixed(2)}',
                                ),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AsyncValue<InventoryState> invAsync = ref.watch(inventoryProvider);
    final List<Product> dbItems = invAsync.value?.products ?? <Product>[];
    final List<Product> sourceDishes = dbItems;

    // Filter by search query and category
    final String query = _searchCtrl.text.trim().toLowerCase();
    final List<Product> filtered = sourceDishes.where((Product p) {
      final String cat = p.categoryName ?? 'Ulam';
      final bool matchesCat =
          _selectedCategory == 'Lahat' || cat == _selectedCategory;
      final bool matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          cat.toLowerCase().contains(query);
      return matchesCat && matchesQuery;
    }).toList();

    return StoreScaffold(
      storeType: StoreType.carinderia,
      headerTitle: 'Carinderia Kiosk',
      headerActions: <Widget>[
        IconButton(
          icon: const Icon(Icons.restaurant_menu_rounded),
          tooltip: 'Combo Builder',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ComboBuilderScreen(onAddCombo: _addCombo),
            ),
          ),
        ),
      ],
      body: Container(
        color: c.background,
        child: Column(
          children: <Widget>[
            // Search Bar + Combo Quick Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.borderSubtle),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Maghanap ng ulam / putahe...',
                          hintStyle: TextStyle(
                            color: c.textTertiary,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: c.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      size: 18, color: c.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ComboBuilderScreen(onAddCombo: _addCombo),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.borderSubtle),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.stars_rounded, color: _brand, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            'Combo',
                            style: TextStyle(
                              color: c.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Category Pills (Lahat, Ulam, Kanin, Silog, etc.)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, int i) {
                  final String cat = _categories[i];
                  final bool selected = cat == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? c.primary : c.borderSubtle,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: selected ? Colors.white : c.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Dish Blocks Grid
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.restaurant,
                              size: 48, color: Color(0xFFDDD5CE)),
                          SizedBox(height: 12),
                          Text(
                            'Walang nahanap na ulam.',
                            style: TextStyle(
                              color: Color(0xFF7A7269),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (BuildContext ctx, BoxConstraints constraints) {
                        final int cols = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 600
                                ? 3
                                : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.82,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (_, int i) {
                            final Product p = filtered[i];
                            final int inCartQty = _cartQtyFor(p.productId);
                            return _DishTile(
                              product: p,
                              brand: _brand,
                              inCartQty: inCartQty,
                              onAdd: () => _addDish(p),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Checkout Dock (Matches Inspo Image 1)
      bottomBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Top notice banner + Alisin button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F2EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDE8E1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32), size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Sa device na ito naka-save ang mga benta',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A524C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_cart.isNotEmpty)
                    GestureDetector(
                      onTap: _clearCart,
                      child: const Text(
                        'Alisin',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Payment method toggle chips
              Row(
                children: <String>['Cash', '✓ GCash', 'Utang'].map((String m) {
                  final String rawName = m.replaceAll('✓ ', '');
                  final bool selected = _paymentMethod == rawName;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = rawName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1E1C1A)
                                : const Color(0xFFF7F5F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1E1C1A)
                                  : const Color(0xFFEDE8E1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              m,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF5A524C),
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Items total + Crimson Bayaran Button
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '$_itemCount ${_itemCount == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: Color(0xFF7A7269),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₱${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF1F1A17),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _showCartSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E0D8),
                        disabledForegroundColor: const Color(0xFF9E958C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Text(
                            'Bayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Dish Tile (Clean White Card matching Inspo Image 1)
// ──────────────────────────────────────────────────────────────────────────────

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.product,
    required this.brand,
    required this.inCartQty,
    required this.onAdd,
  });

  final Product product;
  final Color brand;
  final int inCartQty;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final bool isOut = product.stockQty <= 0;
    final bool isLow = product.isLowStock;
    final bool inCart = inCartQty > 0;

    IconData dishIcon = Icons.restaurant_rounded;
    final String cat = (product.categoryName ?? '').toLowerCase();
    if (cat.contains('silog')) {
      dishIcon = Icons.breakfast_dining_rounded;
    } else if (cat.contains('kanin')) {
      dishIcon = Icons.rice_bowl_rounded;
    } else if (cat.contains('gulay')) {
      dishIcon = Icons.eco_rounded;
    } else if (cat.contains('sabaw')) {
      dishIcon = Icons.soup_kitchen_rounded;
    } else if (cat.contains('inumin')) {
      dishIcon = Icons.local_drink_rounded;
    } else if (cat.contains('meryenda')) {
      dishIcon = Icons.bakery_dining_rounded;
    }

    return GestureDetector(
      onTap: isOut ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: inCart
                ? c.primary
                : isOut
                    ? c.error.withValues(alpha: 0.5)
                    : c.borderSubtle,
            width: inCart ? 1.8 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: inCart
                  ? c.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top row: Category tag + in-cart amber badge or status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product.categoryName ?? 'Ulam',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (inCart)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: c.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'x$inCartQty',
                        style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else if (isOut)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'UBOS',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else if (isLow)
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 16),
                ],
              ),
              const Spacer(),

              // Center: Food squircle icon
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(
                    dishIcon,
                    color: brand,
                    size: 26,
                  ),
                ),
              ),
              const Spacer(),

              // Dish name
              Text(
                product.name,
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price & Portions left
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '₱${product.unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isOut ? c.textTertiary : c.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    isOut ? 'Ubos na' : '${product.stockQty} natitira',
                    style: TextStyle(
                      color: isOut
                          ? const Color(0xFFDC2626)
                          : isLow
                              ? const Color(0xFFD97706)
                              : c.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Quick action button
              if (!isOut)
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          inCart ? brand : c.primary.withValues(alpha: 0.08),
                      foregroundColor: inCart ? Colors.white : brand,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color:
                              inCart ? brand : c.primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    child: Text(
                      inCart ? '+ Isa pa' : 'I-order',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Cart line row (Clean White)
// ──────────────────────────────────────────────────────────────────────────────

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.brand,
    required this.onRemove,
    required this.onAdd,
  });

  final CartLine line;
  final Color brand;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          // Qty stepper
          Row(
            children: <Widget>[
              _QtyButton(icon: Icons.remove, onTap: onRemove),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${line.quantity}',
                  style: const TextStyle(
                    color: Color(0xFF1F1A17),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _QtyButton(icon: Icons.add, onTap: onAdd),
            ],
          ),
          const SizedBox(width: 12),

          // Name & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.name,
                  style: const TextStyle(
                    color: Color(0xFF1F1A17),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₱${line.unitPrice.toStringAsFixed(2)} bawat order',
                  style: const TextStyle(
                    color: Color(0xFF7A7269),
                    fontSize: 12,
                  ),
                ),
                if (line.isCombo && line.comboItems != null)
                  Text(
                    line.comboItems!
                        .map((ComboItem i) => i.dishName)
                        .join(', '),
                    style: const TextStyle(
                      color: Color(0xFF9E958C),
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Line Total
          Text(
            '₱${line.lineTotal.toStringAsFixed(2)}',
            style: TextStyle(
              color: brand,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEDE8E1)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF1F1A17)),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tender Panel (Cash entry, preset buttons, change computation - clean white)
// ──────────────────────────────────────────────────────────────────────────────

class _TenderPanel extends StatefulWidget {
  const _TenderPanel({
    required this.total,
    required this.paymentMethod,
    required this.onCheckout,
  });

  final double total;
  final String paymentMethod;
  final void Function(double change) onCheckout;

  @override
  State<_TenderPanel> createState() => _TenderPanelState();
}

class _TenderPanelState extends State<_TenderPanel> {
  final TextEditingController _ctrl = TextEditingController();
  double? _tendered;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double get _change => _tendered != null && _tendered! >= widget.total
      ? ComboEngine.computeChange(widget.total, _tendered!)
      : 0.0;

  bool get _canCheckout =>
      widget.paymentMethod != 'Cash' ||
      (_tendered != null && _tendered! >= widget.total);

  @override
  Widget build(BuildContext context) {
    final bool isCash = widget.paymentMethod == 'Cash';

    return Container(
      color: const Color(0xFFFBF9F5),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (isCash) ...<Widget>[
            // Quick tender preset pills
            Row(
              children: <double>[50, 100, 200, 500].map((double amt) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _tendered = amt;
                          _ctrl.text = amt.toStringAsFixed(0);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: StoreColors.carinderia,
                        side: const BorderSide(
                            color: Color(0xFFDDD5CE), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        '₱${amt.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Cash input
            TextField(
              controller: _ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                color: Color(0xFF1F1A17),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '₱  ',
                prefixStyle: const TextStyle(
                  color: Color(0xFF7A7269),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                labelText: 'Ibinayad ng kostumer',
                labelStyle: const TextStyle(color: Color(0xFF7A7269)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEDE8E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: StoreColors.carinderia, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (String v) {
                setState(() => _tendered = double.tryParse(v));
              },
            ),
            if (_tendered != null && _tendered! >= widget.total) ...<Widget>[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Sukli:',
                    style: TextStyle(
                      color: Color(0xFF7A7269),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₱${_change.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
          ],

          // Big crimson checkout button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _canCheckout ? () => widget.onCheckout(_change) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreColors.carinderia,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E0D8),
                disabledForegroundColor: const Color(0xFF9E958C),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                _canCheckout
                    ? 'I-bayad  ₱${widget.total.toStringAsFixed(2)}'
                    : 'Ilagay ang sapat na bayad',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Order type chip (Dine-in / Take-out)
// ──────────────────────────────────────────────────────────────────────────────

class _OrderTypeChip extends StatelessWidget {
  const _OrderTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? StoreColors.carinderia : const Color(0xFFF7F5F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? StoreColors.carinderia : const Color(0xFFEDE8E1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF5A524C),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
