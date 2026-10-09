import 'package:flutter/material.dart';

import '../../../domain/entities/buyer_order.dart';
import '../../../domain/services/buyer_order_service.dart';
import '../../../theme/app_theme.dart';
import 'buyer_qr_view.dart';

class BuyerQrDialog extends StatelessWidget {
  const BuyerQrDialog({
    super.key,
    required this.order,
  });

  final BuyerOrder order;

  static Future<void> show(BuildContext context, BuyerOrder order) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) => BuyerQrDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final String qrPayload = BuyerOrderService.serialize(order);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black38,
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Order #${order.orderId}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: c.text,
                        ),
                      ),
                      Text(
                        '${order.totalItemCount} items • ₱${order.totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // High Density QR Box
              BuyerQrView(
                data: qrPayload,
                size: 220,
              ),
              const SizedBox(height: 16),
              // Local Handshake instructions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.qr_code_scanner, color: c.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'I-pakita ang QR na ito sa camera ng Tindero upang mai-load agad ang order sa POS.',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Items breakdown list
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: order.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (BuildContext ctx, int index) {
                    final BuyerOrderItem item = order.items[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ),
                        Text(
                          '₱${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: c.text,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Settle button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Isara / Tapos Na',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
