/// reorder_engine.dart
/// Pure Dart reorder & demand calculation service.
/// Calculates restock requirements based on sales velocity and pack rounding.
library;

class ReorderLine {
  const ReorderLine({
    required this.id,
    required this.name,
    required this.qtyPacks,
    required this.unit,
    required this.supplier,
    required this.costPerPack,
    required this.totalCost,
  });

  final int id;
  final String name;
  final int qtyPacks;
  final String unit;
  final String supplier;
  final double costPerPack;
  final double totalCost;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'qty_packs': qtyPacks,
        'unit': unit,
        'supplier': supplier,
        'cost_per_pack': costPerPack,
        'total_cost': totalCost,
      };
}

class ReorderDraft {
  const ReorderDraft({
    required this.title,
    required this.coverDays,
    required this.lines,
    required this.totalCost,
    this.note,
  });

  final String title;
  final int coverDays;
  final List<ReorderLine> lines;
  final double totalCost;
  final String? note;

  List<String> get suppliers =>
      lines.map((l) => l.supplier).toSet().toList()..sort();

  List<ReorderLine> linesForSupplier(String supplier) =>
      lines.where((l) => l.supplier == supplier).toList();

  /// Formats the restock order as a clean shareable message for Messenger or SMS
  String toShareableText({String storeName = 'Tindahan'}) {
    final StringBuffer buf = StringBuffer();
    buf.writeln('📋 SARI RESTOCK ORDER — $storeName');
    buf.writeln('Panahon: $coverDays araw na cover');
    buf.writeln('------------------------------');
    for (final String s in suppliers) {
      buf.writeln('\n🚚 Supplier: $s');
      for (final ReorderLine line in linesForSupplier(s)) {
        buf.writeln('  • ${line.name} — ${line.qtyPacks} ${line.unit} (₱${line.totalCost.toStringAsFixed(0)})');
      }
    }
    buf.writeln('\n------------------------------');
    buf.writeln('Kabuuang Halaga: ₱${totalCost.toStringAsFixed(2)}');
    buf.writeln('Drafted locally via SARI AI Engine');
    return buf.toString();
  }
}

class ReorderEngine {
  const ReorderEngine._();

  /// Calculates needed packs for an item based on daily velocity and pack size.
  /// Always rounds up to pack size to match wholesale supplier distribution.
  static ReorderLine? calculateNeeded({
    required int id,
    required String name,
    required int currentStock,
    required double dailyVelocity,
    required int packSize,
    required String unit,
    required String supplier,
    required double costPerItem,
    required int coverDays,
  }) {
    final double targetUnits = dailyVelocity * coverDays;
    final double deficitUnits = targetUnits - currentStock;
    if (deficitUnits <= 0) return null;

    final int effectivePack = packSize > 0 ? packSize : 1;
    final int neededPacks = (deficitUnits / effectivePack).ceil();
    if (neededPacks <= 0) return null;

    final double costPerPack = costPerItem * effectivePack;
    final double totalCost = neededPacks * costPerPack;

    return ReorderLine(
      id: id,
      name: name,
      qtyPacks: neededPacks,
      unit: unit,
      supplier: supplier,
      costPerPack: costPerPack,
      totalCost: totalCost,
    );
  }
}
