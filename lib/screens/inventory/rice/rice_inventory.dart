import 'package:flutter/material.dart';

import '../../../domain/adapters/rice_adapter.dart';
import '../../../domain/entities/product.dart';
import '../shared/inventory_header.dart';
import '../shared/item_box_grid.dart';

class RiceInventoryView extends StatefulWidget {
  const RiceInventoryView({
    super.key,
    required this.products,
    required this.onTapProduct,
    required this.onAddRice,
    this.onPrintLabels,
  });

  final List<Product> products;
  final void Function(Product product) onTapProduct;
  final void Function({
    required String variety,
    required String millingGrade,
    required double pricePerKg,
    double? sackPrice25kg,
    double? sackPrice50kg,
    required double stockKg,
  }) onAddRice;
  final VoidCallback? onPrintLabels;

  @override
  State<RiceInventoryView> createState() => _RiceInventoryViewState();
}

class _RiceInventoryViewState extends State<RiceInventoryView> {
  static const RiceAdapter adapter = RiceAdapter();
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
    final TextEditingController varietyCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController sack25Ctrl = TextEditingController();
    final TextEditingController sack50Ctrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController();
    String selectedGrade = 'Well-Milled';

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
                          'Magdagdag ng Klase ng Bigas',
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
                      controller: varietyCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Pangalan ng Bigas / Variety',
                        hintText: 'e.g. Dinorado Special',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E2228),
                      initialValue: selectedGrade,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Milling Grade',
                      ),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem<String>(
                            value: 'Well-Milled', child: Text('Well-Milled')),
                        DropdownMenuItem<String>(
                            value: 'Regular Milled', child: Text('Regular Milled')),
                        DropdownMenuItem<String>(
                            value: 'Premium', child: Text('Premium')),
                        DropdownMenuItem<String>(
                            value: 'Special / Fragrant', child: Text('Special / Fragrant')),
                      ],
                      onChanged: (String? val) {
                        if (val != null) {
                          setModalState(() => selectedGrade = val);
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
                              labelText: 'Presyo / Kilo (₱)',
                              hintText: '56.00',
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
                              labelText: 'Stock (kg)',
                              hintText: '100',
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
                            controller: sack25Ctrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: '25kg Sako (₱)',
                              hintText: '1350',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: sack50Ctrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: '50kg Sako (₱)',
                              hintText: '2650',
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
                          final String variety = varietyCtrl.text.trim();
                          final double price =
                              double.tryParse(priceCtrl.text) ?? 0.0;
                          final double stock =
                              double.tryParse(stockCtrl.text) ?? 0.0;
                          final double? s25 =
                              double.tryParse(sack25Ctrl.text);
                          final double? s50 =
                              double.tryParse(sack50Ctrl.text);
                          if (variety.isEmpty) return;

                          widget.onAddRice(
                            variety: variety,
                            millingGrade: selectedGrade,
                            pricePerKg: price,
                            sackPrice25kg: s25,
                            sackPrice50kg: s50,
                            stockKg: stock,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'I-SAVE ANG BIGAS',
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
                emptyMessage: 'Walang nahanap na bigas',
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.onPrintLabels != null) ...<Widget>[
                FloatingActionButton(
                  heroTag: 'print_labels',
                  backgroundColor: const Color(0xFF2D333B),
                  onPressed: widget.onPrintLabels,
                  child: const Icon(Icons.qr_code, color: Colors.white),
                ),
                const SizedBox(width: 12),
              ],
              FloatingActionButton.extended(
                heroTag: 'add_rice',
                backgroundColor: adapter.brandColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('DAGDAG BIGAS',
                    style: TextStyle(color: Colors.white)),
                onPressed: _showAddDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
