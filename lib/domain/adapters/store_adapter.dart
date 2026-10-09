import 'package:flutter/material.dart';

import '../../theme/store_theme.dart';

/// StoreAdapter is the central polymorphic contract for store-type-specific logic.
/// All shared screens delegate store-specific UI (cards, forms, POS) and business rules
/// (weights, combos, barcodes, CSV schemas) to the active adapter.
abstract class StoreAdapter {
  StoreType get storeType;
  String get storeTitle;
  Color get brandColor;
  bool get requiresBarcode;       // false for gulay, carinderia
  bool get requiresWeightInput;   // true for gulay, rice
  bool get hasComboEngine;        // true for carinderia only
  List<String> get csvHeaders;
  List<String> get defaultCategories;
  List<String> itemToCsvRow(dynamic item);

  Widget buildInventoryBox(dynamic item, VoidCallback onTap, BuildContext context);
  Widget buildAddForm(BuildContext context);
  Widget buildPosInterface(BuildContext context);
}
