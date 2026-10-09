import 'package:flutter/material.dart';

import '../../../domain/adapters/store_adapter.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Search Input ───────────────────────────────────────────────────────
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: GlowTokens.surfaceCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GlowTokens.normalBorder),
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Hanapin sa ${adapter.storeTitle}...',
              hintStyle: const TextStyle(color: Color(0xFF8B949E), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B949E), size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF8B949E), size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
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
                color: Colors.white70,
                bgColor: GlowTokens.surfaceCard,
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
                  borderColor: GlowTokens.outOfStockGlow.withValues(alpha: 0.4),
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
        const SizedBox(height: 16),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? GlowTokens.normalBorder,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? brandColor : GlowTokens.surfaceCard,
          borderRadius: BorderRadius.circular(SpaceTokens.chipRadius),
          border: Border.all(
            color: isSelected ? brandColor : GlowTokens.normalBorder,
            width: 1,
          ),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: brandColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFFC9D1D9),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
