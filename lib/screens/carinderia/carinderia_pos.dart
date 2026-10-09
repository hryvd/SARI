import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/combo_engine.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import 'combo_builder.dart';

/// Carinderia Kiosk POS
/// Full tap-kiosk interface for ordering:
///   • Category tabs (Ulam, Kanin, Silog, etc.)
///   • Large dish tiles with portion counter
///   • Floating cart bar → checkout sheet
///   • Shortcut to ComboBuilder screen
class CarinderiaPosScreen extends ConsumerStatefulWidget {
  const CarinderiaPosScreen({super.key});

  @override
  ConsumerState<CarinderiaPosScreen> createState() =>
      _CarinderiaPosScreenState();
}

class _CarinderiaPosScreenState extends ConsumerState<CarinderiaPosScreen>
    with SingleTickerProviderStateMixin {
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

  late final TabController _tabCtrl;
  List<CartLine> _cart = <CartLine>[];
  String _orderType = 'Dine-in'; // or 'Take-out'

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── cart helpers ───────────────────────────────────────────────────────────

  double get _total => ComboEngine.cartTotal(_cart);
  int get _itemCount =>
      _cart.fold<int>(0, (int s, CartLine l) => s + l.quantity);

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

  // ── dialogs ────────────────────────────────────────────────────────────────

  void _showCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171E),
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
                return Column(
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Order type toggle
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _OrderTypeChip(
                              label: 'Dine-in 🍽️',
                              selected: _orderType == 'Dine-in',
                              onTap: () => setState(() =>
                                  _orderType = 'Dine-in'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _OrderTypeChip(
                              label: 'Take-out 📦',
                              selected: _orderType == 'Take-out',
                              onTap: () => setState(() =>
                                  _orderType = 'Take-out'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Colors.white12, height: 1),
                    // Cart lines
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Text(
                                'Walang order pa.',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 14),
                              ),
                            )
                          : ListView.builder(
                              controller: scroll,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _cart.length,
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
                    const Divider(color: Colors.white12, height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '$_orderType · $_itemCount item${_itemCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              Text(
                                '₱${_total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              _clearCart();
                              setModal(() {});
                            },
                            child: const Text('I-clear',
                                style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    ),
                    _TenderPanel(
                      total: _total,
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
    final AsyncValue<InventoryState> invAsync = ref.watch(inventoryProvider);

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
      body: Column(
        children: <Widget>[
          // Category tab bar
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: _brand,
            labelColor: _brand,
            unselectedLabelColor: Colors.white38,
            dividerColor: Colors.white12,
            padding: EdgeInsets.zero,
            tabs: _categories
                .map((String c) => Tab(text: c))
                .toList(),
          ),
          // Dish grid
          Expanded(
            child: invAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: Colors.redAccent)),
              ),
              data: (InventoryState state) => TabBarView(
                controller: _tabCtrl,
                children: _categories
                    .map((String cat) => _DishGrid(
                          products: cat == 'Lahat'
                              ? state.products
                              : state.products
                                  .where((Product p) =>
                                      (p.categoryName ?? 'Ulam') == cat)
                                  .toList(),
                          brand: _brand,
                          cartIds: _cart
                              .map((CartLine l) => l.id)
                              .toSet(),
                          onAdd: _addDish,
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCartSheet,
              backgroundColor: _brand,
              icon: const Icon(Icons.receipt_long_rounded),
              label: Text(
                '$_itemCount item${_itemCount == 1 ? '' : 's'}  ₱${_total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Dish Grid
// ──────────────────────────────────────────────────────────────────────────────

class _DishGrid extends StatelessWidget {
  const _DishGrid({
    required this.products,
    required this.brand,
    required this.cartIds,
    required this.onAdd,
  });

  final List<Product> products;
  final Color brand;
  final Set<String> cartIds;
  final void Function(Product) onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.restaurant, size: 56, color: brand.withAlpha(80)),
            const SizedBox(height: 12),
            const Text(
              'Walang putahe sa kategoryang ito.\nMag-dagdag sa Inventory.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: products.length,
      itemBuilder: (_, int i) {
        final Product p = products[i];
        return _DishTile(
          product: p,
          brand: brand,
          inCart: cartIds.contains(p.productId),
          onAdd: () => onAdd(p),
        );
      },
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({
    required this.product,
    required this.brand,
    required this.inCart,
    required this.onAdd,
  });

  final Product product;
  final Color brand;
  final bool inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bool isOut = product.stockQty <= 0;
    final bool isLow = product.isLowStock;

    Color glowColor = brand;
    if (isOut) glowColor = Colors.redAccent;
    if (isLow) glowColor = Colors.orangeAccent;

    return GestureDetector(
      onTap: isOut ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1E27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart
                ? brand
                : isOut
                    ? Colors.redAccent.withAlpha(120)
                    : Colors.white10,
            width: inCart ? 1.8 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glowColor.withAlpha(inCart ? 80 : 25),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Category chip + status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: brand.withAlpha(40),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      product.categoryName ?? 'Ulam',
                      style: TextStyle(
                          color: brand, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (inCart)
                    const Icon(Icons.check_circle,
                        color: StoreColors.carinderia, size: 16)
                  else if (isOut)
                    const Icon(Icons.cancel_outlined,
                        color: Colors.redAccent, size: 16)
                  else if (isLow)
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orangeAccent, size: 16),
                ],
              ),
              const SizedBox(height: 10),
              // Dish icon
              const Icon(Icons.dining, color: Colors.white12, size: 30),
              const SizedBox(height: 8),
              // Name
              Text(
                product.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              // Price
              Text(
                '₱${product.unitPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isOut ? Colors.white38 : brand,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Portions left
              Text(
                isOut
                    ? 'UBOS NA'
                    : isLow
                        ? '${product.stockQty} natitira ⚠️'
                        : '${product.stockQty} portions',
                style: TextStyle(
                  color: isOut
                      ? Colors.redAccent
                      : isLow
                          ? Colors.orangeAccent
                          : Colors.white38,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              // Add button
              if (!isOut)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAdd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          inCart ? brand : brand.withAlpha(50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      inCart ? '+ Isa pa' : 'I-order',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
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
// Cart line row
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          // Qty stepper
          Row(
            children: <Widget>[
              _QtyButton(icon: Icons.remove, onTap: onRemove),
              const SizedBox(width: 6),
              Text(
                '${line.quantity}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(width: 6),
              _QtyButton(icon: Icons.add, onTap: onAdd),
            ],
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  line.name,
                  style: TextStyle(
                    color: line.isCombo ? brand : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (line.isCombo)
                  Text(
                    line.comboItems
                            ?.map((ComboItem i) => i.dishName)
                            .join(', ') ??
                        '',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Total
          Text(
            '₱${line.lineTotal.toStringAsFixed(2)}',
            style: TextStyle(
              color: brand,
              fontWeight: FontWeight.bold,
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
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Tender Panel (cash entry + change computation)
// ──────────────────────────────────────────────────────────────────────────────

class _TenderPanel extends StatefulWidget {
  const _TenderPanel({required this.total, required this.onCheckout});
  final double total;
  final void Function(double change) onCheckout;

  @override
  State<_TenderPanel> createState() => _TenderPanelState();
}

class _TenderPanelState extends State<_TenderPanel> {
  final TextEditingController _ctrl = TextEditingController();
  double? _tendered;

  double get _change =>
      _tendered != null && _tendered! >= widget.total
          ? ComboEngine.computeChange(widget.total, _tendered!)
          : 0.0;

  bool get _canCheckout =>
      _tendered != null && _tendered! >= widget.total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1117),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Quick tender presets
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
                      foregroundColor: StoreColors.carinderia,
                      side: const BorderSide(
                          color: StoreColors.carinderia, width: 0.8),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      '₱${amt.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              prefixText: '₱  ',
              prefixStyle:
                  const TextStyle(color: Colors.white54, fontSize: 18),
              labelText: 'Ibinayad',
              labelStyle: const TextStyle(color: Colors.white38),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: StoreColors.carinderia),
              ),
              filled: true,
              fillColor: Colors.white.withAlpha(13),
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
                const Text('Sukli:',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                Text(
                  '₱${_change.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canCheckout
                  ? () => widget.onCheckout(_change)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: StoreColors.carinderia,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(
                _canCheckout
                    ? 'I-bayad  ₱${widget.total.toStringAsFixed(2)}'
                    : 'Ilagay ang bayad',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Order type chip
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? StoreColors.carinderia
              : Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? StoreColors.carinderia
                : Colors.white24,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white60,
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
