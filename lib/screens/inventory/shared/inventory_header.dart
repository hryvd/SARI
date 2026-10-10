import 'package:flutter/material.dart';

import '../../../domain/adapters/store_adapter.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/store_theme.dart';

class InventoryHeader extends StatelessWidget {
  const InventoryHeader({
    super.key,
    required this.adapter,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.categories,
    required this.totalCount,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  final StoreAdapter adapter;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final List<String> categories;
  final int totalCount;
  final int lowStockCount;
  final int outOfStockCount;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SpaceTokens.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Search Input ───────────────────────────────────────────────────────
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.borderSubtle, width: 1.2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: TextStyle(
                color: c.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Hanapin sa ${adapter.storeTitle}...',
                hintStyle: TextStyle(
                  color: c.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: c.textSecondary,
                  size: 20,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: c.textSecondary,
                          size: 18,
                        ),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Status KPI Badges ──────────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: <Widget>[
                _StatChip(
                  label: 'Lahat: $totalCount',
                  color: c.textSecondary,
                  bgColor: c.surface,
                  borderColor: c.borderSubtle,
                ),
                const SizedBox(width: 8),
                if (lowStockCount > 0) ...<Widget>[
                  _StatChip(
                    label: 'Mababa: $lowStockCount',
                    color: GlowTokens.lowStockGlow,
                    bgColor: GlowTokens.lowStockGlow.withValues(alpha: 0.12),
                    borderColor: GlowTokens.lowStockGlow.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                ],
                if (outOfStockCount > 0) ...<Widget>[
                  _StatChip(
                    label: 'Ubos: $outOfStockCount',
                    color: GlowTokens.outOfStockGlow,
                    bgColor: GlowTokens.outOfStockGlow.withValues(alpha: 0.12),
                    borderColor:
                        GlowTokens.outOfStockGlow.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Category Filter Chips ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: <Widget>[
                _CategoryPill(
                  label: 'Lahat',
                  isSelected: selectedCategory == null,
                  brandColor: adapter.brandColor,
                  onTap: () => onCategorySelected(null),
                ),
                ...categories.map(
                  (String cat) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _CategoryPill(
                      label: cat,
                      isSelected: selectedCategory == cat,
                      brandColor: adapter.brandColor,
                      onTap: () => onCategorySelected(cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.color,
    required this.bgColor,
    this.borderColor,
  });

  final String label;
  final Color color;
  final Color bgColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.isSelected,
    required this.brandColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color brandColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : c.surface,
          borderRadius: BorderRadius.circular(SpaceTokens.chipRadius),
          border: Border.all(
            color: isSelected ? brandColor : c.borderSubtle,
            width: 1,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : c.textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
