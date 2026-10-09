import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_provider.dart';
import '../../application/inventory_provider.dart';
import '../../application/store_adapter_provider.dart';
import '../../data/local/daos/store_items_dao.dart';
import '../../domain/adapters/store_adapter.dart';
import '../../domain/entities/item_dish.dart';
import '../../domain/entities/item_gulay.dart';
import '../../domain/entities/item_rice.dart';
import '../../domain/entities/product.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import 'carinderia/carinderia_inventory.dart';
import 'gulay/gulay_inventory.dart';
import 'rice/rice_inventory.dart';
import 'sari_sari/sari_sari_inventory.dart';

class UniversalInventoryScreen extends ConsumerStatefulWidget {
  const UniversalInventoryScreen({super.key});

  @override
  ConsumerState<UniversalInventoryScreen> createState() =>
      _UniversalInventoryScreenState();
}

class _UniversalInventoryScreenState
    extends ConsumerState<UniversalInventoryScreen> {
  final StoreItemsDao _itemsDao = StoreItemsDao();

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E2228),
      ),
    );
  }

  Future<void> _openQuickStockDialog(Product product) async {
    final TextEditingController qtyCtrl = TextEditingController();
    final StoreAdapter adapter = ref.read(storeAdapterProvider);

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E2228),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Dagdag Stock — ${product.name}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Kasalukuyang stock: ${product.stockQty}',
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Dami ng Idadagdag',
                  hintText: 'e.g. 10',
                  prefixIcon: Icon(Icons.add),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kanselahin',
                  style: TextStyle(color: Color(0xFF8B949E))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: adapter.brandColor,
              ),
              onPressed: () async {
                final int delta = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                if (delta <= 0) return;
                await ref
                    .read(inventoryProvider.notifier)
                    .updateStock(product.productId, delta);
                if (ctx.mounted) Navigator.pop(ctx);
                _showMessage('Naidagdag ang $delta sa ${product.name}');
              },
              child: const Text('I-SAVE',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth =
        ref.watch(authProvider).value ?? const AuthState();
    final StoreType storeType = auth.storeType;
    final AsyncValue<InventoryState> asyncState =
        ref.watch(inventoryProvider);

    return StoreScaffold(
      storeType: storeType,
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (InventoryState state) {
          return switch (storeType) {
            StoreType.sariSari => SariSariInventoryView(
                products: state.products,
                onTapProduct: _openQuickStockDialog,
                onAddProduct: ({
                  required String name,
                  required String barcode,
                  required double unitPrice,
                  required double costPrice,
                  required int stockQty,
                  required int threshold,
                  String? category,
                }) async {
                  await ref.read(inventoryProvider.notifier).addProduct(
                        name: name,
                        barcode: barcode.isNotEmpty ? barcode : null,
                        unitPrice: unitPrice,
                        costPrice: costPrice,
                        stockQty: stockQty,
                        threshold: threshold,
                      );
                  _showMessage('Nai-save ang $name');
                },
              ),
            StoreType.gulay => GulayInventoryView(
                products: state.products,
                onTapProduct: _openQuickStockDialog,
                onAddGulay: ({
                  required String name,
                  required double pricePerKg,
                  required double stockKg,
                  required double lowStockKg,
                  String? category,
                  String? portionHint,
                }) async {
                  await ref.read(inventoryProvider.notifier).addProduct(
                        name: name,
                        barcode: null, // No barcode for fresh produce!
                        unitPrice: pricePerKg,
                        costPrice: pricePerKg * 0.7,
                        stockQty: stockKg.round(),
                        threshold: lowStockKg.round(),
                      );
                  // Record extension fields
                  final List<Product> products =
                      ref.read(inventoryProvider).value?.products ??
                          <Product>[];
                  final Product? added = products
                      .where((Product p) => p.name == name)
                      .firstOrNull;
                  if (added != null) {
                    await _itemsDao.upsertGulay(
                      ItemGulay(
                        itemId: added.productId,
                        pricePerKg: pricePerKg,
                        stockKg: stockKg,
                        lowStockKg: lowStockKg,
                        portionHintRecipe: portionHint,
                      ),
                    );
                  }
                  _showMessage('Nai-save ang gulay: $name');
                },
              ),
            StoreType.rice => RiceInventoryView(
                products: state.products,
                onTapProduct: _openQuickStockDialog,
                onAddRice: ({
                  required String variety,
                  required String millingGrade,
                  required double pricePerKg,
                  double? sackPrice25kg,
                  double? sackPrice50kg,
                  required double stockKg,
                }) async {
                  await ref.read(inventoryProvider.notifier).addProduct(
                        name: '$variety ($millingGrade)',
                        barcode: null,
                        unitPrice: pricePerKg,
                        costPrice: pricePerKg * 0.8,
                        stockQty: stockKg.round(),
                        threshold: 25,
                      );
                  final List<Product> products =
                      ref.read(inventoryProvider).value?.products ??
                          <Product>[];
                  final Product? added = products
                      .where((Product p) =>
                          p.name.contains(variety))
                      .firstOrNull;
                  if (added != null) {
                    await _itemsDao.upsertRice(
                      ItemRice(
                        itemId: added.productId,
                        variety: variety,
                        millingGrade: millingGrade,
                        pricePerKg: pricePerKg,
                        sackPrice25kg: sackPrice25kg,
                        sackPrice50kg: sackPrice50kg,
                        stockKg: stockKg,
                        lowStockKg: 25.0,
                        qrPayload:
                            'sare://rice?id=${added.productId}&variety=$variety',
                      ),
                    );
                  }
                  _showMessage('Nai-save ang bigas: $variety');
                },
              ),
            StoreType.carinderia => CarinderiaInventoryView(
                products: state.products,
                onTapProduct: _openQuickStockDialog,
                onAddDish: ({
                  required String name,
                  required String category,
                  required double price,
                  required int dailyPortions,
                  required bool isComboEligible,
                }) async {
                  await ref.read(inventoryProvider.notifier).addProduct(
                        name: name,
                        barcode: null,
                        unitPrice: price,
                        costPrice: price * 0.6,
                        stockQty: dailyPortions,
                        threshold: 5,
                      );
                  final List<Product> products =
                      ref.read(inventoryProvider).value?.products ??
                          <Product>[];
                  final Product? added = products
                      .where((Product p) => p.name == name)
                      .firstOrNull;
                  if (added != null) {
                    await _itemsDao.upsertDish(
                      ItemDish(
                        itemId: added.productId,
                        price: price,
                        dailyPortions: dailyPortions,
                        portionsLeft: dailyPortions,
                        isComboEligible: isComboEligible,
                      ),
                    );
                  }
                  _showMessage('Nai-save ang ulam: $name');
                },
              ),
          };
        },
      ),
    );
  }
}
