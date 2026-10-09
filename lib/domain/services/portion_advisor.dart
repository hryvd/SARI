/// Domain service: Heuristic portion yield advisor for Filipino home cooking.
/// Pure Dart business logic — no Flutter imports.
class PortionAdvisor {
  const PortionAdvisor._();

  /// Returns an approximate serving estimate hint in Tagalog, or null if weight <= 0.
  /// Example: "Pang 6-8 katao" or "Pang 3-5 katao sa Sinigang".
  static String? getHint({
    required String produceName,
    required double weightKg,
    String? recipeHint,
  }) {
    if (weightKg <= 0.0) return null;

    final String nameLower = produceName.toLowerCase();

    // Aromatics (Sibuyas, Bawang, Luya)
    if (nameLower.contains('sibuyas') ||
        nameLower.contains('bawang') ||
        nameLower.contains('luya') ||
        nameLower.contains('sili')) {
      if (recipeHint != null && recipeHint.isNotEmpty) {
        return 'Pampalasa para sa $recipeHint';
      }
      return 'Pampalasa para sa maramihang luto';
    }

    // Determine servings per kg based on vegetable category
    double servingsPerKg = 4.0;
    if (nameLower.contains('patatas') || nameLower.contains('karot')) {
      servingsPerKg = 5.0;
    } else if (nameLower.contains('kamatis')) {
      servingsPerKg = 6.0;
    } else if (nameLower.contains('sitaw') ||
        nameLower.contains('talong') ||
        nameLower.contains('kalabasa') ||
        nameLower.contains('sayote') ||
        nameLower.contains('ampalaya')) {
      servingsPerKg = 4.0;
    }

    final double estimatedServings = weightKg * servingsPerKg;
    final String range = _formatServingsRange(estimatedServings);

    if (recipeHint != null && recipeHint.isNotEmpty) {
      return '$range sa $recipeHint';
    }
    return range;
  }

  static String _formatServingsRange(double servings) {
    if (servings < 2.5) {
      return 'Pang 1-2 katao';
    } else if (servings < 5.5) {
      return 'Pang 3-5 katao';
    } else if (servings < 9.0) {
      return 'Pang 6-8 katao';
    } else {
      return 'Pang 10+ katao (Pang-handaan)';
    }
  }
}
