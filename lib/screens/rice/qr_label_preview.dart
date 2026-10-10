import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../application/inventory_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/label_printer.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';

/// Screen: QR Label Print Preview (Bigasan)
/// Shows a scrollable list of rice varieties. Tap the print FAB to render
/// a PDF sheet and open the system print dialog.
class QrLabelPreviewScreen extends ConsumerStatefulWidget {
  const QrLabelPreviewScreen({super.key});

  @override
  ConsumerState<QrLabelPreviewScreen> createState() =>
      _QrLabelPreviewScreenState();
}

class _QrLabelPreviewScreenState
    extends ConsumerState<QrLabelPreviewScreen> {
  // Set of selected productIds for printing
  final Set<String> _selected = <String>{};
  bool _selectAll = false;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<InventoryState> invAsync =
        ref.watch(inventoryProvider);

    return StoreScaffold(
      storeType: StoreType.rice,
      headerTitle: 'QR Label Generator',
      headerActions: <Widget>[
        IconButton(
          icon: Icon(
            _selectAll ? Icons.deselect : Icons.select_all,
            color: _brand,
          ),
          tooltip: _selectAll ? 'Deselect All' : 'Select All',
          onPressed: () {
            invAsync.whenData((InventoryState state) {
              final List<Product> items = _riceProducts(state);
              setState(() {
                _selectAll = !_selectAll;
                if (_selectAll) {
                  _selected.addAll(items.map((Product i) => i.productId));
                } else {
                  _selected.clear();
                }
              });
            });
          },
        ),
      ],
      body: invAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) =>
            Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (InventoryState state) => _buildBody(context, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected.isEmpty ? null : () => _printSelected(context),
        backgroundColor: _selected.isEmpty
            ? Colors.grey.shade800
            : _brand,
        icon: const Icon(Icons.print_rounded),
        label: Text(
          _selected.isEmpty
              ? 'Select items'
              : 'Print ${_selected.length} label${_selected.length == 1 ? '' : 's'}',
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, InventoryState state) {
    final List<Product> items = _riceProducts(state);

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.qr_code_2, size: 64, color: _brand.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text(
              'No rice varieties yet.\nAdd items in Inventory first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: items.length,
      itemBuilder: (BuildContext ctx, int index) {
        final Product item = items[index];
        final bool isSelected = _selected.contains(item.productId);

        return _LabelCard(
          item: item,
          binNumber: index + 1,
          isSelected: isSelected,
          onToggle: () => setState(() {
            if (isSelected) {
              _selected.remove(item.productId);
            } else {
              _selected.add(item.productId);
            }
          }),
        );
      },
    );
  }

  /// Returns only products that belong to a rice category (barcode used as QR payload).
  List<Product> _riceProducts(InventoryState state) => state.products;

  Future<void> _printSelected(BuildContext context) async {
    final InventoryState? state = ref.read(inventoryProvider).valueOrNull;
    if (state == null) return;

    final List<Product> items = _riceProducts(state);
    final List<BinLabelData> labels = <BinLabelData>[];
    int binNum = 0;
    for (final Product item in items) {
      binNum++;
      if (_selected.contains(item.productId)) {
        labels.add(
          BinLabelData(
            variety: item.name,
            millingGrade: item.categoryName ?? 'Well-Milled',
            pricePerKg: item.unitPrice,
            qrPayload: item.barcode ?? item.productId,
            binNumber: binNum,
          ),
        );
      }
    }

    // Show loading snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating PDF labels...')),
      );
    }

    try {
      final List<int> pdfBytes = await LabelPrinter.generateSheet(labels);
      final Uint8List pdfUint8 = Uint8List.fromList(pdfBytes);

      if (context.mounted) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfUint8,
          name: 'Bigasan_QR_Labels',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Label Card Widget
// ──────────────────────────────────────────────────────────────────────────────

class _LabelCard extends StatelessWidget {
  const _LabelCard({
    required this.item,
    required this.binNumber,
    required this.isSelected,
    required this.onToggle,
  });

  final Product item;
  final int binNumber;
  final bool isSelected;
  final VoidCallback onToggle;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? _brand.withValues(alpha: 0.12)
            : const Color(0xFF1A1F25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? _brand : Colors.white12,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _BinBadge(number: binNumber, selected: isSelected),
        title: Text(
          item.name,
          style: TextStyle(
            color: isSelected ? _brand : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.categoryName ?? 'Well-Milled',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 4),
            _PriceChip(
              label: '₱${item.unitPrice.toStringAsFixed(2)}/kg',
              color: _brand,
            ),
          ],
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggle(),
          activeColor: _brand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        onTap: onToggle,
      ),
    );
  }
}

class _BinBadge extends StatelessWidget {
  const _BinBadge({required this.number, required this.selected});

  final int number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: selected ? StoreColors.rice : Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          '#$number',
          style: TextStyle(
            color: selected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
