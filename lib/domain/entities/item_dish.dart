/// Domain entity – item_dish table.
/// No Flutter imports. Pure Dart data class.
class ItemDish {
  const ItemDish({
    required this.itemId,
    required this.price,
    this.dailyPortions = 0,
    this.portionsLeft = 0,
    this.isComboEligible = true,
    this.modifierGroupIds,
  });

  final String itemId;
  final double price;
  final int dailyPortions;
  final int portionsLeft;
  final bool isComboEligible;
  final String? modifierGroupIds;

  bool get isLowStock => portionsLeft <= 5 && portionsLeft > 0;
  bool get isOutOfStock => portionsLeft <= 0;

  ItemDish copyWith({
    String? itemId,
    double? price,
    int? dailyPortions,
    int? portionsLeft,
    bool? isComboEligible,
    String? modifierGroupIds,
  }) {
    return ItemDish(
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      dailyPortions: dailyPortions ?? this.dailyPortions,
      portionsLeft: portionsLeft ?? this.portionsLeft,
      isComboEligible: isComboEligible ?? this.isComboEligible,
      modifierGroupIds: modifierGroupIds ?? this.modifierGroupIds,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'item_id': itemId,
        'price': price,
        'daily_portions': dailyPortions,
        'portions_left': portionsLeft,
        'is_combo_eligible': isComboEligible ? 1 : 0,
        'modifier_group_ids': modifierGroupIds,
      };

  factory ItemDish.fromMap(Map<String, dynamic> m) => ItemDish(
        itemId: m['item_id'] as String,
        price: (m['price'] as num).toDouble(),
        dailyPortions: (m['daily_portions'] as int? ?? 0),
        portionsLeft: (m['portions_left'] as int? ?? 0),
        isComboEligible: (m['is_combo_eligible'] as int? ?? 1) == 1,
        modifierGroupIds: m['modifier_group_ids'] as String?,
      );
}
