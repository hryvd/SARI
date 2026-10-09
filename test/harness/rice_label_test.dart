/// rice_label_test.dart
/// Contract tests for Phase 5: Bigasan QR Label Generator & Bin POS
///
/// SPEC: Bigasan Label Printer
/// CHECK: LabelPrinter.generateSheet returns non-empty bytes
/// CHECK: Each BinLabelData includes variety, grade, pricePerKg, qrPayload
/// CHECK: Prices are formatted to 2dp (₱65.00/kg)
/// CHECK: Sheet with > 8 labels spans multiple pages
/// CHECK: Empty label list still produces a valid PDF document
///
/// SPEC: Bigasan Bin POS
/// CHECK: Bin POS renders bin tiles from inventory items
/// CHECK: Weight × pricePerKg = correct total (exact cent arithmetic)
/// CHECK: Sack presets (25kg, 50kg) compute correct fixed prices
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:sare/domain/entities/item_rice.dart';
import 'package:sare/domain/services/label_printer.dart';
import 'package:sare/domain/services/scale_calculator.dart';

void main() {
  // ── LabelPrinter service tests ─────────────────────────────────────────────

  group('LabelPrinter', () {
    test('generateSheet returns non-empty bytes for one label', () async {
      final List<BinLabelData> labels = <BinLabelData>[
        const BinLabelData(
          variety: 'Sinandomeng',
          millingGrade: 'Well-Milled',
          pricePerKg: 65.0,
          qrPayload: 'RICE:sinandomeng:WM',
          binNumber: 1,
        ),
      ];

      final List<int> pdfBytes = await LabelPrinter.generateSheet(labels);
      expect(pdfBytes, isNotEmpty);
      // PDF files begin with %PDF
      expect(pdfBytes[0], equals(0x25)); // '%'
      expect(pdfBytes[1], equals(0x50)); // 'P'
      expect(pdfBytes[2], equals(0x44)); // 'D'
      expect(pdfBytes[3], equals(0x46)); // 'F'
    });

    test('generateSheet with empty list still produces valid PDF', () async {
      final List<int> pdfBytes = await LabelPrinter.generateSheet(<BinLabelData>[]);
      expect(pdfBytes, isNotEmpty);
    });

    test('generateSheet with > 8 labels produces multi-page PDF (bytes > single page)', () async {
      final List<BinLabelData> labels = List<BinLabelData>.generate(
        12,
        (int i) => BinLabelData(
          variety: 'Variety $i',
          millingGrade: 'Well-Milled',
          pricePerKg: 50.0 + i,
          qrPayload: 'RICE:variety_$i',
          binNumber: i + 1,
        ),
      );

      final List<BinLabelData> singlePageLabels = labels.sublist(0, 4);
      final List<int> multiBytes = await LabelPrinter.generateSheet(labels);
      final List<int> singleBytes = await LabelPrinter.generateSheet(singlePageLabels);

      // Multi-page PDF should be larger in bytes than single-page
      expect(multiBytes.length, greaterThan(singleBytes.length));
    });

    test('BinLabelData.pricePerKgStr formats to 2 decimal places', () {
      const BinLabelData label = BinLabelData(
        variety: 'NFA Regular',
        millingGrade: 'Regular Milled',
        pricePerKg: 45.5,
        qrPayload: 'RICE:nfa',
      );
      expect(label.pricePerKgStr, equals('₱45.50/kg'));
    });

    test('BinLabelData.pricePerKgStr for whole number', () {
      const BinLabelData label = BinLabelData(
        variety: 'Dinorado',
        millingGrade: 'Premium',
        pricePerKg: 80.0,
        qrPayload: 'RICE:dinorado',
      );
      expect(label.pricePerKgStr, equals('₱80.00/kg'));
    });

    test('LabelPrinter.fromMap creates BinLabelData correctly', () {
      final Map<String, dynamic> row = <String, dynamic>{
        'variety': 'Jasmine',
        'milling_grade': 'Special / Fragrant',
        'price_per_kg': 95.0,
        'qr_payload': 'RICE:jasmine:SF',
        'sack_price_25kg': 2250.0,
        'sack_price_50kg': 4400.0,
      };

      final BinLabelData label = LabelPrinter.fromMap(row, binNumber: 3);

      expect(label.variety, equals('Jasmine'));
      expect(label.millingGrade, equals('Special / Fragrant'));
      expect(label.pricePerKg, equals(95.0));
      expect(label.qrPayload, equals('RICE:jasmine:SF'));
      expect(label.sackPrice25kg, equals(2250.0));
      expect(label.sackPrice50kg, equals(4400.0));
      expect(label.binNumber, equals(3));
    });
  });

  // ── Scale arithmetic (rice) tests ──────────────────────────────────────────

  group('Bigasan weight → price (exact cent arithmetic)', () {
    test('3 kg × ₱65.00/kg = ₱195.00', () {
      final double total = ScaleCalculator.computePrice(
        weightKg: 3.0,
        pricePerKg: 65.0,
      );
      expect(total, equals(195.0));
    });

    test('2.5 kg × ₱80.00/kg = ₱200.00', () {
      final double total = ScaleCalculator.computePrice(
        weightKg: 2.5,
        pricePerKg: 80.0,
      );
      expect(total, equals(200.0));
    });

    test('1.2 kg × ₱95.00/kg = ₱114.00', () {
      final double total = ScaleCalculator.computePrice(
        weightKg: 1.2,
        pricePerKg: 95.0,
      );
      expect(total, equals(114.0));
    });

    test('ItemRice.computePrice 5 kg × ₱50.00/kg = ₱250.00', () {
      const ItemRice item = ItemRice(
        itemId: 'rice_01',
        variety: 'Sinandomeng',
        pricePerKg: 50.0,
        qrPayload: 'RICE:sinandomeng',
      );
      expect(item.computePrice(5.0), equals(250.0));
    });

    test('ItemRice.computePrice no floating point drift: 1.3 kg × ₱70.00', () {
      const ItemRice item = ItemRice(
        itemId: 'rice_02',
        variety: 'Dinorado',
        pricePerKg: 70.0,
        qrPayload: 'RICE:dinorado',
      );
      // 1.3 × 70 = 91.0 — should NOT be 91.00000000000001
      expect(item.computePrice(1.3), equals(91.0));
    });
  });

  // ── ItemRice entity tests ──────────────────────────────────────────────────

  group('ItemRice entity', () {
    test('isLowStock true when stockKg ≤ lowStockKg and > 0', () {
      const ItemRice item = ItemRice(
        itemId: 'r1',
        variety: 'Sinandomeng',
        pricePerKg: 65.0,
        qrPayload: 'RICE:r1',
        stockKg: 10.0,
        lowStockKg: 25.0,
      );
      expect(item.isLowStock, isTrue);
      expect(item.isOutOfStock, isFalse);
    });

    test('isOutOfStock true when stockKg = 0', () {
      const ItemRice item = ItemRice(
        itemId: 'r2',
        variety: 'NFA',
        pricePerKg: 41.0,
        qrPayload: 'RICE:r2',
        stockKg: 0.0,
      );
      expect(item.isOutOfStock, isTrue);
      expect(item.isLowStock, isFalse);
    });

    test('copyWith updates only specified fields', () {
      const ItemRice original = ItemRice(
        itemId: 'r3',
        variety: 'Glutinous',
        pricePerKg: 85.0,
        qrPayload: 'RICE:r3',
        stockKg: 100.0,
      );
      final ItemRice updated = original.copyWith(pricePerKg: 90.0);
      expect(updated.pricePerKg, equals(90.0));
      expect(updated.variety, equals('Glutinous'));
      expect(updated.stockKg, equals(100.0));
    });

    test('fromMap round-trips via toMap', () {
      const ItemRice original = ItemRice(
        itemId: 'r4',
        variety: 'Brown Rice',
        millingGrade: 'Brown / Red Rice',
        pricePerKg: 72.0,
        sackPrice25kg: 1750.0,
        sackPrice50kg: 3400.0,
        stockKg: 48.5,
        lowStockKg: 20.0,
        qrPayload: 'RICE:brown:BR',
      );
      final ItemRice restored = ItemRice.fromMap(original.toMap());

      expect(restored.itemId, equals(original.itemId));
      expect(restored.variety, equals(original.variety));
      expect(restored.millingGrade, equals(original.millingGrade));
      expect(restored.pricePerKg, equals(original.pricePerKg));
      expect(restored.sackPrice25kg, equals(original.sackPrice25kg));
      expect(restored.sackPrice50kg, equals(original.sackPrice50kg));
      expect(restored.stockKg, equals(original.stockKg));
      expect(restored.lowStockKg, equals(original.lowStockKg));
      expect(restored.qrPayload, equals(original.qrPayload));
    });
  });
}
