import 'package:flutter/material.dart';

import '../../screens/carinderia/carinderia_pos.dart';
import '../../theme/store_theme.dart';
import '../../widgets/item_box.dart';
import '../entities/item_dish.dart';
import '../entities/product.dart';
import 'store_adapter.dart';

class CarinderiaAdapter implements StoreAdapter {
  const CarinderiaAdapter();

  @override
  StoreType get storeType => StoreType.carinderia;

  @override
  String get storeTitle => 'Carinderia';

  @override
  Color get brandColor => StoreColors.carinderia;

  @override
  bool get requiresBarcode => false; // Tap-kiosk POS

  @override
  bool get requiresWeightInput => false; // Portion-based

  @override
  bool get hasComboEngine => true; // Combo meal engine active

  @override
  List<String> get csvHeaders => const <String>[
        'dish_id',
        'dish_name',
        'category',
        'price',
        'today_prepared_portions',
        'portions_remaining',
        'combo_eligible',
      ];

  @override
  List<String> get defaultCategories => const <String>[
        'Ulam',
        'Kanin',
        'Silog',
        'Gulay',
        'Sabaw',
        'Inumin',
        'Meryenda',
      ];

  @override
  List<String> itemToCsvRow(dynamic item) {
    if (item is ItemDish) {
      return <String>[
        item.itemId,
        item.itemId,
        'Ulam',
        item.price.toStringAsFixed(2),
        item.dailyPortions.toString(),
        item.portionsLeft.toString(),
        item.isComboEligible ? 'YES' : 'NO',
      ];
    } else if (item is Map<String, dynamic>) {
      return <String>[
        item['dish_id']?.toString() ?? item['item_id']?.toString() ?? '',
        item['name']?.toString() ?? '',
        item['category']?.toString() ?? 'Ulam',
        ((item['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        (item['daily_portions'] as int? ?? 0).toString(),
        (item['portions_left'] as int? ?? 0).toString(),
        (item['is_combo_eligible'] == true || item['is_combo_eligible'] == 1)
            ? 'YES'
            : 'NO',
      ];
    } else if (item is Product) {
      return <String>[
        item.productId,
        item.name,
        item.categoryName ?? 'Ulam',
        item.unitPrice.toStringAsFixed(2),
        item.stockQty.toString(),
        item.stockQty.toString(),
        'YES',
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
    int portionsLeft = 0;
    int dailyPortions = 0;
    String? category;

    if (item is ItemDish) {
      name = item.itemId;
      price = item.price;
      portionsLeft = item.portionsLeft;
      dailyPortions = item.dailyPortions;
      category = 'Ulam';
    } else if (item is Map<String, dynamic>) {
      name = item['name']?.toString() ?? '';
      price = (item['price'] as num?)?.toDouble() ??
          (item['unit_price'] as num?)?.toDouble() ??
          0.0;
      portionsLeft = (item['portions_left'] as int?) ??
          (item['stock_qty'] as int?) ??
          0;
      dailyPortions = (item['daily_portions'] as int?) ?? portionsLeft;
      category = item['category']?.toString();
    } else if (item is Product) {
      name = item.name;
      price = item.unitPrice;
      portionsLeft = item.stockQty;
      dailyPortions = item.stockQty;
      category = item.categoryName;
    }

    final bool isOutOfStock = portionsLeft <= 0;
    final bool isLowStock = portionsLeft <= 5 && !isOutOfStock;

    final String stockLabel = isOutOfStock
        ? 'UBOS NA'
        : '$portionsLeft / $dailyPortions left';

    return ItemBox(
      name: name,
      priceLabel: '₱${price.toStringAsFixed(2)}',
      stockLabel: stockLabel,
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
        'Carinderia Add Dish Form',
        style: TextStyle(color: brandColor),
      ),
    );
  }

  @override
  Widget buildPosInterface(BuildContext context) {
    return const CarinderiaPosScreen();
  }
}
