import 'package:flutter/material.dart';

import '../../../domain/adapters/rice_adapter.dart';
import '../../../domain/entities/product.dart';
import '../../../theme/app_theme.dart';
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
                            'Magdagdag ng Klase ng Bigas',
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
                      controller: varietyCtrl,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Pangalan ng Bigas / Variety',
                        labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                        hintText: 'e.g. Dinorado Special',
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
                    DropdownButtonFormField<String>(
                      dropdownColor: c.surface,
                      initialValue: selectedGrade,
                      style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Milling Grade',
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
                      items: <String>[
                        'Well-Milled',
                        'Regular Milled',
                        'Premium',
                        'Special / Fragrant',
                      ].map((String grade) {
                        return DropdownMenuItem<String>(
                          value: grade,
                          child: Text(grade, style: TextStyle(color: c.text)),
                        );
                      }).toList(),
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
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Presyo / Kilo (₱)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '56.00',
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
                              labelText: 'Stock (kg)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '100',
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
                            controller: sack25Ctrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: '25kg Sako (₱)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '1350',
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
                            controller: sack50Ctrl,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              labelText: '50kg Sako (₱)',
                              labelStyle: TextStyle(color: c.textSecondary, fontSize: 13),
                              hintText: '2650',
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
                  backgroundColor: appColors(context).surface,
                  foregroundColor: appColors(context).text,
                  elevation: 2,
                  onPressed: widget.onPrintLabels,
                  child: const Icon(Icons.qr_code),
                ),
                const SizedBox(width: 12),
              ],
              FloatingActionButton.extended(
                heroTag: 'add_rice',
                backgroundColor: adapter.brandColor,
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'DAGDAG BIGAS',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: _showAddDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
