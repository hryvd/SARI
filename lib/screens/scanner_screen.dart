import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/cart_provider.dart';
import '../application/inventory_provider.dart';
import '../domain/entities/buyer_order.dart';
import '../domain/entities/product.dart';
import '../domain/entities/transaction.dart';
import '../domain/services/buyer_order_service.dart';
import '../theme/app_theme.dart';
import 'barcode_scanner_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Lahat';
  bool _hideOfflineNotice = false;

  static const List<String> _categories = <String>[
    'Lahat',
    'Noodles',
    'Drinks',
    'Snacks',
    'Fresh',
    'Rice',
    'Home',
    'Cooking',
    'Canned',
  ];

  static final List<Product> _defaultFallbackProducts = <Product>[
    Product(
      productId: 'seed_pos_1',
      name: 'Lucky Me Pancit Canton',
      unitPrice: 16.0,
      costPrice: 12.5,
      stockQty: 14,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Noodles',
      barcode: '4800016004310',
    ),
    Product(
      productId: 'seed_pos_2',
      name: 'Kopiko 3-in-1',
      unitPrice: 8.0,
      costPrice: 6.2,
      stockQty: 42,
      threshold: 15,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Drinks',
      barcode: '4800016004314',
    ),
    Product(
      productId: 'seed_pos_3',
      name: 'Coke Sakto',
      unitPrice: 15.0,
      costPrice: 12.0,
      stockQty: 18,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Drinks',
      barcode: '4800016004311',
    ),
    Product(
      productId: 'seed_pos_4',
      name: 'Piattos',
      unitPrice: 20.0,
      costPrice: 16.0,
      stockQty: 9,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Snacks',
      barcode: '4800016004309',
    ),
    Product(
      productId: 'seed_pos_5',
      name: 'Itlog (1 pc)',
      unitPrice: 9.0,
      costPrice: 7.5,
      stockQty: 29,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Fresh',
    ),
    Product(
      productId: 'seed_pos_6',
      name: 'Bigas Sinandomeng (1 kg)',
      unitPrice: 58.0,
      costPrice: 52.0,
      stockQty: 2,
      threshold: 5,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Rice',
    ),
    Product(
      productId: 'seed_pos_7',
      name: 'Safeguard',
      unitPrice: 38.0,
      costPrice: 31.0,
      stockQty: 11,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Home',
    ),
    Product(
      productId: 'seed_pos_8',
      name: 'Surf Sachet',
      unitPrice: 7.0,
      costPrice: 5.4,
      stockQty: 60,
      threshold: 15,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Home',
    ),
    Product(
      productId: 'seed_pos_9',
      name: 'Mang Tomas',
      unitPrice: 24.0,
      costPrice: 19.0,
      stockQty: 10,
      threshold: 5,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Cooking',
    ),
    Product(
      productId: 'seed_pos_10',
      name: 'Nissin Cup Noodles',
      unitPrice: 28.0,
      costPrice: 23.0,
      stockQty: 19,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Noodles',
    ),
    Product(
      productId: 'seed_pos_11',
      name: 'Payless Pancit Canton',
      unitPrice: 14.0,
      costPrice: 11.0,
      stockQty: 25,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Noodles',
    ),
    Product(
      productId: 'seed_pos_12',
      name: 'Milo Sachet',
      unitPrice: 9.0,
      costPrice: 7.0,
      stockQty: 35,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Drinks',
    ),
    Product(
      productId: 'seed_pos_13',
      name: 'C2 Green Tea 230 ml',
      unitPrice: 20.0,
      costPrice: 16.0,
      stockQty: 23,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Drinks',
    ),
    Product(
      productId: 'seed_pos_14',
      name: 'Chippy BBQ',
      unitPrice: 10.0,
      costPrice: 8.0,
      stockQty: 39,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Snacks',
    ),
    Product(
      productId: 'seed_pos_15',
      name: 'Oishi Prawn Crackers',
      unitPrice: 12.0,
      costPrice: 9.5,
      stockQty: 22,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Snacks',
    ),
    Product(
      productId: 'seed_pos_16',
      name: 'Ligo Sardinas',
      unitPrice: 24.0,
      costPrice: 20.0,
      stockQty: 16,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Canned',
    ),
    Product(
      productId: 'seed_pos_17',
      name: 'Century Tuna Flakes',
      unitPrice: 38.0,
      costPrice: 30.0,
      stockQty: 12,
      threshold: 6,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Canned',
      barcode: '4800016004315',
    ),
    Product(
      productId: 'seed_pos_18',
      name: 'Silver Swan Toyo',
      unitPrice: 18.0,
      costPrice: 14.0,
      stockQty: 18,
      threshold: 8,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Cooking',
      barcode: '4800016004316',
    ),
    Product(
      productId: 'seed_pos_19',
      name: 'Datu Puti Suka',
      unitPrice: 18.0,
      costPrice: 14.0,
      stockQty: 14,
      threshold: 8,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Cooking',
    ),
    Product(
      productId: 'seed_pos_20',
      name: 'Asin (Iodized)',
      unitPrice: 10.0,
      costPrice: 7.0,
      stockQty: 30,
      threshold: 10,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      categoryName: 'Cooking',
    ),
  ];

  static IconData _getCategoryIcon(String? catName, String pName) {
    final String c = (catName ?? '').toLowerCase();
    final String p = pName.toLowerCase();
    if (c.contains('noodle') || p.contains('noodle') || p.contains('canton')) {
      return Icons.ramen_dining_outlined;
    }
    if (c.contains('drink') ||
        c.contains('beverage') ||
        p.contains('kopiko') ||
        p.contains('coke') ||
        p.contains('milo') ||
        p.contains('tea')) {
      return Icons.local_drink_outlined;
    }
    if (c.contains('snack') ||
        p.contains('piattos') ||
        p.contains('chippy') ||
        p.contains('oishi') ||
        p.contains('cracker')) {
      return Icons.cookie_outlined;
    }
    if (c.contains('fresh') || c.contains('egg') || p.contains('itlog')) {
      return Icons.egg_outlined;
    }
    if (c.contains('rice') || c.contains('grain') || p.contains('bigas')) {
      return Icons.grain_outlined;
    }
    if (c.contains('home') ||
        c.contains('soap') ||
        p.contains('safeguard') ||
        p.contains('surf') ||
        p.contains('colgate')) {
      return Icons.cleaning_services_outlined;
    }
    if (c.contains('canned') || p.contains('sardinas') || p.contains('tuna')) {
      return Icons.inventory_2_outlined;
    }
    if (c.contains('cook') ||
        c.contains('condiment') ||
        p.contains('toyo') ||
        p.contains('suka') ||
        p.contains('asin') ||
        p.contains('mang tomas') ||
        p.contains('oil')) {
      return Icons.soup_kitchen_outlined;
    }
    return Icons.shopping_bag_outlined;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  /// Shows a blocking dialog when quantity exceeds available stock.
  void _showStockWarning(String productName, int available) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        icon: Icon(Icons.warning_amber_rounded,
            color: appColors(ctx).warning, size: 36),
        title: const Text('Not enough stock'),
        content: Text(
          '"$productName" only has $available available in stock.\n\n'
          'Please adjust the quantity or restock the product first.',
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Asks the user to confirm before removing an item from the cart.
  Future<void> _confirmRemoveItem(String productName, String productId) async {
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        icon: Icon(Icons.remove_shopping_cart_outlined,
            color: appColors(ctx).warning, size: 36),
        title: const Text('Remove Item?'),
        content: Text(
          'Are you sure you want to remove "$productName" from the cart?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: appColors(ctx).error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(cartProvider.notifier).removeItem(productId);
    }
  }

  // ─── Checkout Dialog ─────────────────────────────────────────────────────

  Future<void> _showCheckoutDialog() async {
    final CartState cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      _showMessage('Cart is empty');
      return;
    }

    final TextEditingController cashCtrl = TextEditingController();
    final TextEditingController mobileCtrl = TextEditingController();
    String method = cart.paymentMethod;
    String? cashError;
    // Load all configured QR entries (decoded data strings)
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Static defaults
    final List<String> staticKeys = <String>[
      'qr_gcash',
      'qr_maya',
      'qr_bdo',
      'qr_bpi',
      'qr_gotyme',
      'qr_unionbank',
      'qr_maribank',
      'qr_custom',
    ];
    final Map<String, String> staticLabels = <String, String>{
      'qr_gcash': 'GCash',
      'qr_maya': 'Maya',
      'qr_bdo': 'BDO',
      'qr_bpi': 'BPI',
      'qr_gotyme': 'GoTyme',
      'qr_unionbank': 'UnionBank',
      'qr_maribank': 'MariBank',
      'qr_custom': 'Bangko QR',
    };
    // Dynamic extras
    final int extraCount = prefs.getInt('qr_extra_count') ?? 0;

    final List<Map<String, String?>> qrEntries = <Map<String, String?>>[
      for (final String k in staticKeys)
        <String, String?>{
          'key': k,
          'label': prefs.getString('${k}_label') ?? staticLabels[k],
          'data': prefs.getString('${k}_qrdata'),
        },
      for (int i = 0; i < extraCount; i++)
        <String, String?>{
          'key': 'qr_extra_$i',
          'label': prefs.getString('qr_extra_${i}_label') ?? 'Other ${i + 1}',
          'data': prefs.getString('qr_extra_${i}_qrdata'),
        },
    ].where((Map<String, String?> e) {
      final String? d = e['data'];
      return d != null && d.isNotEmpty;
    }).toList();

    String? selectedQrKey =
        qrEntries.isNotEmpty ? qrEntries.first['key'] : null;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        final AppColors c = appColors(ctx);
        return StatefulBuilder(
          builder: (BuildContext ctx2, StateSetter setS) {
            final double total = ref.read(cartProvider).total;
            final double tendered = double.tryParse(cashCtrl.text) ?? 0;
            final double change = method == 'cash'
                ? (tendered - total).clamp(0, double.infinity)
                : 0;

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: const Text('Checkout'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Total
                    Text(
                      'Total: ₱${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22),
                    ),
                    const SizedBox(height: 16),

                    // Payment method toggle
                    Row(children: <Widget>[
                      Expanded(
                        child: _PaymentChip(
                          label: 'Cash',
                          icon: Icons.payments_outlined,
                          selected: method == 'cash',
                          onTap: () => setS(() {
                            method = 'cash';
                            cashError = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _PaymentChip(
                          label: 'E-Wallet / QR',
                          icon: Icons.qr_code_outlined,
                          selected: method == 'ewallet',
                          disabled: qrEntries.isEmpty,
                          disabledHint: 'No QR set up in Profile',
                          onTap: qrEntries.isEmpty
                              ? null
                              : () => setS(() => method = 'ewallet'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),

                    // Cash fields
                    if (method == 'cash') ...<Widget>[
                      TextField(
                        controller: cashCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cash tendered (PHP)',
                          prefixText: '₱ ',
                          errorText: cashError,
                        ),
                        onChanged: (_) => setS(() => cashError = null),
                      ),
                      if (tendered >= total && tendered > 0) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          'Change: ₱${change.toStringAsFixed(2)}',
                          style: TextStyle(
                              color: c.info, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ],

                    // E-Wallet QR display
                    if (method == 'ewallet') ...<Widget>[
                      const SizedBox(height: 8),
                      if (qrEntries.isEmpty) ...<Widget>[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(children: <Widget>[
                            Icon(Icons.qr_code_2,
                                size: 48, color: c.textTertiary),
                            const SizedBox(height: 8),
                            Text('No payment QR set up.',
                                style: TextStyle(color: c.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              'Go to Profile → Payment QR Codes to upload.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: c.textTertiary, fontSize: 12),
                            ),
                          ]),
                        ),
                      ] else ...<Widget>[
                        // QR selector chips
                        if (qrEntries.length > 1)
                          Wrap(
                            spacing: 8,
                            children: qrEntries.map((Map<String, String?> e) {
                              final bool sel = selectedQrKey == e['key'];
                              return ChoiceChip(
                                label: Text(e['label'] ?? ''),
                                selected: sel,
                                onSelected: (_) =>
                                    setS(() => selectedQrKey = e['key']),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 8),
                        // Display selected regenerated QR
                        Builder(builder: (BuildContext _) {
                          final Map<String, String?>? entry = qrEntries
                              .cast<Map<String, String?>?>()
                              .firstWhere(
                                (Map<String, String?>? e) =>
                                    e!['key'] == selectedQrKey,
                                orElse: () => qrEntries.first,
                              );
                          final String? rawData = entry?['data'];
                          if (rawData == null) return const SizedBox.shrink();

                          // If it's a fallback image path
                          if (rawData.startsWith('IMAGE:')) {
                            final String imgPath = rawData.substring(6);
                            return Center(
                              child: Column(children: <Widget>[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(File(imgPath),
                                      height: 200, fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Customer scans & enters ₱${total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: c.textSecondary, fontSize: 13),
                                ),
                              ]),
                            );
                          }

                          // Regenerated brand-colored QR
                          return Center(
                            child: Column(children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: c.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: c.primary.withValues(alpha: 0.25)),
                                ),
                                child: SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: QrImageView(
                                    data: rawData,
                                    version: QrVersions.auto,
                                    size: 200,
                                    backgroundColor: Colors.transparent,
                                    eyeStyle: QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: c.primaryDark,
                                    ),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: c.primaryDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Customer scans & enters ₱${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: c.textSecondary, fontSize: 13),
                              ),
                            ]),
                          );
                        }),
                      ],
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 12),

                    // Customer mobile (optional)
                    TextField(
                      controller: mobileCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Customer mobile (optional)',
                        hintText: '09xxxxxxxxx',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // ── Validate BEFORE closing dialog ──
                    if (method == 'cash') {
                      final double t = double.tryParse(cashCtrl.text) ?? 0;
                      if (t < total) {
                        setS(() => cashError =
                            'Enter at least ₱${total.toStringAsFixed(2)}');
                        return; // keep dialog open
                      }
                      ref.read(cartProvider.notifier).setTenderedCash(t);
                    }

                    // ── Guard: block ewallet if no QR codes configured ──
                    if (method == 'ewallet' && qrEntries.isEmpty) {
                      await showDialog<void>(
                        context: ctx,
                        builder: (BuildContext dCtx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          icon: Icon(Icons.qr_code_2,
                              color: appColors(dCtx).warning, size: 36),
                          title: const Text('No Payment QR Set Up'),
                          content: const Text(
                            'You haven\'t uploaded any QR payment codes yet.\n\n'
                            'Go to Profile → Payment QR Codes to add your GCash, Maya, or other QR codes first.',
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dCtx),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                      return; // keep checkout dialog open
                    }

                    ref.read(cartProvider.notifier).setPaymentMethod(method);
                    // When ewallet is selected, store the specific provider label
                    if (method == 'ewallet' && selectedQrKey != null) {
                      final Map<String, String?>? entry =
                          qrEntries.cast<Map<String, String?>?>().firstWhere(
                                (Map<String, String?>? e) =>
                                    e!['key'] == selectedQrKey,
                                orElse: () => null,
                              );
                      if (entry != null && entry['label'] != null) {
                        ref
                            .read(cartProvider.notifier)
                            .setPaymentMethod('ewallet:${entry['label']}');
                      }
                    }
                    if (mobileCtrl.text.isNotEmpty) {
                      ref
                          .read(cartProvider.notifier)
                          .setCustomerMobile(mobileCtrl.text);
                    }

                    // Close dialog, then checkout
                    Navigator.pop(ctx);
                    final bool ok =
                        await ref.read(cartProvider.notifier).checkout();

                    if (ok && mounted) {
                      // Use postFrameCallback so receipt shows after
                      // the widget rebuilds from state change
                      final Receipt? receipt =
                          ref.read(cartProvider).lastReceipt;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _showReceiptDialog(receipt);
                      });
                    } else if (mounted) {
                      _showMessage(
                          ref.read(cartProvider).error ?? 'Checkout failed');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appColors(ctx).primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReceiptDialog(Receipt? receipt) async {
    if (receipt == null || !mounted) return;

    Map<String, dynamic> data = <String, dynamic>{};
    List<dynamic> items = <dynamic>[];
    try {
      // New format: human-readable text then ##JSON##<jsonstring>
      // Old format: raw JSON (backwards compat)
      final String payload = receipt.qrPayload;
      final int sepIdx = payload.indexOf('##JSON##');
      final String jsonStr =
          sepIdx >= 0 ? payload.substring(sepIdx + 8) : payload;
      data = jsonDecode(jsonStr) as Map<String, dynamic>;
      items = (data['items'] as List<dynamic>?) ?? <dynamic>[];
    } catch (_) {}

    final String payMethod =
        (data['payment_method'] as String? ?? 'cash').toUpperCase();
    final double total = (data['total'] as num?)?.toDouble() ?? 0;
    final double changeDue = ref.read(cartProvider).changeDue;
    final String dateStr = '${receipt.timestamp.year}-'
        '${receipt.timestamp.month.toString().padLeft(2, '0')}-'
        '${receipt.timestamp.day.toString().padLeft(2, '0')} '
        '${receipt.timestamp.hour.toString().padLeft(2, '0')}:'
        '${receipt.timestamp.minute.toString().padLeft(2, '0')}';

    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        final AppColors c = appColors(ctx);
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // ── Header ──
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 36),
                      const SizedBox(height: 6),
                      Text(
                        receipt.storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        receipt.receiptId.startsWith('REF-')
                            ? receipt.receiptId
                            : 'Receipt #${receipt.receiptId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                    ],
                  ),
                ),

                // ── Items list ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ...items.map((dynamic it) {
                          final Map<String, dynamic> item =
                              it as Map<String, dynamic>;
                          final String name = item['name'] as String? ?? '-';
                          final int qty = (item['qty'] as num?)?.toInt() ?? 1;
                          final double price =
                              (item['price'] as num?)?.toDouble() ?? 0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    '$qty× $name',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '₱${(qty * price).toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: c.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }),
                        Divider(color: c.border, height: 20),

                        // ── Totals ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Payment',
                                style: TextStyle(fontSize: 12)),
                            Text(payMethod,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('TOTAL',
                                style: TextStyle(
                                    color: c.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                            Text(
                              '₱${total.toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: c.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20),
                            ),
                          ],
                        ),
                        if (payMethod == 'CASH' && changeDue > 0) ...<Widget>[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text('Change',
                                  style:
                                      TextStyle(color: c.info, fontSize: 13)),
                              Text(
                                '₱${changeDue.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: c.info,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // ── Receipt QR (colored) ──
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: c.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: c.primary.withValues(alpha: 0.25)),
                            ),
                            child: SizedBox(
                              width: 140,
                              height: 140,
                              child: QrImageView(
                                data: receipt.qrPayload,
                                version: QrVersions.auto,
                                size: 140,
                                backgroundColor: Colors.transparent,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: c.primaryDark,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: c.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Scan to verify receipt',
                            style:
                                TextStyle(color: c.textTertiary, fontSize: 11),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Actions ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
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
  }

  // Scan barcode → find product by barcode → add to cart directly
  Future<void> _scanAndAdd() async {
    final String? barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerView()),
    );
    if (barcode == null || barcode.isEmpty || !mounted) return;

    // Check if scanned QR is a Buyer Kiosk Order payload
    if (BuyerOrderService.isBuyerOrder(barcode)) {
      final BuyerOrder? order = BuyerOrderService.deserialize(barcode);
      if (order != null) {
        ref.read(cartProvider.notifier).stageBuyerOrder(order);
        _showMessage(
          'Na-scan ang Buyer Order #${order.orderId} (${order.totalItemCount} items, ₱${order.totalAmount.toStringAsFixed(2)})!',
        );
        setState(() {
          _searchCtrl.clear();
        });
        return;
      }
    }

    final CartNotifier notifier = ref.read(cartProvider.notifier);
    await notifier.search(barcode);
    final List<Product> results = ref.read(cartProvider).searchResults;
    if (results.isEmpty) {
      _showMessage('No product found for barcode: $barcode');
    } else {
      final Product p = results.first;
      if (p.stockQty <= 0) {
        _showStockWarning(p.name, 0);
      } else {
        final String? warn = notifier.addProduct(p);
        if (warn != null) {
          _showStockWarning(p.name, p.stockQty);
        } else {
          _showMessage('Added: ${p.name}');
        }
      }
    }
    notifier.search(''); // clear search results
    setState(() {
      _searchCtrl.clear();
    });
  }

  // ─── AI Scan ──────────────────────────────────────────────────────────────

  Future<void> _aiScan() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image == null || !mounted) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
            'https://serverless.roboflow.com/ryz-q9ol8/workflows/detect-count-and-visualize-3'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "api_key": "eqU5uR0sdzhRaTHf49yJ",
          "inputs": {
            "image": {"type": "base64", "value": base64Image}
          }
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // close loading

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _handleRoboflowResponse(data);
      } else {
        _showMessage(
            'AI Scan failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        _showMessage('Error during AI scan: $e');
      }
    }
  }

  void _handleRoboflowResponse(dynamic data) {
    List<Map<String, dynamic>> predictions = [];

    void extractPredictions(dynamic obj) {
      if (obj is Map) {
        if (obj.containsKey('class') && obj.containsKey('confidence')) {
          predictions.add(Map<String, dynamic>.from(obj));
        }
        for (final val in obj.values) {
          extractPredictions(val);
        }
      } else if (obj is List) {
        for (final val in obj) {
          extractPredictions(val);
        }
      }
    }

    extractPredictions(data);

    if (predictions.isEmpty) {
      _showMessage('AI could not identify any product in the image.');
      return;
    }

    predictions.sort((a, b) {
      final confA = (a['confidence'] as num?)?.toDouble() ?? 0.0;
      final confB = (b['confidence'] as num?)?.toDouble() ?? 0.0;
      return confB.compareTo(confA);
    });

    final String? detectedClass = predictions.first['class']?.toString();
    final double confidence =
        (predictions.first['confidence'] as num?)?.toDouble() ?? 0.0;

    if (detectedClass == null || detectedClass.isEmpty) {
      _showMessage('AI could not identify the product.');
      return;
    }

    _promptAiAdd(detectedClass, confidence);
  }

  Future<void> _promptAiAdd(String detectedClass, double confidence) async {
    final CartNotifier notifier = ref.read(cartProvider.notifier);
    // Search the local inventory for a matching product name
    await notifier.search(detectedClass);
    final List<Product> results = ref.read(cartProvider).searchResults;

    if (!mounted) return;

    if (results.isEmpty) {
      _showMessage(
          'AI detected "$detectedClass" (${(confidence * 100).toStringAsFixed(1)}%), but it is not in your inventory.');
      notifier.search('');
    } else {
      final Product p = results.first;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.auto_awesome,
              color: Colors.blueAccent, size: 36),
          title: const Text('AI Match Found'),
          content: Text(
              'AI detected: $detectedClass\nConfidence: ${(confidence * 100).toStringAsFixed(1)}%\n\nAdd "${p.name}" to cart?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                notifier.search('');
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appColors(ctx).primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                if (p.stockQty <= 0) {
                  _showStockWarning(p.name, 0);
                } else {
                  final String? warn = notifier.addProduct(p);
                  if (warn != null) {
                    _showStockWarning(p.name, p.stockQty);
                  } else {
                    _showMessage('Added: ${p.name}');
                  }
                }
                notifier.search('');
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    }
  }

  // ─── Cart Review Bottom Sheet ─────────────────────────────────────────────

  void _showCartDetailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetCtx) {
        return Consumer(
          builder: (BuildContext ctx, WidgetRef refWatcher, _) {
            final CartState currentCart = refWatcher.watch(cartProvider);
            if (currentCart.isEmpty) {
              Navigator.pop(sheetCtx);
              return const SizedBox.shrink();
            }
            final AppColors c = appColors(ctx);
            final int totalItemsCount = currentCart.items
                .fold<int>(0, (int s, CartItem i) => s + i.qty);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.shopping_bag_outlined,
                            color: Color(0xFFA31D1D), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Cart ($totalItemsCount item${totalItemsCount == 1 ? '' : 's'})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).clearCart();
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text('I-clear',
                              style: TextStyle(color: Colors.red)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: currentCart.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (BuildContext _, int index) {
                          final CartItem item = currentCart.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        item.product.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14),
                                      ),
                                      Text(
                                        '₱${item.product.unitPrice.toStringAsFixed(2)} bawat isa',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: c.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    IconButton(
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 20),
                                      onPressed: () {
                                        if (item.qty <= 1) {
                                          _confirmRemoveItem(item.product.name,
                                              item.product.productId);
                                        } else {
                                          ref
                                              .read(cartProvider.notifier)
                                              .changeQty(
                                                  item.product.productId, -1);
                                        }
                                      },
                                    ),
                                    Text(
                                      '${item.qty}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline,
                                          size: 20),
                                      onPressed: () {
                                        final String? warn = ref
                                            .read(cartProvider.notifier)
                                            .changeQty(
                                                item.product.productId, 1);
                                        if (warn != null) {
                                          _showStockWarning(item.product.name,
                                              item.product.stockQty);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 75,
                                  child: Text(
                                    '₱${item.subtotal.toStringAsFixed(2)}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFA31D1D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Kabuuan:',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '₱${currentCart.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFA31D1D),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA31D1D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          _showCheckoutDialog();
                        },
                        child: const Text(
                          'Ituloy ang Bayaran',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
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

// ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final CartState cart = ref.watch(cartProvider);

    // Watch SQLite products from inventoryProvider, fallback to catalog if empty
    final AsyncValue<InventoryState> invAsync = ref.watch(inventoryProvider);
    final List<Product> dbProducts =
        invAsync.value?.products ?? const <Product>[];
    final List<Product> allProducts =
        dbProducts.isNotEmpty ? dbProducts : _defaultFallbackProducts;

    // Filter by selected category and search input
    final String selectedCategory = _selectedCategory;
    final String query = _searchCtrl.text.trim().toLowerCase();

    final List<Product> displayProducts = allProducts.where((Product p) {
      if (selectedCategory != 'Lahat') {
        final String catName = (p.categoryName ?? '').toLowerCase();
        final String pName = p.name.toLowerCase();
        final String target = selectedCategory.toLowerCase();

        bool matches = false;
        if (target == 'noodles') {
          matches = catName.contains('noodle') ||
              pName.contains('noodle') ||
              pName.contains('canton');
        } else if (target == 'drinks') {
          matches = catName.contains('drink') ||
              catName.contains('beverage') ||
              pName.contains('kopiko') ||
              pName.contains('coke') ||
              pName.contains('milo') ||
              pName.contains('tea') ||
              pName.contains('c2');
        } else if (target == 'snacks') {
          matches = catName.contains('snack') ||
              pName.contains('piattos') ||
              pName.contains('chippy') ||
              pName.contains('oishi') ||
              pName.contains('cracker') ||
              pName.contains('tomas');
        } else if (target == 'fresh') {
          matches = catName.contains('fresh') ||
              catName.contains('egg') ||
              catName.contains('dairy') ||
              pName.contains('itlog');
        } else if (target == 'rice') {
          matches = catName.contains('rice') ||
              catName.contains('grain') ||
              pName.contains('bigas');
        } else if (target == 'home') {
          matches = catName.contains('home') ||
              catName.contains('personal') ||
              pName.contains('safeguard') ||
              pName.contains('surf') ||
              pName.contains('colgate');
        } else if (target == 'cooking') {
          matches = catName.contains('cook') ||
              catName.contains('condiment') ||
              pName.contains('toyo') ||
              pName.contains('suka') ||
              pName.contains('asin') ||
              pName.contains('oil') ||
              pName.contains('tomas');
        } else if (target == 'canned') {
          matches = catName.contains('canned') ||
              pName.contains('sardinas') ||
              pName.contains('tuna');
        } else {
          matches = catName.contains(target) || pName.contains(target);
        }
        if (!matches) return false;
      }

      if (query.isNotEmpty) {
        final bool matchName = p.name.toLowerCase().contains(query);
        final bool matchBarcode =
            (p.barcode ?? '').toLowerCase().contains(query);
        final bool matchCat =
            (p.categoryName ?? '').toLowerCase().contains(query);
        if (!matchName && !matchBarcode && !matchCat) return false;
      }

      return true;
    }).toList();

    // Mapping of product ID to cart quantity for amber badges
    final Map<String, int> inCartQuantities = <String, int>{
      for (final CartItem item in cart.items) item.product.productId: item.qty,
    };
    final int totalCartItems =
        cart.items.fold<int>(0, (int s, CartItem i) => s + i.qty);

    return Column(
      children: <Widget>[
        // ── Top Header Controls (Search + Quick Actions + Category Chips) ──
        Container(
          color: c.surface,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ── 1. Seamless Blended Search Input ──────────────────────
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.search, color: c.textSecondary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        style: TextStyle(color: c.text),
                        decoration: InputDecoration(
                          hintText: 'Hanapin ang produkto',
                          hintStyle: TextStyle(
                            color: c.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.clear,
                              size: 18, color: c.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── 2. Scan & AI Scan Highlight Blocks (Side-by-Side Cards) ──
              Row(
                children: <Widget>[
                  // Block 1: Barcode Scanner (Full SARI Red Card with Shadow)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scanAndAdd,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x33D62828),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(Icons.qr_code_scanner,
                                  color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'Barcode Scan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'I-scan ang paninda',
                                      style: TextStyle(
                                        color: Color(0xFFFDE8E8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Block 2: AI Vision Scan (White Card with Red Border & Shadow)
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _aiScan,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: c.primary, width: 1.5),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD62828),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      'AI Scan',
                                      style: TextStyle(
                                        color: Color(0xFFD62828),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'Visual recognition',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── 3. Horizontal Category Chips Row (Swipe Right) ───────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((String cat) {
                    final bool isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCategory = cat),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? c.primary : c.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? c.primary : c.borderSubtle,
                              width: 1,
                            ),
                            boxShadow: isSel
                                ? const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x33D62828),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (isSel) ...<Widget>[
                                const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                cat,
                                style: TextStyle(
                                  color: isSel ? Colors.white : c.text,
                                  fontWeight:
                                      isSel ? FontWeight.w800 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Main Content: Responsive Product Blocks Grid ───────────────────
        Expanded(
          child: displayProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.inventory_2_outlined,
                          size: 48, color: c.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        'Walang produktong tumugma sa "$_selectedCategory"',
                        style: TextStyle(
                            color: c.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (BuildContext ctx, BoxConstraints constraints) {
                    final double width = constraints.maxWidth;
                    final int crossAxisCount =
                        width >= 720 ? 4 : (width >= 480 ? 3 : 2);
                    final double aspectRatio =
                        width >= 720 ? 0.88 : (width >= 480 ? 0.86 : 0.84);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: displayProducts.length,
                      itemBuilder: (BuildContext _, int index) {
                        final Product p = displayProducts[index];
                        final int inCartQty =
                            inCartQuantities[p.productId] ?? 0;
                        final IconData catIcon =
                            _getCategoryIcon(p.categoryName, p.name);

                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final String? warn =
                                  ref.read(cartProvider.notifier).addProduct(p);
                              if (warn != null) {
                                _showStockWarning(p.name, p.stockQty);
                              }
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: inCartQty > 0
                                      ? const Color(0xFFE5A93C)
                                      : const Color(0xFFECE7E2),
                                  width: inCartQty > 0 ? 1.5 : 1,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // Top row: Category Icon + In-Cart Quantity Amber Badge
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      Icon(
                                        catIcon,
                                        size: 22,
                                        color: const Color(0xFFA31D1D),
                                      ),
                                      if (inCartQty > 0)
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE5A93C),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '$inCartQty',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 22),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Product name (bold, max 2 lines)
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      height: 1.18,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Price in bold red
                                  Text(
                                    '₱${p.unitPrice.toStringAsFixed(p.unitPrice.truncateToDouble() == p.unitPrice ? 0 : 2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFFA31D1D),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  // Stock indicator (red Natitira if low stock)
                                  p.isLowStock
                                      ? Text(
                                          'Natitira ${p.stockQty}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFA31D1D),
                                          ),
                                        )
                                      : Text(
                                          'Stock ${p.stockQty}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),

        // ── Sticky Checkout Dock (Matches Image 1) ─────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Offline notice banner (dismissible)
              if (!_hideOfflineNotice) ...<Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.error_outline,
                        size: 14, color: Color(0xFFA31D1D)),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Sa device na ito naka-save ang mga benta',
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _hideOfflineNotice = true),
                      child: const Text(
                        'Alisin',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Segmented payment buttons (Cash, GCash, Utang)
              Row(
                children: <Widget>[
                  _buildPaymentPill('Cash', 'cash', cart.paymentMethod),
                  const SizedBox(width: 8),
                  _buildPaymentPill('GCash', 'gcash', cart.paymentMethod),
                  const SizedBox(width: 8),
                  _buildPaymentPill('Utang', 'utang', cart.paymentMethod),
                ],
              ),
              const SizedBox(height: 10),

              // Summary row: Item count + Total + Bayaran button
              Row(
                children: <Widget>[
                  // Cart items & big total (tap to view cart details)
                  InkWell(
                    onTap: cart.isEmpty
                        ? null
                        : () => _showCartDetailsSheet(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                '$totalCartItems item',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black54),
                              ),
                              if (!cart.isEmpty) ...<Widget>[
                                const SizedBox(width: 4),
                                const Icon(Icons.keyboard_arrow_up,
                                    size: 14, color: Colors.black54),
                              ],
                            ],
                          ),
                          Text(
                            '₱${cart.total.toStringAsFixed(cart.total.truncateToDouble() == cart.total ? 0 : 2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Clear cart button if cart has items
                  if (!cart.isEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.black45,
                      tooltip: 'Clear Cart',
                      onPressed: () =>
                          ref.read(cartProvider.notifier).clearCart(),
                    ),
                  const SizedBox(width: 4),
                  // Solid Red Bayaran Pill Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: cart.isEmpty || cart.isProcessing
                          ? null
                          : _showCheckoutDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA31D1D),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: cart.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Bayaran',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentPill(String label, String key, String currentMethod) {
    final bool isSelected = currentMethod.toLowerCase() == key.toLowerCase();
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(cartProvider.notifier).setPaymentMethod(key);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD62828) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFD62828)
                  : const Color(0xFFDDD5CE),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33D62828),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isSelected) ...<Widget>[
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Payment Chip ─────────────────────────────────────────────────────────────

class _PaymentChip extends StatelessWidget {
  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.disabled = false,
    this.disabledHint,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final Color fgColor = disabled
        ? c.textTertiary
        : selected
            ? Colors.white
            : c.textSecondary;
    return Tooltip(
      message: disabled ? (disabledHint ?? '') : '',
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: disabled
                ? c.surfaceMuted.withValues(alpha: 0.5)
                : selected
                    ? const Color(0xFFD62828)
                    : c.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: disabled
                    ? c.borderSubtle
                    : selected
                        ? const Color(0xFFD62828)
                        : c.border,
                width: selected && !disabled ? 2 : 1),
            boxShadow: selected && !disabled
                ? const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x33D62828),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(children: <Widget>[
            Icon(icon, color: fgColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight:
                    selected && !disabled ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (disabled && disabledHint != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(
                disabledHint!,
                style: TextStyle(color: c.textTertiary, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
