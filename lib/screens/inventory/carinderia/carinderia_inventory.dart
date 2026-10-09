import 'package:flutter/material.dart';

import '../../../domain/adapters/carinderia_adapter.dart';
import '../../../domain/entities/product.dart';
import '../shared/inventory_header.dart';
import '../shared/item_box_grid.dart';

class CarinderiaInventoryView extends StatefulWidget {
  const CarinderiaInventoryView({
    super.key,
    required this.products,
    required this.onTapProduct,
    required this.onAddDish,
  });

  final List<Product> products;
  final void Function(Product product) onTapProduct;
  final void Function({
    required String name,
    required String category,
    required double price,
    required int dailyPortions,
    required bool isComboEligible,
  }) onAddDish;

  @override
  State<CarinderiaInventoryView> createState() =>
      _CarinderiaInventoryViewState();
}

class _CarinderiaInventoryViewState extends State<CarinderiaInventoryView> {
  static const CarinderiaAdapter adapter = CarinderiaAdapter();
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
    final TextEditingController portionsCtrl = TextEditingController();
    String selectedCategory = adapter.defaultCategories.first;
    bool isComboEligible = true;

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
                          'Magdagdag ng Ulam / Lutuin',
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
                        labelText: 'Pangalan ng Ulam / Pagkain',
                        hintText: 'e.g. Pork Adobo, Menudo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E2228),
                      initialValue: selectedCategory,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Kategorya'),
                      items: adapter.defaultCategories
                          .map((String c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() => selectedCategory = val);
                        }
                      },
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
                              labelText: 'Presyo (₱)',
                              hintText: '55.00',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: portionsCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Lutong Portions',
                              hintText: '30',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Pang-Combo Meal (Kasama sa 1/2 Ulam)',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: isComboEligible,
                      activeThumbColor: adapter.brandColor,
                      onChanged: (bool val) {
                        setModalState(() => isComboEligible = val);
                      },
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
                          final int portions =
                              int.tryParse(portionsCtrl.text) ?? 0;
                          if (name.isEmpty) return;

                          widget.onAddDish(
                            name: name,
                            category: selectedCategory,
                            price: price,
                            dailyPortions: portions,
                            isComboEligible: isComboEligible,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'I-SAVE ANG ULAM',
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
                emptyMessage: 'Walang nahanap na ulam o pagkain',
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
            label: const Text('DAGDAG ULAM',
                style: TextStyle(color: Colors.white)),
            onPressed: _showAddDialog,
          ),
        ),
      ],
    );
  }
}
