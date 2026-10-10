import '../../data/local/daos/product_dao.dart';
import '../../data/local/daos/restock_draft_dao.dart';
import '../../domain/entities/product.dart';
import 'reorder_engine.dart';

/// NightlyReorderWorker
/// Periodic & on-launch background worker that assesses stock deficit
/// and creates restock drafts in SQLite without cloud dependencies.
class NightlyReorderWorker {
  const NightlyReorderWorker({
    ProductDao? productDao,
    RestockDraftDao? restockDraftDao,
  })  : _productDao = productDao,
        _restockDraftDao = restockDraftDao;

  final ProductDao? _productDao;
  final RestockDraftDao? _restockDraftDao;

  ProductDao get _effectiveProductDao => _productDao ?? ProductDao();
  RestockDraftDao get _effectiveRestockDraftDao =>
      _restockDraftDao ?? RestockDraftDao();

  /// Runs reorder evaluation across the local product catalog.
  /// Generates a restock draft into `restock_drafts` table if items are below threshold.
  Future<RestockDraftEntry?> run({int coverDays = 3}) async {
    final List<Product> products = await _effectiveProductDao.getAllProducts();
    if (products.isEmpty) return null;

    final List<ReorderLine> neededLines = <ReorderLine>[];

    for (final Product p in products) {
      if (!p.isActive) continue;

      // Estimate daily velocity from threshold if velocity history is nascent
      final double estimatedVelocity =
          p.threshold > 0 ? (p.threshold / 2.5).clamp(1.0, 50.0) : 1.0;

      final String supplierName =
          (p.categoryName != null && p.categoryName!.isNotEmpty)
              ? p.categoryName!
              : 'Supplier';

      final ReorderLine? line = ReorderEngine.calculateNeeded(
        id: p.productId.hashCode,
        name: p.name,
        currentStock: p.stockQty,
        dailyVelocity: estimatedVelocity,
        packSize: 1,
        unit: 'pcs',
        supplier: supplierName,
        costPerItem: p.costPrice > 0 ? p.costPrice : p.unitPrice * 0.8,
        coverDays: coverDays,
      );

      if (line != null) {
        neededLines.add(line);
      }
    }

    if (neededLines.isEmpty) return null;

    final double totalCost = neededLines.fold<double>(
      0.0,
      (double sum, ReorderLine l) => sum + l.totalCost,
    );

    final String title = 'SARI Nightly Restock Draft ($coverDays Araw)';
    final List<Map<String, dynamic>> serializedLines =
        neededLines.map((ReorderLine l) => l.toMap()).toList();

    // Check if an open draft with this title was already generated recently
    final List<RestockDraftEntry> openDrafts =
        await _effectiveRestockDraftDao.getOpenDrafts();
    final bool alreadyDraftedToday = openDrafts.any(
      (RestockDraftEntry d) =>
          d.title.startsWith('SARI Nightly Restock') &&
          DateTime.now().difference(d.createdAt).inHours < 12,
    );

    if (alreadyDraftedToday) {
      return openDrafts.firstWhere(
        (RestockDraftEntry d) => d.title.startsWith('SARI Nightly Restock'),
      );
    }

    await _effectiveRestockDraftDao.saveDraft(
      title: title,
      lines: serializedLines,
      totalCost: totalCost,
      status: 'open',
    );

    final List<RestockDraftEntry> updatedOpen =
        await _effectiveRestockDraftDao.getOpenDrafts();
    return updatedOpen.firstOrNull;
  }
}
