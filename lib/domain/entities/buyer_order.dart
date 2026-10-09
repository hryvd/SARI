/// buyer_order.dart
/// Pure-Dart entity classes for Buyer Kiosk mode.
/// Zero Flutter imports.
library;

class BuyerOrderItem {
  const BuyerOrderItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    this.qty = 1,
    this.addons = const <String>[],
    this.addonPrice = 0.0,
  });

  final String id;
  final String name;
  final double unitPrice;
  final int qty;
  final List<String> addons;
  final double addonPrice;

  double get itemUnitPrice => unitPrice + addonPrice;
  double get subtotal => itemUnitPrice * qty;

  BuyerOrderItem copyWith({
    String? id,
    String? name,
    double? unitPrice,
    int? qty,
    List<String>? addons,
    double? addonPrice,
  }) {
    return BuyerOrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      qty: qty ?? this.qty,
      addons: addons ?? this.addons,
      addonPrice: addonPrice ?? this.addonPrice,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'price': unitPrice,
        'qty': qty,
        'addons': addons,
        'addon_price': addonPrice,
      };

  factory BuyerOrderItem.fromMap(Map<String, dynamic> map) {
    return BuyerOrderItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Item',
      unitPrice: (map['price'] as num? ?? 0.0).toDouble(),
      qty: (map['qty'] as num? ?? 1).toInt(),
      addons: (map['addons'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      addonPrice: (map['addon_price'] as num? ?? 0.0).toDouble(),
    );
  }
}

class BuyerOrder {
  const BuyerOrder({
    required this.orderId,
    required this.storeId,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    this.notes,
  });

  final String orderId;
  final String storeId;
  final DateTime timestamp;
  final List<BuyerOrderItem> items;
  final double totalAmount;
  final String? notes;

  int get totalItemCount =>
      items.fold<int>(0, (int sum, BuyerOrderItem item) => sum + item.qty);

  BuyerOrder copyWith({
    String? orderId,
    String? storeId,
    DateTime? timestamp,
    List<BuyerOrderItem>? items,
    double? totalAmount,
    String? notes,
  }) {
    return BuyerOrder(
      orderId: orderId ?? this.orderId,
      storeId: storeId ?? this.storeId,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'v': 1,
        'order_id': orderId,
        'store_id': storeId,
        'ts': timestamp.millisecondsSinceEpoch,
        'items': items.map((BuyerOrderItem i) => i.toMap()).toList(),
        'total': totalAmount,
        if (notes != null) 'notes': notes,
      };

  factory BuyerOrder.fromMap(Map<String, dynamic> map) {
    final List<dynamic> rawItems =
        map['items'] as List<dynamic>? ?? <dynamic>[];
    return BuyerOrder(
      orderId: map['order_id'] as String? ?? '',
      storeId: map['store_id'] as String? ?? '',
      timestamp: map['ts'] != null
          ? DateTime.fromMillisecondsSinceEpoch((map['ts'] as num).toInt())
          : DateTime.now(),
      items: rawItems
          .map((dynamic item) =>
              BuyerOrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['total'] as num? ?? 0.0).toDouble(),
      notes: map['notes'] as String?,
    );
  }
}
