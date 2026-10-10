import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/inventory_provider.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/scale_calculator.dart';
import '../../theme/app_theme.dart';
import '../../theme/store_theme.dart';
import '../../widgets/store_scaffold.dart';
import 'qr_label_preview.dart';

/// Bigasan Bin POS Screen
/// Designed to match the POS inspiration layout:
///   • Clean warm canvas background
///   • Search bar + QR label generator shortcut
///   • Variety category filter pills (Lahat, Well-Milled, Regular, Premium, etc.)
///   • Responsive bin blocks grid with amber in-cart badges and stock counters
///   • Sticky bottom checkout dock (Offline notice + payment pills + red Bayaran button)
///   • Clean white weight/sack dialog and checkout basket (NO black container!)
class RicePosScreen extends ConsumerStatefulWidget {
  const RicePosScreen({super.key});

  @override
  ConsumerState<RicePosScreen> createState() => _RicePosScreenState();
}

class _RicePosScreenState extends ConsumerState<RicePosScreen> {
  static const Color _brand = StoreColors.rice;

  static const List<String> _varieties = <String>[
    'Lahat',
    'Well-Milled',
    'Regular',
    'Premium',
    'Sinandomeng',
    'Dinorado',
    'Jasmine',
    'Malagkit',
  ];

  String _selectedCategory = 'Lahat';
  final TextEditingController _searchCtrl = TextEditingController();
  String _paymentMethod = 'Cash'; // Cash, GCash, Utang

  // Cart: key → {item, weightKg, total, label}
  final Map<String, Map<String, dynamic>> _cart =
      <String, Map<String, dynamic>>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _cartTotal => _cart.values.fold<double>(
        0.0,
        (double sum, Map<String, dynamic> e) => sum + (e['total'] as double),
      );

  // ── helpers ────────────────────────────────────────────────────────────────

  void _addToCart(Product item, double weightKg, String label) {
    setState(() {
      final String key = '${item.productId}_$label';
      final double total = ScaleCalculator.computePrice(
          weightKg: weightKg, pricePerKg: item.unitPrice);
      _cart[key] = <String, dynamic>{
        'item': item,
        'weightKg': weightKg,
        'total': total,
        'label': label,
      };
    });
  }

  void _removeFromCart(String key) => setState(() => _cart.remove(key));

  void _clearCart() => setState(() => _cart.clear());

  String? _inCartLabelFor(String productId) {
    for (final MapEntry<String, Map<String, dynamic>> entry in _cart.entries) {
      if (entry.key.startsWith(productId)) {
        return entry.value['label'] as String?;
      }
    }
    return null;
  }

  // ── weight & sack dialog (clean white container) ───────────────────────────

  void _openWeightDialog(Product item) {
    final AppColors c = appColors(context);
    double weight = 1.0;
    final TextEditingController ctrl = TextEditingController(text: '1.0');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final double computed = ScaleCalculator.computePrice(
              weightKg: weight,
              pricePerKg: item.unitPrice,
            );

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  left: 20,
                  right: 20,
                  top: 14,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Grab handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDD5CE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header row
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Color(0xFF1F1A17),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.categoryName ?? 'Well-Milled',
                                style: const TextStyle(
                                  color: Color(0xFF7A7269),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Text(
                            '₱${item.unitPrice.toStringAsFixed(2)}/kg',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Kilo presets title
                    const Text(
                      'PER KILO (Mabilisang Pindot)',
                      style: TextStyle(
                        color: Color(0xFF5A524C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Kilo preset chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <double>[0.5, 1.0, 2.0, 3.0, 5.0, 10.0]
                            .map((double preset) {
                          final bool isSelected =
                              (weight - preset).abs() < 0.01;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: _WeightChip(
                              kg: preset,
                              selected: isSelected,
                              onTap: () {
                                setModalState(() {
                                  weight = preset;
                                  ctrl.text = preset % 1 == 0
                                      ? preset.toInt().toString()
                                      : preset.toString();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sack quick options
                    const Text(
                      'SACK / SAKO',
                      style: TextStyle(
                        color: Color(0xFF5A524C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SackButton(
                            label: '25 kg (1/2 Sako)',
                            price: ScaleCalculator.computePrice(
                              weightKg: 25.0,
                              pricePerKg: item.unitPrice,
                            ),
                            selected: (weight - 25.0).abs() < 0.01,
                            onTap: () {
                              setModalState(() {
                                weight = 25.0;
                                ctrl.text = '25';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SackButton(
                            label: '50 kg (1 Buong Sako)',
                            price: ScaleCalculator.computePrice(
                              weightKg: 50.0,
                              pricePerKg: item.unitPrice,
                            ),
                            selected: (weight - 50.0).abs() < 0.01,
                            onTap: () {
                              setModalState(() {
                                weight = 50.0;
                                ctrl.text = '50';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Custom weight input field
                    TextField(
                      controller: ctrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        color: Color(0xFF1F1A17),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        labelText: 'I-type ang timbang (kg)',
                        labelStyle: const TextStyle(color: Color(0xFF7A7269)),
                        suffixText: 'kg',
                        suffixStyle: const TextStyle(
                          color: Color(0xFF7A7269),
                          fontWeight: FontWeight.bold,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F5),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFEDE8E1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: _brand, width: 1.5),
                        ),
                      ),
                      onChanged: (String v) {
                        setModalState(() {
                          weight = double.tryParse(v) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Computed Subtotal Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Kalkuladong Presyo:',
                                style: TextStyle(
                                  color: Color(0xFF7A7269),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 2)} kg × ₱${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF5A524C),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '₱${computed.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Add to basket button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: weight <= 0
                            ? null
                            : () {
                                final String label = weight == 25.0
                                    ? '25 kg (1/2 Sako)'
                                    : weight == 50.0
                                        ? '50 kg (1 Sako)'
                                        : '${weight.toStringAsFixed(weight % 1 == 0 ? 0 : 2)} kg';
                                _addToCart(item, weight, label);
                                Navigator.pop(ctx);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE5E0D8),
                          disabledForegroundColor: const Color(0xFF9E958C),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 20),
                        label: Text(
                          weight <= 0
                              ? 'Ilagay ang sapat na timbang'
                              : 'I-dagdag sa Basket  ₱${computed.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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

  // ── cart sheet (clean white container) ─────────────────────────────────────

  void _showCartSheet() {
    final AppColors c = appColors(context);
    final TextEditingController cashCtrl = TextEditingController();
    double? tendered;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            final double change = tendered != null && tendered! >= _cartTotal
                ? (tendered! - _cartTotal).clamp(0, double.infinity)
                : 0.0;
            final bool isCash = _paymentMethod == 'Cash';
            final bool canPay =
                !isCash || (tendered != null && tendered! >= _cartTotal);

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              maxChildSize: 0.92,
              minChildSize: 0.4,
              expand: false,
              builder: (_, ScrollController scroll) {
                return SafeArea(
                  top: false,
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 12),
                        // Grab handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDD5CE),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.rice_bowl_rounded,
                                      color: _brand, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order Basket (${_cart.length})',
                                    style: const TextStyle(
                                      color: Color(0xFF1F1A17),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              if (_cart.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    _clearCart();
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text(
                                    'I-clear',
                                    style: TextStyle(
                                      color: Color(0xFFD32F2F),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Color(0xFF7A7269)),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Color(0xFFEDE8E1), height: 1),

                        // Cart items list
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Walang laman ang basket.',
                                    style: TextStyle(
                                      color: Color(0xFF7A7269),
                                      fontSize: 15,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  controller: scroll,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                  itemCount: _cart.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      color: Color(0xFFF3EFEA), height: 1),
                                  itemBuilder: (BuildContext _, int index) {
                                    final MapEntry<String, Map<String, dynamic>>
                                        e = _cart.entries.elementAt(index);
                                    final Product item =
                                        e.value['item'] as Product;
                                    final double total =
                                        e.value['total'] as double;
                                    final String label =
                                        e.value['label'] as String;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    color: Color(0xFF1F1A17),
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '$label · ₱${item.unitPrice.toStringAsFixed(2)}/kg',
                                                  style: const TextStyle(
                                                    color: Color(0xFF7A7269),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₱${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFFB45309),
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.remove_circle_outline,
                                              color: Color(0xFFD32F2F),
                                              size: 22,
                                            ),
                                            onPressed: () {
                                              _removeFromCart(e.key);
                                              setModalState(() {});
                                              if (_cart.isEmpty) {
                                                Navigator.pop(ctx);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(color: Color(0xFFEDE8E1), height: 1),

                        // Subtotal row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${_cart.length} item${_cart.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Color(0xFF7A7269),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '₱${_cartTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF1F1A17),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F2EB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFEDE8E1)),
                                ),
                                child: Text(
                                  'Paraan: $_paymentMethod',
                                  style: const TextStyle(
                                    color: Color(0xFF5A524C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Cash presets and checkout panel
                        Container(
                          color: const Color(0xFFFBF9F5),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (isCash) ...<Widget>[
                                Row(
                                  children: <double>[100, 200, 500, 1000]
                                      .map((double amt) {
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 3),
                                        child: OutlinedButton(
                                          onPressed: () {
                                            setModalState(() {
                                              tendered = amt;
                                              cashCtrl.text =
                                                  amt.toStringAsFixed(0);
                                            });
                                          },
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor:
                                                StoreColors.riceDark,
                                            side: const BorderSide(
                                                color: Color(0xFFDDD5CE),
                                                width: 1),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                          child: Text(
                                            '₱${amt.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: cashCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: const TextStyle(
                                    color: Color(0xFF1F1A17),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    prefixText: '₱ ',
                                    prefixStyle: const TextStyle(
                                      color: Color(0xFF7A7269),
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    labelText: 'Ibinayad ng kostumer',
                                    labelStyle: const TextStyle(
                                        color: Color(0xFF7A7269)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFEDE8E1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: _brand, width: 1.5),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onChanged: (String v) {
                                    setModalState(() {
                                      tendered = double.tryParse(v);
                                    });
                                  },
                                ),
                                if (tendered != null &&
                                    tendered! >= _cartTotal) ...<Widget>[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      const Text(
                                        'Sukli:',
                                        style: TextStyle(
                                          color: Color(0xFF7A7269),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '₱${change.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                              ],

                              // Checkout button
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: !canPay || _cart.isEmpty
                                      ? null
                                      : () {
                                          _clearCart();
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                isCash && change > 0
                                                    ? '✅ Bayad natanggap! Sukli: ₱${change.toStringAsFixed(2)}'
                                                    : '✅ Bayad natanggap sa Bigasan!',
                                              ),
                                              backgroundColor:
                                                  const Color(0xFF2E7D32),
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _brand,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        const Color(0xFFE5E0D8),
                                    disabledForegroundColor:
                                        const Color(0xFF9E958C),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 20),
                                  label: Text(
                                    canPay
                                        ? 'I-bayad  ₱${_cartTotal.toStringAsFixed(2)}'
                                        : 'Ilagay ang sapat na bayad',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final AsyncValue<InventoryState> invAsync = ref.watch(inventoryProvider);

    return StoreScaffold(
      storeType: StoreType.rice,
      headerTitle: 'Bigasan POS',
      headerActions: <Widget>[
        IconButton(
          icon: const Icon(Icons.qr_code_2),
          tooltip: 'Print QR Labels',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => const QrLabelPreviewScreen(),
            ),
          ),
        ),
      ],
      body: Container(
        color: c.background,
        child: Column(
          children: <Widget>[
            // Search Bar + Print QR quick button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.borderSubtle),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: c.text,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Maghanap ng bigas / sako...',
                          hintStyle: TextStyle(
                            color: c.textTertiary,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: c.textSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close,
                                      size: 18, color: c.textSecondary),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const QrLabelPreviewScreen(),
                      ),
                    ),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.borderSubtle),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: <Widget>[
                          Icon(Icons.qr_code_2_rounded,
                              color: _brand, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Labels',
                            style: TextStyle(
                              color: Color(0xFF1F1A17),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Variety filter pills
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _varieties.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, int i) {
                  final String variety = _varieties[i];
                  final bool selected = variety == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = variety),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? c.primary : c.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: selected ? c.primary : c.borderSubtle,
                        ),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x05000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          variety,
                          style: TextStyle(
                            color: selected ? Colors.white : c.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Rice Bins Grid
            Expanded(
              child: invAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object e, _) => Center(
                  child: Text('Error: $e',
                      style: const TextStyle(color: Colors.redAccent)),
                ),
                data: (InventoryState state) => _buildBinGrid(state),
              ),
            ),
          ],
        ),
      ),

      // Sticky Bottom Checkout Dock (Matches Inspo Image 1)
      bottomBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.borderSubtle)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Notice banner + Alisin button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F2EB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDE8E1)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32), size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Sa device na ito naka-save ang mga benta',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF5A524C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_cart.isNotEmpty)
                    GestureDetector(
                      onTap: _clearCart,
                      child: const Text(
                        'Alisin',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Payment method toggle chips
              Row(
                children: <String>['Cash', '✓ GCash', 'Utang'].map((String m) {
                  final String rawName = m.replaceAll('✓ ', '');
                  final bool selected = _paymentMethod == rawName;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = rawName),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF1E1C1A)
                                : const Color(0xFFF7F5F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF1E1C1A)
                                  : const Color(0xFFEDE8E1),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              m,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : const Color(0xFF5A524C),
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Total + Crimson Bayaran Button
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${_cart.length} ${_cart.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            color: Color(0xFF7A7269),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₱${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF1F1A17),
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _cart.isEmpty ? null : _showCartSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFE5E0D8),
                        disabledForegroundColor: const Color(0xFF9E958C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Text(
                            'Bayaran',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBinGrid(InventoryState state) {
    final List<Product> rawItems = state.products;

    if (rawItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.rice_bowl_outlined, size: 54, color: Color(0xFFDDD5CE)),
            SizedBox(height: 12),
            Text(
              'Walang bigas na naka-set up.\nMag-dagdag sa Inventory muna.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF7A7269),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Apply search filter and variety filter
    final String query = _searchCtrl.text.trim().toLowerCase();
    final List<Product> items = rawItems.where((Product p) {
      final String cat = p.categoryName ?? 'Well-Milled';
      final bool matchesCategory = _selectedCategory == 'Lahat' ||
          cat.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          p.name.toLowerCase().contains(_selectedCategory.toLowerCase());
      final bool matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          cat.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        final int cols = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext ctx, int index) {
            final Product item = items[index];
            final String? inCartLabel = _inCartLabelFor(item.productId);
            return _BinTile(
              item: item,
              binNumber: index + 1,
              inCartLabel: inCartLabel,
              onTap: () => _openWeightDialog(item),
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Bin Tile (Clean White Card matching Inspo Image 1)
// ──────────────────────────────────────────────────────────────────────────────

class _BinTile extends StatelessWidget {
  const _BinTile({
    required this.item,
    required this.binNumber,
    required this.inCartLabel,
    required this.onTap,
  });

  final Product item;
  final int binNumber;
  final String? inCartLabel;
  final VoidCallback onTap;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final bool isOut = item.stockQty <= 0;
    final bool isLow = item.isLowStock;
    final bool inCart = inCartLabel != null;

    return GestureDetector(
      onTap: isOut ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: inCart
                ? c.primary
                : isOut
                    ? c.error.withValues(alpha: 0.5)
                    : c.borderSubtle,
            width: inCart ? 1.8 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: inCart
                  ? c.primary.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Top row: Bin number badge + in-cart amber badge or status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'BIN #$binNumber',
                      style: TextStyle(
                        color: c.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  if (inCart)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: c.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        inCartLabel!,
                        style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else if (isOut)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'UBOS',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else if (isLow)
                    const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFD97706), size: 16),
                ],
              ),
              const Spacer(),

              // Center: Grain Squircle Icon
              Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: c.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.rice_bowl_rounded,
                    color: _brand,
                    size: 26,
                  ),
                ),
              ),
              const Spacer(),

              // Variety name
              Text(
                item.name,
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.categoryName ?? 'Well-Milled',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price & Stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '₱${item.unitPrice.toStringAsFixed(2)}/kg',
                    style: TextStyle(
                      color: isOut
                          ? const Color(0xFF9E958C)
                          : const Color(0xFF1F1A17),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    isOut ? 'Ubos na' : '${item.stockQty} kg',
                    style: TextStyle(
                      color: isOut
                          ? const Color(0xFFDC2626)
                          : isLow
                              ? const Color(0xFFD97706)
                              : const Color(0xFF7A7269),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Button
              if (!isOut)
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          inCart ? _brand : const Color(0xFFFFFBEB),
                      foregroundColor:
                          inCart ? Colors.white : const Color(0xFFB45309),
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: inCart ? _brand : const Color(0xFFFDE68A),
                        ),
                      ),
                    ),
                    child: Text(
                      inCart ? '+ Baguhin' : '+ Timbangin',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
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

// ──────────────────────────────────────────────────────────────────────────────
// Weight Chip & Sack Button (Clean Light Styling)
// ──────────────────────────────────────────────────────────────────────────────

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.kg,
    required this.selected,
    required this.onTap,
  });

  final double kg;
  final bool selected;
  final VoidCallback onTap;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _brand : const Color(0xFFF7F5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _brand : const Color(0xFFEDE8E1),
          ),
        ),
        child: Text(
          '${kg % 1 == 0 ? kg.toInt() : kg} kg',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF4A423D),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SackButton extends StatelessWidget {
  const _SackButton({
    required this.label,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  static const Color _brand = StoreColors.rice;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFFBEB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _brand : const Color(0xFFEDE8E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFB45309)
                    : const Color(0xFF1F1A17),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₱${price.toStringAsFixed(2)}',
              style: TextStyle(
                color: selected
                    ? const Color(0xFFB45309)
                    : const Color(0xFF7A7269),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
