import 'package:flutter/material.dart';

import '../../domain/services/combo_engine.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';

/// ComboBuilder Screen
/// Displays the built-in Silog combos and allows the user to
/// add a combo meal directly to the POS cart.
class ComboBuilderScreen extends StatefulWidget {
  const ComboBuilderScreen({super.key, required this.onAddCombo});

  /// Called when a combo is selected; passes combo back to POS cart.
  final void Function(ComboMeal combo) onAddCombo;

  @override
  State<ComboBuilderScreen> createState() => _ComboBuilderScreenState();
}

class _ComboBuilderScreenState extends State<ComboBuilderScreen> {
  static const Color _brand = StoreColors.carinderia;

  final List<ComboMeal> _combos = ComboEngine.defaultSilogCombos();
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    return StoreScaffold(
      storeType: StoreType.carinderia,
      headerTitle: 'Combo Builder',
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: _combos.length,
        itemBuilder: (BuildContext ctx, int i) {
          final ComboMeal combo = _combos[i];
          final bool expanded = _expandedId == combo.comboId;
          return _ComboCard(
            combo: combo,
            expanded: expanded,
            brand: _brand,
            onToggle: () => setState(() {
              _expandedId = expanded ? null : combo.comboId;
            }),
            onAdd: () {
              widget.onAddCombo(combo);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('${combo.name} idinagdag sa order! 🍽️'),
                  backgroundColor: _brand,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Combo Card
// ──────────────────────────────────────────────────────────────────────────────

class _ComboCard extends StatelessWidget {
  const _ComboCard({
    required this.combo,
    required this.expanded,
    required this.brand,
    required this.onToggle,
    required this.onAdd,
  });

  final ComboMeal combo;
  final bool expanded;
  final Color brand;
  final VoidCallback onToggle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: expanded
            ? brand.withAlpha(20)
            : const Color(0xFF1A1E28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? brand : Colors.white12,
          width: expanded ? 1.5 : 1,
        ),
        boxShadow: expanded
            ? <BoxShadow>[
                BoxShadow(
                  color: brand.withAlpha(50),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header — always visible
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  // Silog icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brand.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('🍳', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + savings
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          combo.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          combo.savingsLabel,
                          style: TextStyle(
                            color: combo.savings > 0
                                ? Colors.greenAccent
                                : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '₱${combo.comboPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: brand,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded detail
          if (expanded) ...<Widget>[
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'KASAMA',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 8),
                  ...combo.items.map(
                    (ComboItem item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.circle,
                              color: StoreColors.carinderia, size: 6),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.dishName,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          Text(
                            '₱${item.alaCartePrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // À la carte total vs combo price comparison
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('À la carte',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            Text(
                              '₱${combo.alaCarteTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            const Text('Tipid',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            Text(
                              '₱${combo.savings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            const Text('Combo',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 11)),
                            Text(
                              '₱${combo.comboPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: brand,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        'I-order  ₱${combo.comboPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
