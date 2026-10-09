import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/buyer_provider.dart';
import '../../../domain/entities/buyer_order.dart';
import '../../../theme/app_theme.dart';
import 'buyer_qr_dialog.dart';

class BuyerCartSheet extends ConsumerWidget {
  const BuyerCartSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const BuyerCartSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors c = appColors(context);
    final BuyerState state = ref.watch(buyerProvider);
    final BuyerNotifier notifier = ref.read(buyerProvider.notifier);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grabber handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.shopping_bag_outlined, color: c.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Iyong Basket (${state.cartCount})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: c.text,
                      ),
                    ),
                  ],
                ),
                if (!state.isCartEmpty)
                  TextButton.icon(
                    onPressed: () => notifier.clearCart(),
                    icon: Icon(Icons.delete_outline, size: 16, color: c.error),
                    label: Text(
                      'I-clear',
                      style: TextStyle(fontSize: 12, color: c.error),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.isCartEmpty) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Icon(Icons.remove_shopping_cart_outlined,
                          size: 48, color: c.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'Walang laman ang basket',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...<Widget>[
              // Items List
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: state.cartItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (BuildContext ctx, int index) {
                    final BuyerOrderItem item = state.cartItems[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₱${item.itemUnitPrice.toStringAsFixed(2)} bawat isa',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textSecondary,
                                ),
                              ),
                              if (item.addons.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+ ${item.addons.join(", ")}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: c.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Qty controls
                        Row(
                          children: <Widget>[
                            InkWell(
                              onTap: () => notifier.updateItemQty(index, -1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: c.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: c.border),
                                ),
                                child: Icon(Icons.remove, size: 16, color: c.text),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '${item.qty}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: c.text,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => notifier.updateItemQty(index, 1),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.add, size: 16, color: c.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        // Subtotal
                        SizedBox(
                          width: 65,
                          child: Text(
                            '₱${item.subtotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Total summary box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Kabuuang Babayaran:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                    Text(
                      '₱${state.cartTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: c.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // I-Order Na (Generate QR)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final BuyerOrder order = notifier.stageOrder();
                    Navigator.of(context).pop();
                    BuyerQrDialog.show(context, order);
                  },
                  icon: const Icon(Icons.qr_code_2, color: Colors.white),
                  label: const Text(
                    'I-Order Na (I-pakita ang QR)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
