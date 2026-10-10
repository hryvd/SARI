import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth_provider.dart';
import '../../application/inventory_provider.dart';
import '../../application/locale_provider.dart';
import '../../application/store_adapter_provider.dart';
import '../../data/local/daos/store_items_dao.dart';
import '../../domain/adapters/store_adapter.dart';
import '../../domain/entities/item_dish.dart';
import '../../domain/entities/item_gulay.dart';
import '../../domain/entities/item_rice.dart';
import '../../domain/entities/product.dart';
import '../../theme/app_theme.dart';
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
    final AppColors c = appColors(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: c.text)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.surface,
      ),
    );
  }

  Future<void> _openQuickStockDialog(Product product) async {
    final TextEditingController qtyCtrl = TextEditingController();
    final StoreAdapter adapter = ref.read(storeAdapterProvider);
    final AppColors c = appColors(context);

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: c.surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: c.borderSubtle),
              ),
              title: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: adapter.brandColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: adapter.brandColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Dagdag Stock',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          product.name,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'Kasalukuyang stock:',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${product.stockQty}',
                            style: TextStyle(
                              color: c.text,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pumili ng dagdag:',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <int>[5, 10, 20, 50].map((int val) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(color: c.borderSubtle),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  final int current =
                                      int.tryParse(qtyCtrl.text.trim()) ?? 0;
                                  qtyCtrl.text = (current + val).toString();
                                });
                              },
                              child: Text(
                                '+$val',
                                style: TextStyle(
                                  color: adapter.brandColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: qtyCtrl,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: c.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Dami ng Idadagdag',
                        labelStyle: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                        ),
                        hintText: 'e.g. 10',
                        hintStyle: TextStyle(
                          color: c.textTertiary,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.add_circle_outline,
                          color: adapter.brandColor,
                        ),
                        filled: true,
                        fillColor: c.surfaceMuted,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: c.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: adapter.brandColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Kanselahin',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: adapter.brandColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
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
                  child: const Text(
                    'I-SAVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AuthState auth =
        ref.watch(authProvider).value ?? const AuthState();
    final StoreType storeType = auth.storeType;
    final StoreAdapter adapter = ref.watch(storeAdapterProvider);
    final AsyncValue<InventoryState> asyncState =
        ref.watch(inventoryProvider);
    final AppLocale locale = ref.watch(localeProvider);
    final String invLabel = locale == AppLocale.en ? 'Inventory' : 'Imbentaryo';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(storeType.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '${adapter.storeTitle} $invLabel',
              style: TextStyle(
                color: c.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: StoreScaffold(
        storeType: storeType,
        body: asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object e, _) => Center(
            child: Text(
              'Error: $e',
              style: TextStyle(color: c.text),
            ),
          ),
          data: (InventoryState state) {
            return switch (storeType) {
              StoreType.sariSari => SariSariInventoryView(
                products: state.products,
                onTapProduct: _openQuickStockDialog,
                onAddProduct: ({
                  required String name,
                  String? alias,
                  required String barcode,
                  required double unitPrice,
                  required double costPrice,
                  required int stockQty,
                  required int threshold,
                  String? category,
                }) async {
                  await ref.read(inventoryProvider.notifier).addProduct(
                        name: name,
                        alias: alias,
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
    ),
  );
  }
}
