/// Domain service: Scale Pricing Calculator for produce sold by weight.
/// Pure Dart business logic — no Flutter imports.
class ScaleCalculator {
  const ScaleCalculator._();

  /// Common market preset weights in kilograms.
  static const List<double> standardPresets = <double>[
    0.25,
    0.5,
    1.0,
    1.2,
    1.8,
  ];

  /// Computes the exact scale price rounded to 2 decimal places.
  /// Throws [ArgumentError] if weight or price is negative.
  static double computePrice({
    required double weightKg,
    required double pricePerKg,
  }) {
    if (weightKg < 0) {
      throw ArgumentError.value(weightKg, 'weightKg', 'Weight cannot be negative');
    }
    if (pricePerKg < 0) {
      throw ArgumentError.value(
          pricePerKg, 'pricePerKg', 'Price per kg cannot be negative');
    }
    if (weightKg == 0.0) return 0.0;

    // Use cents arithmetic to eliminate IEEE-754 floating point inaccuracies
    final int cents = (weightKg * pricePerKg * 100).round();
    return cents / 100.0;
  }

  /// Formats the computed scale price as Philippine Pesos (₱XX.XX).
  static String formatPrice(double price) {
    return '₱${price.toStringAsFixed(2)}';
  }
}
