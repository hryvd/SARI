/// Domain entity – item_gulay table.
/// No Flutter imports. Pure Dart data class.
class ItemGulay {
  const ItemGulay({
    required this.itemId,
    required this.pricePerKg,
    this.stockKg = 0.0,
    this.lowStockKg = 2.0,
    this.portionHintRecipe,
    this.portionServingsPerKg = 4.0,
  });

  final String itemId;
  final double pricePerKg;
  final double stockKg;
  final double lowStockKg;
  final String? portionHintRecipe;
  final double portionServingsPerKg;

  bool get isLowStock => stockKg <= lowStockKg && stockKg > 0.0;
  bool get isOutOfStock => stockKg <= 0.0;

  double computePrice(double weightKg) {
    // Round to 2 decimal places to avoid floating point inaccuracies
    return double.parse((weightKg * pricePerKg).toStringAsFixed(2));
  }

  ItemGulay copyWith({
    String? itemId,
    double? pricePerKg,
    double? stockKg,
    double? lowStockKg,
    String? portionHintRecipe,
    double? portionServingsPerKg,
  }) {
    return ItemGulay(
      itemId: itemId ?? this.itemId,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      stockKg: stockKg ?? this.stockKg,
      lowStockKg: lowStockKg ?? this.lowStockKg,
      portionHintRecipe: portionHintRecipe ?? this.portionHintRecipe,
      portionServingsPerKg:
          portionServingsPerKg ?? this.portionServingsPerKg,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'item_id': itemId,
        'price_per_kg': pricePerKg,
        'stock_kg': stockKg,
        'low_stock_kg': lowStockKg,
        'portion_hint_recipe': portionHintRecipe,
        'portion_servings_per_kg': portionServingsPerKg,
      };

  factory ItemGulay.fromMap(Map<String, dynamic> m) => ItemGulay(
        itemId: m['item_id'] as String,
        pricePerKg: (m['price_per_kg'] as num).toDouble(),
        stockKg: (m['stock_kg'] as num? ?? 0.0).toDouble(),
        lowStockKg: (m['low_stock_kg'] as num? ?? 2.0).toDouble(),
        portionHintRecipe: m['portion_hint_recipe'] as String?,
        portionServingsPerKg:
            (m['portion_servings_per_kg'] as num? ?? 4.0).toDouble(),
      );
}
