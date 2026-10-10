import 'package:flutter/material.dart';

import '../../../domain/adapters/sari_sari_adapter.dart';
import '../../../domain/entities/product.dart';
import '../../../theme/app_theme.dart';
import '../shared/inventory_header.dart';
import '../shared/item_box_grid.dart';

class SariSariInventoryView extends StatefulWidget {
  const SariSariInventoryView({
    super.key,
    required this.products,
    required this.onTapProduct,
    required this.onAddProduct,
  });

  final List<Product> products;
  final void Function(Product product) onTapProduct;
  final void Function({
    required String name,
    String? alias,
    required String barcode,
    required double unitPrice,
    required double costPrice,
    required int stockQty,
    required int threshold,
    String? category,
  }) onAddProduct;

  @override
  State<SariSariInventoryView> createState() => _SariSariInventoryViewState();
}

class _SariSariInventoryViewState extends State<SariSariInventoryView> {
  static const SariSariAdapter adapter = SariSariAdapter();
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
        final bool nameMatches = p.name.toLowerCase().contains(q);
        final bool barcodeMatches =
            p.barcode != null && p.barcode!.toLowerCase().contains(q);
        final bool aliasMatches =
            p.alias != null && p.alias!.toLowerCase().contains(q);
        if (!nameMatches && !barcodeMatches && !aliasMatches) return false;
      }
      return true;
    }).toList();
  }

  void _showAddDialog() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController aliasCtrl = TextEditingController();
    final TextEditingController barcodeCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    final TextEditingController costCtrl = TextEditingController();
    final TextEditingController stockCtrl = TextEditingController();
    final TextEditingController thresholdCtrl = TextEditingController(text: '5');
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
                            'Magdagdag ng Paninda (Sari-Sari)',
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
                        labelText: 'Pangalan ng Produkto',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                        hintText: 'e.g. Piattos Cheese',
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
                    TextField(
                      controller: aliasCtrl,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Palayaw / Alias (hal. Piattos, Canton)',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                        hintText: 'Pinaikling tawag o shortcut ng suki',
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
                    TextField(
                      controller: barcodeCtrl,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                        hintText: 'I-scan o i-type ang barcode',
                        hintStyle: TextStyle(color: c.textTertiary, fontSize: 13),
                        suffixIcon: Icon(Icons.qr_code_scanner, color: adapter.brandColor),
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
                    DropdownButtonFormField<String>(
                      dropdownColor: c.surface,
                      initialValue: selectedCat,
                      style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Kategorya',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
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
                      items: adapter.defaultCategories
                          .map((String cat) => DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat, style: TextStyle(color: c.text)),
                              ))
                          .toList(),
                      onChanged: (String? val) {
                        if (val != null) setModalState(() => selectedCat = val);
                      },
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
                              labelText: 'Presyo (₱)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '0.00',
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
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Puhunan (₱)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '0.00',
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
                            controller: stockCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Bilang ng Stock',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '10',
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
                            controller: thresholdCtrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Low Stock Alert',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '5',
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
                          final double cost =
                              double.tryParse(costCtrl.text) ?? 0.0;
                          final int stock = int.tryParse(stockCtrl.text) ?? 0;
                          final int threshold =
                              int.tryParse(thresholdCtrl.text) ?? 5;
                          if (name.isEmpty) return;

                          widget.onAddProduct(
                            name: name,
                            alias: aliasCtrl.text.trim().isNotEmpty
                                ? aliasCtrl.text.trim()
                                : null,
                            barcode: barcodeCtrl.text.trim(),
                            unitPrice: price,
                            costPrice: cost,
                            stockQty: stock,
                            threshold: threshold,
                            category: selectedCat,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'I-SAVE ANG PRODUKTO',
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
                emptyMessage: 'Walang nahanap na paninda',
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
              'DAGDAG',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            onPressed: _showAddDialog,
          ),
        ),
      ],
    );
  }
}
