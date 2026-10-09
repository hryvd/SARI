import 'package:flutter/material.dart';

import '../../../domain/adapters/gulay_adapter.dart';
import '../../../domain/entities/product.dart';
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

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: StatefulBuilder(
            builder: (BuildContext ctx, StateSetter setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Magdagdag ng Gulay / Prutas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Pangalan ng Gulay / Ani',
                        hintText: 'e.g. Talong (Long Purple)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: priceCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Presyo bawat Kilo (₱/kg)',
                              hintText: '75.00',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Stock (Kilo)',
                              hintText: '10.5',
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
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Mababang Stock Alert (kg)',
                              hintText: '2.0',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: portionCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Pang-ulam / Recipe Hint',
                              hintText: 'e.g. Pinakbet, Sinigang',
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('DAGDAG GULAY',
                style: TextStyle(color: Colors.white)),
            onPressed: _showAddDialog,
          ),
        ),
      ],
    );
  }
}
