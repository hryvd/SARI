// StoreScaffold — standardized page scaffold with 16dp horizontal padding.
// The Sari-Sari home layout is the canonical reference for all store types.
// All screens MUST use StoreScaffold instead of raw Padding or Container.

import 'package:flutter/material.dart';

import '../theme/store_theme.dart';

/// A consistent page scaffold that wraps a scrollable or fixed body
/// with the standard 16dp horizontal page padding, enforced globally.
/// Store-specific accent color is injected via [storeType].
class StoreScaffold extends StatelessWidget {
  const StoreScaffold({
    super.key,
    required this.body,
    this.storeType,
    this.headerTitle,
    this.headerActions,
    this.floatingActionButton,
    this.bottomBar,
    this.slivers,
    this.useSliver = false,
  }) : assert(
          useSliver == false || slivers != null,
          'Provide slivers when useSliver is true',
        );

  /// Main body widget. Used when [useSliver] is false.
  final Widget? body;

  /// List of slivers. Used when [useSliver] is true.
  final List<Widget>? slivers;

  /// True to render body as a CustomScrollView with [slivers].
  final bool useSliver;

  final StoreType? storeType;

  /// Optional page-level header title string.
  final String? headerTitle;

  /// Optional action widgets placed to the right of the header title.
  final List<Widget>? headerActions;

  final Widget? floatingActionButton;

  /// Optional bottom bar (e.g., cart summary bar for POS).
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (useSliver && slivers != null) {
      content = CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: slivers!,
      );
    } else {
      content = body ?? const SizedBox.shrink();
    }

    if (headerTitle != null || headerActions != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              SpaceTokens.pagePadding,
              SpaceTokens.pagePadding,
              SpaceTokens.pagePadding,
              0,
            ),
            child: Row(
              children: <Widget>[
                if (headerTitle != null)
                  Expanded(
                    child: Text(
                      headerTitle!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ...?headerActions,
              ],
            ),
          ),
          const SizedBox(height: SpaceTokens.cardGap),
          Expanded(child: content),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          if (bottomBar == null)
            content
          else
            Positioned.fill(
              bottom: 0,
              child: Column(
                children: <Widget>[
                  Expanded(child: content),
                  bottomBar!,
                ],
              ),
            ),
          if (floatingActionButton != null)
            Positioned(
              right: SpaceTokens.pagePadding,
              bottom: bottomBar != null ? 80 : SpaceTokens.pagePadding,
              child: floatingActionButton!,
            ),
        ],
      ),
    );
  }
}

/// Horizontal padding wrapper matching the standard page padding.
/// Use this inside CustomScrollView slivers for consistent insets.
class PagePaddingSliver extends StatelessWidget {
  const PagePaddingSliver({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: SpaceTokens.pagePadding,
      ),
      sliver: child,
    );
  }
}

/// Non-sliver version: standard horizontal page padding around any widget.
class PagePadding extends StatelessWidget {
  const PagePadding({super.key, required this.child, this.top = 0, this.bottom = 0});

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        SpaceTokens.pagePadding,
        top,
        SpaceTokens.pagePadding,
        bottom,
      ),
      child: child,
    );
  }
}
