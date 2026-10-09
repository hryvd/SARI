import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../domain/entities/sales_summary.dart';
import '../../../theme/app_theme.dart';

class TopProductsBarView extends StatelessWidget {
  const TopProductsBarView({
    super.key,
    required this.topProducts,
    required this.accentColor,
  });

  final List<TopProduct> topProducts;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final List<TopProduct> items = topProducts.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.leaderboard_rounded, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'Pinakamalakas na Produkto',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Wala pang sapat na transaksyon para sa listahan.',
                  style: TextStyle(color: c.textTertiary, fontSize: 13),
                ),
              ),
            )
          else ...<Widget>[
            ...List.generate(items.length, (int index) {
              final TopProduct item = items[index];
              final double maxRev = items
                  .map((e) => e.totalRevenue)
                  .fold<double>(0.0, math.max);
              final double ratio = maxRev > 0 ? (item.totalRevenue / maxRev) : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: index == 0
                                      ? accentColor
                                      : c.border.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: index == 0 ? Colors.white : c.text,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${item.totalRevenue.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: c.text,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Thick horizontal proportion bar
                    Stack(
                      children: <Widget>[
                        Container(
                          height: 10,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: c.border.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: ratio.clamp(0.04, 1.0),
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: index == 0 ? accentColor : accentColor.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: index == 0
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.35),
                                        blurRadius: 6,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
