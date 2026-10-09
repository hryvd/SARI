/// Domain entity – item_rice table.
/// No Flutter imports. Pure Dart data class.
class ItemRice {
  const ItemRice({
    required this.itemId,
    required this.variety,
    this.millingGrade = 'Well-Milled',
    required this.pricePerKg,
    this.sackPrice25kg,
    this.sackPrice50kg,
    this.stockKg = 0.0,
    this.lowStockKg = 25.0,
    required this.qrPayload,
  });

  final String itemId;
  final String variety;
  final String millingGrade;
  final double pricePerKg;
  final double? sackPrice25kg;
  final double? sackPrice50kg;
  final double stockKg;
  final double lowStockKg;
  final String qrPayload;

  bool get isLowStock => stockKg <= lowStockKg && stockKg > 0.0;
  bool get isOutOfStock => stockKg <= 0.0;

  double computePrice(double weightKg) {
    return double.parse((weightKg * pricePerKg).toStringAsFixed(2));
  }

  ItemRice copyWith({
    String? itemId,
    String? variety,
    String? millingGrade,
    double? pricePerKg,
    double? sackPrice25kg,
    double? sackPrice50kg,
    double? stockKg,
    double? lowStockKg,
    String? qrPayload,
  }) {
    return ItemRice(
      itemId: itemId ?? this.itemId,
      variety: variety ?? this.variety,
      millingGrade: millingGrade ?? this.millingGrade,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      sackPrice25kg: sackPrice25kg ?? this.sackPrice25kg,
      sackPrice50kg: sackPrice50kg ?? this.sackPrice50kg,
      stockKg: stockKg ?? this.stockKg,
      lowStockKg: lowStockKg ?? this.lowStockKg,
      qrPayload: qrPayload ?? this.qrPayload,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'item_id': itemId,
        'variety': variety,
        'milling_grade': millingGrade,
        'price_per_kg': pricePerKg,
        'sack_price_25kg': sackPrice25kg,
        'sack_price_50kg': sackPrice50kg,
        'stock_kg': stockKg,
        'low_stock_kg': lowStockKg,
        'qr_payload': qrPayload,
      };

  factory ItemRice.fromMap(Map<String, dynamic> m) => ItemRice(
        itemId: m['item_id'] as String,
        variety: m['variety'] as String,
        millingGrade: m['milling_grade'] as String? ?? 'Well-Milled',
        pricePerKg: (m['price_per_kg'] as num).toDouble(),
        sackPrice25kg: (m['sack_price_25kg'] as num?)?.toDouble(),
        sackPrice50kg: (m['sack_price_50kg'] as num?)?.toDouble(),
        stockKg: (m['stock_kg'] as num? ?? 0.0).toDouble(),
        lowStockKg: (m['low_stock_kg'] as num? ?? 25.0).toDouble(),
        qrPayload: m['qr_payload'] as String? ?? '',
      );
}
