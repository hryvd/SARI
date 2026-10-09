/// buyer_order_service.dart
/// Pure-Dart service — no Flutter imports.
/// Handles offline order payload serialization, QR string encoding,
/// and instant order decoding for the zero-cloud handoff protocol.
library;

import 'dart:convert';

import '../entities/buyer_order.dart';

class BuyerOrderService {
  BuyerOrderService._();

  static const String orderPrefix = 'SARE_ORDER:';

  /// Serializes a [BuyerOrder] into a compact JSON string, optionally prefixed.
  static String serialize(BuyerOrder order, {bool withPrefix = true}) {
    final String jsonStr = jsonEncode(order.toMap());
    return withPrefix ? '$orderPrefix$jsonStr' : jsonStr;
  }

  /// Checks whether [raw] payload is formatted as a Sar-E buyer order QR string.
  static bool isBuyerOrder(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.startsWith(orderPrefix)) return true;
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final dynamic decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          return decoded.containsKey('items') &&
              (decoded.containsKey('order_id') ||
                  decoded.containsKey('store_id') ||
                  decoded.containsKey('v'));
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Deserializes a [raw] QR string back into a [BuyerOrder].
  /// Returns null if parsing fails or data is invalid.
  static BuyerOrder? deserialize(String raw) {
    try {
      String jsonStr = raw.trim();
      if (jsonStr.startsWith(orderPrefix)) {
        jsonStr = jsonStr.substring(orderPrefix.length).trim();
      }
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) return null;

      return BuyerOrder.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Validates the calculated sum against the stated total.
  static bool validateTotal(BuyerOrder order) {
    final double calculated = order.items.fold<double>(
      0.0,
      (double sum, BuyerOrderItem item) => sum + item.subtotal,
    );
    // Allow for small floating-point tolerance (< 0.01)
    return (calculated - order.totalAmount).abs() < 0.01;
  }
}
