import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_provider.dart';
import '../../domain/adapters/gulay_adapter.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/portion_advisor.dart';
import '../../domain/services/scale_calculator.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import '../inventory/shared/item_box_grid.dart';

class GulayPosScreen extends ConsumerStatefulWidget {
  const GulayPosScreen({super.key});

  @override
  ConsumerState<GulayPosScreen> createState() => _GulayPosScreenState();
}

class _GulayPosScreenState extends ConsumerState<GulayPosScreen> {
  static const GulayAdapter adapter = GulayAdapter();

  // Active cart for POS: maps productId -> {weight, total, product}
  final Map<String, Map<String, dynamic>> _cart = <String, Map<String, dynamic>>{};

  double get _cartTotal => _cart.values.fold<double>(
        0.0,
        (double sum, Map<String, dynamic> item) =>
            sum + (item['total'] as double),
      );

  int get _cartItemCount => _cart.length;

  void _openScalePricingDialog(Product product) {
    double currentWeight = 1.0;
    final TextEditingController weightCtrl =
        TextEditingController(text: currentWeight.toString());

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E2228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final double computedPrice = ScaleCalculator.computePrice(
              weightKg: currentWeight,
              pricePerKg: product.unitPrice,
            );

            final String? portionHint = PortionAdvisor.getHint(
              produceName: product.name,
              weightKg: currentWeight,
              recipeHint: product.categoryName,
            );

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // ── Header ─────────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                product.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₱${product.unitPrice.toStringAsFixed(2)} / kilo',
                                style: TextStyle(
                                  color: adapter.brandColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Weight Presets Chips ───────────────────────────────
                    const Text(
                      'Pumili ng Timbang (kg):',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: ScaleCalculator.standardPresets.map((double preset) {
                          final bool isSelected = (currentWeight - preset).abs() < 0.001;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(
                              label: Text('${preset.toString()} kg'),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFFC9D1D9),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              backgroundColor: isSelected
                                  ? adapter.brandColor
                                  : GlowTokens.surfaceCard,
                              side: BorderSide(
                                color: isSelected
                                    ? adapter.brandColor
                                    : GlowTokens.normalBorder,
                              ),
                              onPressed: () {
                                setModalState(() {
                                  currentWeight = preset;
                                  weightCtrl.text = preset.toString();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Custom Weight Input ────────────────────────────────
                    TextField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                      decoration: InputDecoration(
                        labelText: 'Ipasok ang Timbang (Kilo)',
                        suffixText: 'kg',
                        suffixStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.scale, color: Color(0xFF8B949E)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: GlowTokens.normalBorder),
                        ),
                      ),
                      onChanged: (String val) {
                        final double? parsed = double.tryParse(val);
                        if (parsed != null && parsed >= 0) {
                          setModalState(() => currentWeight = parsed);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // ── Dynamic Portion Hint Chip ──────────────────────────
                    if (portionHint != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: adapter.brandColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: adapter.brandColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFFFFB300),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                portionHint,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ── Total & Add Button ─────────────────────────────────
                    Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Kabuuang Presyo:',
                              style: TextStyle(
                                  color: Color(0xFF8B949E), fontSize: 12),
                            ),
                            Text(
                              ScaleCalculator.formatPrice(computedPrice),
                              style: TextStyle(
                                color: adapter.brandColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: adapter.brandColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.shopping_basket,
                              color: Colors.white),
                          label: const Text(
                            'ILAGAY SA BAYONG',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: currentWeight <= 0
                              ? null
                              : () {
                                  setState(() {
                                    _cart[product.productId] = <String, dynamic>{
                                      'product': product,
                                      'weight': currentWeight,
                                      'total': computedPrice,
                                    };
                                  });
                                  Navigator.pop(ctx);
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<InventoryState> asyncInv = ref.watch(inventoryProvider);

    return StoreScaffold(
      storeType: StoreType.gulay,
      headerTitle: 'Gulay POS (Scale Pricing)',
      bottomBar: _cartItemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: GlowTokens.surfaceCard,
                border: const Border(
                  top: BorderSide(color: GlowTokens.normalBorder),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$_cartItemCount gulay sa bayong',
                        style: const TextStyle(
                            color: Color(0xFF8B949E), fontSize: 12),
                      ),
                      Text(
                        ScaleCalculator.formatPrice(_cartTotal),
                        style: TextStyle(
                          color: adapter.brandColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: adapter.brandColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      setState(() => _cart.clear());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Nabayaran na ang bayong!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text(
                      'MAGBAYAD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: asyncInv.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text('Error: $e')),
        data: (InventoryState state) {
          return StoreItemBoxGrid(
            items: state.products,
            adapter: adapter,
            onTapItem: (dynamic item) {
              if (item is Product) _openScalePricingDialog(item);
            },
            emptyMessage: 'Walang nakalistang gulay o prutas',
          );
        },
      ),
    );
  }
}
