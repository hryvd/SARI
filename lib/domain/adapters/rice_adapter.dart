import 'package:flutter/material.dart';

import '../../screens/rice/rice_pos.dart';
import '../../theme/store_theme.dart';
import '../../widgets/item_box.dart';
import '../entities/item_rice.dart';
import '../entities/product.dart';
import 'store_adapter.dart';

class RiceAdapter implements StoreAdapter {
  const RiceAdapter();

  @override
  StoreType get storeType => StoreType.rice;

  @override
  String get storeTitle => 'Bigasan / Rice Store';

  @override
  Color get brandColor => StoreColors.rice;

  @override
  bool get requiresBarcode => true; // Uses QR bin stickers

  @override
  bool get requiresWeightInput => true; // Sold per kilo or per sack

  @override
  bool get hasComboEngine => false;

  @override
  List<String> get csvHeaders => const <String>[
        'item_id',
        'variety_name',
        'milling_grade',
        'price_per_kg',
        'price_sack_25kg',
        'price_sack_50kg',
        'stock_kg',
        'qr_code',
      ];

  @override
  List<String> get defaultCategories => const <String>[
        'Well-Milled',
        'Regular Milled',
        'Premium',
        'Special / Fragrant',
        'Glutinous (Malagkit)',
        'Brown / Red Rice',
      ];

  @override
  List<String> itemToCsvRow(dynamic item) {
    if (item is ItemRice) {
      return <String>[
        item.itemId,
        item.variety,
        item.millingGrade,
        item.pricePerKg.toStringAsFixed(2),
        item.sackPrice25kg?.toStringAsFixed(2) ?? '',
        item.sackPrice50kg?.toStringAsFixed(2) ?? '',
        item.stockKg.toStringAsFixed(1),
        item.qrPayload,
      ];
    } else if (item is Map<String, dynamic>) {
      return <String>[
        item['item_id']?.toString() ?? '',
        item['variety']?.toString() ?? item['name']?.toString() ?? '',
        item['milling_grade']?.toString() ?? 'Well-Milled',
        ((item['price_per_kg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        ((item['sack_price_25kg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        ((item['sack_price_50kg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
        ((item['stock_kg'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1),
        item['qr_payload']?.toString() ?? '',
      ];
    } else if (item is Product) {
      return <String>[
        item.productId,
        item.name,
        item.categoryName ?? 'Well-Milled',
        item.unitPrice.toStringAsFixed(2),
        '',
        '',
        item.stockQty.toDouble().toStringAsFixed(1),
        item.barcode ?? '',
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
    double lowStockKg = 25.0;
    String? grade;

    if (item is ItemRice) {
      name = item.variety;
      pricePerKg = item.pricePerKg;
      stockKg = item.stockKg;
      lowStockKg = item.lowStockKg;
      grade = item.millingGrade;
    } else if (item is Map<String, dynamic>) {
      name = item['variety']?.toString() ?? item['name']?.toString() ?? '';
      pricePerKg = (item['price_per_kg'] as num?)?.toDouble() ??
          (item['unit_price'] as num?)?.toDouble() ??
          0.0;
      stockKg = (item['stock_kg'] as num?)?.toDouble() ??
          (item['stock_qty'] as num?)?.toDouble() ??
          0.0;
      lowStockKg = (item['low_stock_kg'] as num?)?.toDouble() ?? 25.0;
      grade = item['milling_grade']?.toString() ?? item['category']?.toString();
    } else if (item is Product) {
      name = item.name;
      pricePerKg = item.unitPrice;
      stockKg = item.stockQty.toDouble();
      lowStockKg = item.threshold.toDouble();
      grade = item.categoryName;
    }

    final bool isOutOfStock = stockKg <= 0.0;
    final bool isLowStock = stockKg <= lowStockKg && !isOutOfStock;

    return ItemBox(
      name: name,
      priceLabel: '₱${pricePerKg.toStringAsFixed(2)} / kg',
      stockLabel: '${stockKg.toStringAsFixed(1)} kg',
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
      categoryLabel: grade,
      accentColor: brandColor,
      onTap: onTap,
    );
  }

  @override
  Widget buildAddForm(BuildContext context) {
    return Center(
      child: Text(
        'Rice Add Variety Form',
        style: TextStyle(color: brandColor),
      ),
    );
  }

  @override
  Widget buildPosInterface(BuildContext context) {
    return const RicePosScreen();
  }
}

