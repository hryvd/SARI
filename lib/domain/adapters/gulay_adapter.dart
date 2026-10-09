import 'package:flutter/material.dart';

import '../../screens/gulay/gulay_pos.dart';
import '../../theme/store_theme.dart';
import '../../widgets/item_box.dart';
import '../entities/item_gulay.dart';
import '../entities/product.dart';
import 'store_adapter.dart';

class GulayAdapter implements StoreAdapter {
  const GulayAdapter();

  @override
  StoreType get storeType => StoreType.gulay;

  @override
  String get storeTitle => 'Gulay / Palengke';

  @override
  Color get brandColor => StoreColors.gulay;

  @override
  bool get requiresBarcode => false; // Fresh produce does NOT require barcode

  @override
  bool get requiresWeightInput => true; // Scale-based pricing

  @override
  bool get hasComboEngine => false;

  @override
  List<String> get csvHeaders => const <String>[
        'item_id',
        'produce_name',
        'category',
        'price_per_kg',
        'current_stock_kg',
        'low_stock_threshold_kg',
        'status',
      ];

  @override
  List<String> get defaultCategories => const <String>[
        'Gulay',
        'Prutas',
        'Pampalasa',
        'Dahon',
        'Ugat',
        'Bawas-Presyo',
      ];

  @override
  List<String> itemToCsvRow(dynamic item) {
    if (item is ItemGulay) {
      final String status = item.isOutOfStock
          ? 'UBOS NA'
          : (item.isLowStock ? 'LOW STOCK' : 'IN STOCK');
      return <String>[
        item.itemId,
        item.itemId,
        'Gulay',
        item.pricePerKg.toStringAsFixed(2),
        item.stockKg.toStringAsFixed(2),
        item.lowStockKg.toStringAsFixed(2),
        status,
      ];
    } else if (item is Map<String, dynamic>) {
      final double stock = (item['stock_kg'] as num?)?.toDouble() ?? 0.0;
      final double low = (item['low_stock_kg'] as num?)?.toDouble() ?? 2.0;
      final String status = stock <= 0.0
          ? 'UBOS NA'
          : (stock <= low ? 'LOW STOCK' : 'IN STOCK');
      return <String>[
        item['item_id']?.toString() ?? '',
        item['name']?.toString() ?? '',
        item['category']?.toString() ?? 'Gulay',
        ((item['price_per_kg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        stock.toStringAsFixed(2),
        low.toStringAsFixed(2),
        status,
      ];
    } else if (item is Product) {
      final String status = item.stockQty <= 0
          ? 'UBOS NA'
          : (item.isLowStock ? 'LOW STOCK' : 'IN STOCK');
      return <String>[
        item.productId,
        item.name,
        item.categoryName ?? 'Gulay',
        item.unitPrice.toStringAsFixed(2),
        item.stockQty.toDouble().toStringAsFixed(2),
        item.threshold.toDouble().toStringAsFixed(2),
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
    double pricePerKg = 0.0;
    double stockKg = 0.0;
    double lowStockKg = 2.0;
    String? category;

    if (item is ItemGulay) {
      name = item.itemId;
      pricePerKg = item.pricePerKg;
      stockKg = item.stockKg;
      lowStockKg = item.lowStockKg;
      category = 'Gulay';
    } else if (item is Map<String, dynamic>) {
      name = item['name']?.toString() ?? '';
      pricePerKg = (item['price_per_kg'] as num?)?.toDouble() ??
          (item['unit_price'] as num?)?.toDouble() ??
          0.0;
      stockKg = (item['stock_kg'] as num?)?.toDouble() ??
          (item['stock_qty'] as num?)?.toDouble() ??
          0.0;
      lowStockKg = (item['low_stock_kg'] as num?)?.toDouble() ??
          (item['threshold'] as num?)?.toDouble() ??
          2.0;
      category = item['category']?.toString();
    } else if (item is Product) {
      name = item.name;
      pricePerKg = item.unitPrice;
      stockKg = item.stockQty.toDouble();
      lowStockKg = item.threshold.toDouble();
      category = item.categoryName;
    }

    final bool isOutOfStock = stockKg <= 0.0;
    final bool isLowStock = stockKg <= lowStockKg && !isOutOfStock;

    return ItemBox(
      name: name,
      priceLabel: '₱${pricePerKg.toStringAsFixed(2)} / kg',
      stockLabel: '${stockKg.toStringAsFixed(1)} kg',
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
        'Gulay Add Item Form (No Barcode)',
        style: TextStyle(color: brandColor),
      ),
    );
  }

  @override
  Widget buildPosInterface(BuildContext context) {
    return const GulayPosScreen();
  }
}
