import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/scale_calculator.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import 'qr_label_preview.dart';

/// Bigasan Bin POS Screen
/// Allows cashier to:
///   1. Browse all rice varieties (bin tiles)
///   2. Tap a bin tile → weight input dialog → adds to cart
///   3. Sack quick-select (25kg / 50kg) per variety
///   4. View running total, check out
///   5. Navigate to QR label print screen
class RicePosScreen extends ConsumerStatefulWidget {
  const RicePosScreen({super.key});

  @override
  ConsumerState<RicePosScreen> createState() => _RicePosScreenState();
}

class _RicePosScreenState extends ConsumerState<RicePosScreen> {
  static const Color _brand = StoreColors.rice;

  // Cart: key → {item, weightKg, total, label}
  final Map<String, Map<String, dynamic>> _cart =
      <String, Map<String, dynamic>>{};

  double get _cartTotal => _cart.values.fold<double>(
        0.0,
        (double sum, Map<String, dynamic> e) => sum + (e['total'] as double),
      );

  // ── helpers ────────────────────────────────────────────────────────────────

  void _addToCart(Product item, double weightKg, String label) {
    setState(() {
      final String key = '${item.productId}_$label';
      final double total =
          ScaleCalculator.computePrice(weightKg: weightKg, pricePerKg: item.unitPrice);
      _cart[key] = <String, dynamic>{
        'item': item,
        'weightKg': weightKg,
        'total': total,
        'label': label,
      };
    });
  }

  void _removeFromCart(String key) => setState(() => _cart.remove(key));

  void _clearCart() => setState(() => _cart.clear());

  // ── dialogs ────────────────────────────────────────────────────────────────

  void _openWeightDialog(Product item) {
    double weight = 1.0;
    final TextEditingController ctrl = TextEditingController(text: '1.0');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2330),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            final double computed = ScaleCalculator.computePrice(
              weightKg: weight,
              pricePerKg: item.unitPrice,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              item.categoryName ?? 'Well-Milled',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _brand.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _brand.withOpacity(0.4)),
                        ),
                        child: Text(
                          '₱${item.unitPrice.toStringAsFixed(2)}/kg',
                          style: TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Kilo weight presets
                  Text(
                    'PER KILO',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <double>[1.0, 2.0, 3.0, 5.0, 10.0, 25.0]
                        .map((double w) => _WeightChip(
                              kg: w,
                              selected: weight == w,
                              onTap: () => setState(() {
                                weight = w;
                                ctrl.text = w.toString();
                              }),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Custom kg input
                  TextField(
                    controller: ctrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                    decoration: InputDecoration(
                      labelText: 'Custom kg',
                      labelStyle: const TextStyle(color: Colors.white54),
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: _brand),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: _brand),
                      ),
                      fillColor: Colors.white.withOpacity(0.05),
                      filled: true,
                    ),
                    onChanged: (String v) {
                      final double? parsed = double.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(() => weight = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  // Total display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _brand.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: <Widget>[
                        Text(
                          '${weight.toStringAsFixed(2)} kg × ₱${item.unitPrice.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${computed.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _brand,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _addToCart(item, weight, '${weight.toStringAsFixed(2)} kg');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        'Add  ₱${computed.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCartSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16202E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (_, ScrollController scroll) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Listahan ng Order',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _clearCart();
                              Navigator.pop(ctx);
                            },
                            child: const Text(
                              'I-clear',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white12),
                      Expanded(
                        child: ListView(
                          controller: scroll,
                          children: _cart.entries.map((MapEntry<String, Map<String, dynamic>> e) {
                            final Product item = e.value['item'] as Product;
                            final double total = e.value['total'] as double;
                            final String label = e.value['label'] as String;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                label,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    '₱${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: _brand,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () {
                                      _removeFromCart(e.key);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'KABUUAN',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '₱${_cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _cart.isEmpty
                              ? null
                              : () {
                                  _clearCart();
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Bayad natanggap!'),
                                      backgroundColor: Color(0xFF2E7D32),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: Text(
                            'I-bayad  ₱${_cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
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
    final AsyncValue<InventoryState> invAsync = ref.watch(inventoryProvider);

    return StoreScaffold(
      storeType: StoreType.rice,
      headerTitle: 'Bigasan POS',
      headerActions: <Widget>[
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          tooltip: 'Print QR Labels',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const QrLabelPreviewScreen(),
            ),
          ),
        ),
      ],
      body: invAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (InventoryState state) => _buildBinGrid(state),
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCartSheet,
              backgroundColor: _brand,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                '${_cart.length} item${_cart.length == 1 ? '' : 's'}  ₱${_cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBinGrid(InventoryState state) {
    final List<Product> items = state.products;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.rice_bowl_outlined, size: 64, color: _brand.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Walang bigas na naka-set up.\nMag-dagdag sa Inventory muna.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext ctx, int index) {
        return _BinTile(
          item: items[index],
          binNumber: index + 1,
          inCart: _cart.keys.any((String k) => k.startsWith(items[index].productId)),
          onTap: () => _openWeightDialog(items[index]),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bin Tile
// ──────────────────────────────────────────────────────────────────────────────

class _BinTile extends StatelessWidget {
  const _BinTile({
    required this.item,
    required this.binNumber,
    required this.inCart,
    required this.onTap,
  });

  final Product item;
  final int binNumber;
  final bool inCart;
  final VoidCallback onTap;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    final bool isOut = item.stockQty <= 0;
    final bool isLow = item.isLowStock;

    Color glowColor = _brand;
    if (isOut) glowColor = Colors.redAccent;
    if (isLow) glowColor = Colors.orangeAccent;

    return GestureDetector(
      onTap: isOut ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2236),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart
                ? _brand
                : isOut
                    ? Colors.redAccent.withOpacity(0.5)
                    : Colors.white10,
            width: inCart ? 1.8 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: glowColor.withOpacity(inCart ? 0.35 : 0.12),
              blurRadius: 14,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Bin badge + stock status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _brand.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BIN #$binNumber',
                      style: const TextStyle(
                        color: StoreColors.rice,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (isOut)
                    const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18)
                  else if (isLow)
                    const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 18)
                  else if (inCart)
                    const Icon(Icons.check_circle, color: StoreColors.rice, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              // Rice sack icon
              const Icon(Icons.rice_bowl, color: Colors.white24, size: 32),
              const SizedBox(height: 8),
              // Variety name
              Text(
                item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                item.categoryName ?? 'Well-Milled',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
              const Spacer(),
              // Price
              Text(
                '₱${item.unitPrice.toStringAsFixed(2)}/kg',
                style: TextStyle(
                  color: isOut ? Colors.white38 : _brand,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              // Stock
              Text(
                isOut
                    ? 'UBOS NA'
                    : '${item.stockQty} natitira',
                style: TextStyle(
                  color: isOut ? Colors.redAccent : Colors.white38,
                  fontSize: 11,
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
// Weight Chip & Sack Chip
// ──────────────────────────────────────────────────────────────────────────────

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.kg,
    required this.selected,
    required this.onTap,
  });

  final double kg;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? StoreColors.rice
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? StoreColors.rice : Colors.white24,
          ),
        ),
        child: Text(
          '${kg % 1 == 0 ? kg.toInt() : kg} kg',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
