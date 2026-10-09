// ItemBox — box-type inventory card used across all store types.
// Supports 3 stock status states with glow effects via BoxShadow (NO blur).
//
// Usage:
//   ItemBox(
//     name: 'Talong',
//     priceLabel: '₱75.00 / kg',
//     stockLabel: '14.5 kg',
//     isLowStock: false,
//     isOutOfStock: false,
//     onTap: () {},
//   )

import 'package:flutter/material.dart';

import '../theme/store_theme.dart';

/// Universal inventory item card with status glow.
/// Used by ALL store type inventory screens.
class ItemBox extends StatelessWidget {
  const ItemBox({
    super.key,
    required this.name,
    required this.priceLabel,
    required this.stockLabel,
    required this.isLowStock,
    required this.isOutOfStock,
    required this.onTap,
    this.onLongPress,
    this.imageWidget,
    this.categoryLabel,
    this.accentColor,
    this.trailing,
  });

  final String name;
  final String priceLabel;
  final String stockLabel;
  final bool isLowStock;
  final bool isOutOfStock;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Optional photo/icon widget shown at the top of the card.
  final Widget? imageWidget;

  /// Optional category/type badge text.
  final String? categoryLabel;

  /// Optional store-specific accent color for the price text.
  final Color? accentColor;

  /// Optional trailing action widget (e.g. add-stock button).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final BoxDecoration decoration = GlowTokens.cardDecoration(
      isLowStock: isLowStock,
      isOutOfStock: isOutOfStock,
    );

    final double opacity = isOutOfStock ? 0.5 : 1.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Opacity(
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: decoration,
          child: Stack(
            children: <Widget>[
              // Main card content
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Image/icon zone
                    if (imageWidget != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 72,
                          width: double.infinity,
                          child: imageWidget!,
                        ),
                      )
                    else
                      _DefaultIcon(
                        accent: accentColor,
                        isLowStock: isLowStock,
                        isOutOfStock: isOutOfStock,
                      ),
                    const SizedBox(height: 8),

                    // Name
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                    ),

                    if (categoryLabel != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        categoryLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                            ),
                      ),
                    ],

                    const Spacer(),

                    // Price
                    Text(
                      priceLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: accentColor ??
                                Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),

                    // Stock badge row
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            stockLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) trailing!,
                      ],
                    ),
                  ],
                ),
              ),

              // Status overlay badges
              if (isOutOfStock)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: _StatusBadge(
                    label: 'UBOS',
                    color: GlowTokens.outOfStockGlow,
                  ),
                )
              else if (isLowStock)
                const Positioned(
                  top: 8,
                  right: 8,
                  child: _StatusBadge(
                    label: 'MABABA',
                    color: GlowTokens.lowStockGlow,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback icon shown when no product image is available.
class _DefaultIcon extends StatelessWidget {
  const _DefaultIcon({
    this.accent,
    required this.isLowStock,
    required this.isOutOfStock,
  });

  final Color? accent;
  final bool isLowStock;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isOutOfStock
        ? GlowTokens.outOfStockGlow
        : isLowStock
            ? GlowTokens.lowStockGlow
            : (accent ?? Theme.of(context).colorScheme.primary);

    return Container(
      height: 72,
      width: double.infinity,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        isOutOfStock
            ? Icons.remove_shopping_cart_outlined
            : isLowStock
                ? Icons.warning_amber_rounded
                : Icons.inventory_2_outlined,
        size: SpaceTokens.iconSizeGrid,
        color: iconColor,
      ),
    );
  }
}

/// Small colored badge used for stock status labels.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Responsive 2-column box grid for inventory items.
/// Used by all store type inventory screens.
class ItemBoxGrid extends StatelessWidget {
  const ItemBoxGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisExtent = 210,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: SpaceTokens.pagePadding,
        vertical: SpaceTokens.cardGap,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: SpaceTokens.cardGap,
        mainAxisSpacing: SpaceTokens.cardGap,
        mainAxisExtent: mainAxisExtent,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// Sliver variant for use inside CustomScrollView.
class SliverItemBoxGrid extends StatelessWidget {
  const SliverItemBoxGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisExtent = 210,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpaceTokens.pagePadding,
        vertical: SpaceTokens.cardGap,
      ),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: SpaceTokens.cardGap,
          mainAxisSpacing: SpaceTokens.cardGap,
          mainAxisExtent: mainAxisExtent,
        ),
      ),
    );
  }
}
