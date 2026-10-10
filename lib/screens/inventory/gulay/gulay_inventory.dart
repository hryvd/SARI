import 'package:flutter/material.dart';

import '../../../domain/adapters/gulay_adapter.dart';
import '../../../domain/entities/product.dart';
import '../../../theme/app_theme.dart';
import '../shared/inventory_header.dart';
import '../shared/item_box_grid.dart';

class GulayInventoryView extends StatefulWidget {
  const GulayInventoryView({
    super.key,
    required this.products,
    required this.onTapProduct,
    required this.onAddGulay,
  });

  final List<Product> products;
  final void Function(Product product) onTapProduct;
  final void Function({
    required String name,
    required double pricePerKg,
    required double stockKg,
    required double lowStockKg,
    String? category,
    String? portionHint,
  }) onAddGulay;

  @override
  State<GulayInventoryView> createState() => _GulayInventoryViewState();
}

class _GulayInventoryViewState extends State<GulayInventoryView> {
  static const GulayAdapter adapter = GulayAdapter();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return widget.products.where((Product p) {
      if (_selectedCategory != null && p.categoryName != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final String q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();
  }

  void _showAddDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController();
    final TextEditingController lowStockCtrl =
        TextEditingController(text: '2.0');
    final TextEditingController portionCtrl = TextEditingController();
    String selectedCat = adapter.defaultCategories.first;
    final AppColors c = appColors(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 14,
          ),
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: c.borderSubtle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Magdagdag ng Gulay / Prutas',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: c.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Pangalan ng Gulay / Ani',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                        hintText: 'e.g. Talong (Long Purple)',
                        hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                        filled: true,
                        fillColor: c.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: adapter.brandColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Presyo bawat Kilo (₱/kg)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '75.00',
                              hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                              filled: true,
                              fillColor: c.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: c.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: adapter.brandColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Stock (Kilo)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '10.5',
                              hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                              filled: true,
                              fillColor: c.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: c.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: adapter.brandColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: lowStockCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Mababang Stock Alert (kg)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '2.0',
                              hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                              filled: true,
                              fillColor: c.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: c.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: adapter.brandColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: portionCtrl,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Pang-ulam / Recipe Hint',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: 'e.g. Pinakbet, Sinigang',
                              hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                              filled: true,
                              fillColor: c.surfaceMuted,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: c.borderSubtle),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: adapter.brandColor, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: adapter.brandColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final String name = nameCtrl.text.trim();
                          final double price =
                              double.tryParse(priceCtrl.text) ?? 0.0;
                          final double stock =
                              double.tryParse(stockCtrl.text) ?? 0.0;
                          final double lowStock =
                              double.tryParse(lowStockCtrl.text) ?? 2.0;
                          if (name.isEmpty) return;

                          widget.onAddGulay(
                            name: name,
                            pricePerKg: price,
                            stockKg: stock,
                            lowStockKg: lowStock,
                            category: selectedCat,
                            portionHint: portionCtrl.text.trim().isNotEmpty
                                ? portionCtrl.text.trim()
                                : null,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'I-SAVE ANG GULAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Product> filtered = _filteredProducts;
    final int lowStock = widget.products.where((Product p) => p.isLowStock).length;
    final int outOfStock =
        widget.products.where((Product p) => p.stockQty <= 0).length;

    return Stack(
      children: <Widget>[
        Column(
          children: <Widget>[
            InventoryHeader(
              adapter: adapter,
              searchController: _searchCtrl,
              onSearchChanged: (String q) => setState(() => _searchQuery = q),
              selectedCategory: _selectedCategory,
              onCategorySelected: (String? cat) =>
                  setState(() => _selectedCategory = cat),
              categories: adapter.defaultCategories,
              totalCount: widget.products.length,
              lowStockCount: lowStock,
              outOfStockCount: outOfStock,
            ),
            Expanded(
              child: StoreItemBoxGrid(
                items: filtered,
                adapter: adapter,
                onTapItem: (dynamic item) {
                  if (item is Product) widget.onTapProduct(item);
                },
                emptyMessage: 'Walang nahanap na gulay o prutas',
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            backgroundColor: adapter.brandColor,
            foregroundColor: Colors.white,
            elevation: 3,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'DAGDAG GULAY',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _showAddDialog,
          ),
        ),
      ],
    );
  }
}
