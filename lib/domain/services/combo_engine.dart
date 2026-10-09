/// combo_engine.dart
/// Pure-Dart service — no Flutter imports.
/// Manages combo meal definitions and discount computation for Carinderia.
///
/// A ComboMeal is a named bundle of dishes sold at a flat discounted price.
/// The engine validates combo eligibility and computes savings vs. à la carte.
library;

/// A single item in a combo.
class ComboItem {
  const ComboItem({
    required this.dishId,
    required this.dishName,
    required this.alaCartePrice,
    this.quantity = 1,
  });

  final String dishId;
  final String dishName;
  final double alaCartePrice;
  final int quantity;

  double get lineTotal => alaCartePrice * quantity;
}

/// A named combo meal definition.
class ComboMeal {
  const ComboMeal({
    required this.comboId,
    required this.name,
    required this.items,
    required this.comboPrice,
    this.imagePath,
    this.category = 'Combo',
  });

  final String comboId;
  final String name;
  final List<ComboItem> items;
  final double comboPrice;
  final String? imagePath;
  final String category;

  /// Total à la carte price if bought separately.
  double get alaCarteTotal =>
      items.fold<double>(0.0, (double s, ComboItem i) => s + i.lineTotal);

  /// Savings vs buying à la carte.
  double get savings =>
      double.parse((alaCarteTotal - comboPrice).toStringAsFixed(2));

  /// Savings as a percentage (0-100).
  double get savingsPct =>
      alaCarteTotal > 0 ? (savings / alaCarteTotal * 100) : 0.0;

  /// Human-readable savings label e.g. "Makatipid ₱15.00 (18%)"
  String get savingsLabel =>
      savings > 0
          ? 'Makatipid ₱${savings.toStringAsFixed(2)} (${savingsPct.toStringAsFixed(0)}%)'
          : 'Combo Price';
}

/// Cart line item for the carinderia POS.
class CartLine {
  CartLine({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.category,
    this.quantity = 1,
    this.isCombo = false,
    this.comboItems,
  });

  final String id;
  final String name;
  final double unitPrice;
  final String category;
  int quantity;
  final bool isCombo;
  final List<ComboItem>? comboItems;

  double get lineTotal =>
      double.parse((unitPrice * quantity).toStringAsFixed(2));
}

/// ComboEngine: stateless utility for combo operations.
class ComboEngine {
  ComboEngine._();

  // ─── Built-in Silog combos ─────────────────────────────────────────────────

  /// Generates the standard silog combo variants for quick setup.
  /// Prices are sample defaults; the store owner overrides per-store.
  static List<ComboMeal> defaultSilogCombos() => <ComboMeal>[
        const ComboMeal(
          comboId: 'combo_tapsilog',
          name: 'Tapsilog',
          category: 'Silog',
          comboPrice: 79.0,
          items: <ComboItem>[
            ComboItem(
              dishId: 'tapa',
              dishName: 'Tapa',
              alaCartePrice: 50.0,
            ),
            ComboItem(
              dishId: 'sinangag',
              dishName: 'Sinangag',
              alaCartePrice: 20.0,
            ),
            ComboItem(
              dishId: 'itlog',
              dishName: 'Itlog (Pritong)',
              alaCartePrice: 15.0,
            ),
          ],
        ),
        const ComboMeal(
          comboId: 'combo_longsilog',
          name: 'Longsilog',
          category: 'Silog',
          comboPrice: 69.0,
          items: <ComboItem>[
            ComboItem(
              dishId: 'longganisa',
              dishName: 'Longganisa',
              alaCartePrice: 40.0,
            ),
            ComboItem(
              dishId: 'sinangag',
              dishName: 'Sinangag',
              alaCartePrice: 20.0,
            ),
            ComboItem(
              dishId: 'itlog',
              dishName: 'Itlog (Pritong)',
              alaCartePrice: 15.0,
            ),
          ],
        ),
        const ComboMeal(
          comboId: 'combo_bangsilog',
          name: 'Bangsilog',
          category: 'Silog',
          comboPrice: 89.0,
          items: <ComboItem>[
            ComboItem(
              dishId: 'bangus',
              dishName: 'Bangus (Inihaw)',
              alaCartePrice: 60.0,
            ),
            ComboItem(
              dishId: 'sinangag',
              dishName: 'Sinangag',
              alaCartePrice: 20.0,
            ),
            ComboItem(
              dishId: 'itlog',
              dishName: 'Itlog (Pritong)',
              alaCartePrice: 15.0,
            ),
          ],
        ),
        const ComboMeal(
          comboId: 'combo_tosilog',
          name: 'Tosilog',
          category: 'Silog',
          comboPrice: 74.0,
          items: <ComboItem>[
            ComboItem(
              dishId: 'tocino',
              dishName: 'Tocino',
              alaCartePrice: 45.0,
            ),
            ComboItem(
              dishId: 'sinangag',
              dishName: 'Sinangag',
              alaCartePrice: 20.0,
            ),
            ComboItem(
              dishId: 'itlog',
              dishName: 'Itlog (Pritong)',
              alaCartePrice: 15.0,
            ),
          ],
        ),
        const ComboMeal(
          comboId: 'combo_chicksilog',
          name: 'Chicksilog',
          category: 'Silog',
          comboPrice: 84.0,
          items: <ComboItem>[
            ComboItem(
              dishId: 'chicken',
              dishName: 'Chicken (Prito)',
              alaCartePrice: 55.0,
            ),
            ComboItem(
              dishId: 'sinangag',
              dishName: 'Sinangag',
              alaCartePrice: 20.0,
            ),
            ComboItem(
              dishId: 'itlog',
              dishName: 'Itlog (Pritong)',
              alaCartePrice: 15.0,
            ),
          ],
        ),
      ];

  // ─── Cart logic ────────────────────────────────────────────────────────────

  /// Add a dish line to the cart. Merges quantity if already present.
  static List<CartLine> addToCart(
    List<CartLine> cart,
    CartLine newLine,
  ) {
    final List<CartLine> updated = List<CartLine>.from(cart);
    final int existingIdx =
        updated.indexWhere((CartLine l) => l.id == newLine.id && !l.isCombo);
    if (existingIdx >= 0 && !newLine.isCombo) {
      updated[existingIdx].quantity += newLine.quantity;
    } else {
      updated.add(newLine);
    }
    return updated;
  }

  /// Remove one unit from a cart line. Removes line entirely if quantity hits 0.
  static List<CartLine> removeOne(List<CartLine> cart, String lineId) {
    final List<CartLine> updated = List<CartLine>.from(cart);
    final int idx = updated.indexWhere((CartLine l) => l.id == lineId);
    if (idx < 0) return updated;
    if (updated[idx].quantity <= 1) {
      updated.removeAt(idx);
    } else {
      updated[idx].quantity--;
    }
    return updated;
  }

  /// Compute grand total of the cart (exact cent arithmetic).
  static double cartTotal(List<CartLine> cart) => double.parse(
        cart
            .fold<double>(0.0, (double s, CartLine l) => s + l.lineTotal)
            .toStringAsFixed(2),
      );

  /// Compute change given cash tendered.
  static double computeChange(double cartTotal, double tendered) =>
      double.parse((tendered - cartTotal).toStringAsFixed(2));

  /// Group cart lines by category for receipt display.
  static Map<String, List<CartLine>> groupByCategory(List<CartLine> cart) {
    final Map<String, List<CartLine>> grouped = <String, List<CartLine>>{};
    for (final CartLine line in cart) {
      grouped.putIfAbsent(line.category, () => <CartLine>[]).add(line);
    }
    return grouped;
  }

  /// Savings on a combo vs. buying à la carte.
  static double comboSavings(ComboMeal combo) => combo.savings;

  /// Check if all combo items are still available (portions > 0) given
  /// a map of dishId → portionsLeft.
  static bool isComboAvailable(
    ComboMeal combo,
    Map<String, int> portionsMap,
  ) {
    for (final ComboItem item in combo.items) {
      final int left = portionsMap[item.dishId] ?? 0;
      if (left <= 0) return false;
    }
    return true;
  }
}
