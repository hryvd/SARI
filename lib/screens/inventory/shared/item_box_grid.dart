import 'package:flutter/material.dart';

import '../../../domain/adapters/store_adapter.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/store_theme.dart';

/// Universal 2-column Box-Grid for inventory items across all store types.
/// Enforces consistent 12dp card gaps and delegates card rendering to [adapter].
class StoreItemBoxGrid extends StatelessWidget {
  const StoreItemBoxGrid({
    super.key,
    required this.items,
    required this.adapter,
    required this.onTapItem,
    this.emptyMessage = 'Walang nahanap na produkto',
    this.emptySubtext = 'Pindutin ang + para magdagdag',
    this.physics = const BouncingScrollPhysics(),
    this.shrinkWrap = false,
    this.padding,
  });

  final List<dynamic> items;
  final StoreAdapter adapter;
  final void Function(dynamic item) onTapItem;
  final String emptyMessage;
  final String emptySubtext;
  final ScrollPhysics physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: adapter.brandColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: adapter.brandColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    adapter.storeType.emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtext,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding ??
          const EdgeInsets.fromLTRB(
            SpaceTokens.pagePadding,
            SpaceTokens.cardGap / 2,
            SpaceTokens.pagePadding,
            96.0,
          ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SpaceTokens.cardGap,
        mainAxisSpacing: SpaceTokens.cardGap,
        childAspectRatio: 0.84,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        final dynamic item = items[index];
        return adapter.buildInventoryBox(
          item,
          () => onTapItem(item),
          context,
        );
      },
    );
  }
}
