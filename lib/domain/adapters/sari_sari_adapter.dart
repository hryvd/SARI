import 'package:flutter/material.dart';

import '../../screens/scanner_screen.dart';
import '../../theme/store_theme.dart';
import '../../widgets/item_box.dart';
import '../entities/product.dart';
import 'store_adapter.dart';

class SariSariAdapter implements StoreAdapter {
  const SariSariAdapter();

  @override
  StoreType get storeType => StoreType.sariSari;

  @override
  String get storeTitle => 'Sari-Sari Store';

  @override
  Color get brandColor => StoreColors.sariSari;

  @override
  bool get requiresBarcode => true;

  @override
  bool get requiresWeightInput => false;

  @override
  bool get hasComboEngine => false;

  @override
  List<String> get csvHeaders => const <String>[
        'product_id',
        'name',
        'category',
        'barcode',
        'unit_price',
        'cost_price',
        'stock_qty',
        'threshold',
        'status',
      ];

  @override
  List<String> get defaultCategories => const <String>[
        'Beverages',
        'Snacks',
        'Canned Goods',
        'Instant Noodles',
        'Condiments',
        'Dairy & Eggs',
        'Personal Care',
        'Household',
        'Tobacco',
        'Alcohol',
        'Other',
      ];

  @override
  List<String> itemToCsvRow(dynamic item) {
    if (item is Product) {
      final String status = item.stockQty <= 0
          ? 'UBOS NA'
          : (item.isLowStock ? 'LOW STOCK' : 'IN STOCK');
      return <String>[
        item.productId,
        item.name,
        item.categoryName ?? 'Other',
        item.barcode ?? '',
        item.unitPrice.toStringAsFixed(2),
        item.costPrice.toStringAsFixed(2),
        item.stockQty.toString(),
        item.threshold.toString(),
        status,
      ];
    } else if (item is Map<String, dynamic>) {
      final int stock = (item['stock_qty'] as int? ?? 0);
      final int threshold = (item['threshold'] as int? ?? 0);
      final String status = stock <= 0
          ? 'UBOS NA'
          : (stock <= threshold ? 'LOW STOCK' : 'IN STOCK');
      return <String>[
        item['product_id']?.toString() ?? '',
        item['name']?.toString() ?? '',
        item['category']?.toString() ?? 'Other',
        item['barcode']?.toString() ?? '',
        ((item['unit_price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        ((item['cost_price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        stock.toString(),
        threshold.toString(),
        status,
      ];
    }
    return <String>[];
  }

  @override
  Widget buildInventoryBox(
    dynamic item,
    VoidCallback onTap,
    BuildContext context,
  ) {
    String name = '';
    double price = 0.0;
    int stock = 0;
    int threshold = 0;
    String? category;

    if (item is Product) {
      name = item.name;
      price = item.unitPrice;
      stock = item.stockQty;
      threshold = item.threshold;
      category = item.categoryName;
    } else if (item is Map<String, dynamic>) {
      name = item['name']?.toString() ?? '';
      price = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
      stock = item['stock_qty'] as int? ?? 0;
      threshold = item['threshold'] as int? ?? 0;
      category = item['category']?.toString();
    }

    final bool isOutOfStock = stock <= 0;
    final bool isLowStock = stock <= threshold && !isOutOfStock;

    return ItemBox(
      name: name,
      priceLabel: '₱${price.toStringAsFixed(2)}',
      stockLabel: '$stock pcs',
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      categoryLabel: category,
      accentColor: brandColor,
      onTap: onTap,
    );
  }

  @override
  Widget buildAddForm(BuildContext context) {
    return Center(
      child: Text(
        'Sari-Sari Add Item Form',
        style: TextStyle(color: brandColor),
      ),
    );
  }

  @override
  Widget buildPosInterface(BuildContext context) {
    return const ScannerScreen();
  }
}
