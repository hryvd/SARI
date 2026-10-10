/// label_printer.dart
/// Pure-Dart service — no Flutter imports.
/// Generates an A4 PDF sheet of QR bin labels for Bigasan rice varieties.
/// Uses the `pdf` package (already in pubspec).
library;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr/qr.dart';

/// One label's worth of data.
class BinLabelData {
  const BinLabelData({
    required this.variety,
    required this.millingGrade,
    required this.pricePerKg,
    required this.qrPayload,
    this.sackPrice25kg,
    this.sackPrice50kg,
    this.binNumber,
  });

  final String variety;
  final String millingGrade;
  final double pricePerKg;
  final String qrPayload;
  final double? sackPrice25kg;
  final double? sackPrice50kg;
  final int? binNumber;

  String get pricePerKgStr => '₱${pricePerKg.toStringAsFixed(2)}/kg';
}

/// Generates a printable A4 PDF sheet of QR bin labels.
///
/// Layout: 2-column × 4-row grid = 8 labels per page, 54mm × 68mm each.
class LabelPrinter {
  LabelPrinter._();

  static const int _cols = 2;
  static const int _rows = 4;
  static const int _labelsPerPage = _cols * _rows;

  /// Returns the raw PDF bytes for a list of [BinLabelData].
  /// Pages are added automatically when [labels] exceeds 8.
  static Future<List<int>> generateSheet(List<BinLabelData> labels) async {
    final pw.Document doc = pw.Document(
      title: 'Bigasan Bin QR Labels',
      author: 'SARI POS',
    );

    // Split labels into pages
    final List<List<BinLabelData>> pages = <List<BinLabelData>>[];
    for (int i = 0; i < labels.length; i += _labelsPerPage) {
      pages.add(
        labels.sublist(
          i,
          (i + _labelsPerPage).clamp(0, labels.length),
        ),
      );
    }
    // Always at least one page (even if empty, for print preview)
    if (pages.isEmpty) {
      pages.add(<BinLabelData>[]);
    }

    for (final List<BinLabelData> pageLabels in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) => _buildPage(ctx, pageLabels),
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildPage(
    pw.Context ctx,
    List<BinLabelData> labels,
  ) {
    // Fill remaining slots with null to keep grid alignment
    final List<BinLabelData?> cells = List<BinLabelData?>.from(labels);
    while (cells.length < _labelsPerPage) {
      cells.add(null);
    }

    return pw.GridView(
      crossAxisCount: _cols,
      childAspectRatio: 54 / 68,
      children: cells.map(_buildLabel).toList(),
    );
  }

  static pw.Widget _buildLabel(BinLabelData? data) {
    if (data == null) {
      return pw.Container(); // empty cell
    }

    // Build QR code matrix
    final pw.Widget qrWidget = _buildQrWidget(data.qrPayload);

    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          // Bin number badge
          if (data.binNumber != null)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              child: pw.Text(
                'BIN #${data.binNumber}',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          pw.SizedBox(height: 4),
          // QR code
          pw.Expanded(child: pw.Center(child: qrWidget)),
          pw.SizedBox(height: 4),
          // Variety name
          pw.Text(
            data.variety,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
          // Grade
          pw.Text(
            data.millingGrade,
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          // Price per kg — large
          pw.Text(
            data.pricePerKgStr,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          // Sack prices
          if (data.sackPrice25kg != null || data.sackPrice50kg != null)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: <pw.Widget>[
                if (data.sackPrice25kg != null)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 4),
                    child: pw.Text(
                      '25kg ₱${data.sackPrice25kg!.toStringAsFixed(0)}',
                      style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                    ),
                  ),
                if (data.sackPrice50kg != null)
                  pw.Text(
                    '50kg ₱${data.sackPrice50kg!.toStringAsFixed(0)}',
                    style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700),
                  ),
              ],
            ),
          pw.SizedBox(height: 2),
          // QR payload text (small, for manual entry fallback)
          pw.Text(
            data.qrPayload,
            style: const pw.TextStyle(fontSize: 5, color: PdfColors.grey500),
            textAlign: pw.TextAlign.center,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  /// Renders a QR code as a [pw.Widget] using the `qr` package to build the
  /// module matrix, then draws each dark module as a tiny filled rectangle.
  static pw.Widget _buildQrWidget(String data) {
    final QrCode qr = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final QrImage qrImage = QrImage(qr);
    final int moduleCount = qr.moduleCount;

    return pw.AspectRatio(
      aspectRatio: 1,
      child: pw.CustomPaint(
        painter: (PdfGraphics canvas, PdfPoint size) {
          final double cellSize = size.x / moduleCount;
          for (int row = 0; row < moduleCount; row++) {
            for (int col = 0; col < moduleCount; col++) {
              if (qrImage.isDark(row, col)) {
                canvas
                  ..setFillColor(PdfColors.black)
                  ..drawRect(
                    col * cellSize,
                    size.y - (row + 1) * cellSize,
                    cellSize,
                    cellSize,
                  )
                  ..fillPath();
              }
            }
          }
        },
      ),
    );
  }

  /// Utility: convert an [ItemRice]-like map into [BinLabelData].
  static BinLabelData fromMap(Map<String, dynamic> m, {int? binNumber}) {
    return BinLabelData(
      variety: m['variety'] as String? ?? '',
      millingGrade: m['milling_grade'] as String? ?? 'Well-Milled',
      pricePerKg: (m['price_per_kg'] as num? ?? 0.0).toDouble(),
      qrPayload: m['qr_payload'] as String? ?? '',
      sackPrice25kg: (m['sack_price_25kg'] as num?)?.toDouble(),
      sackPrice50kg: (m['sack_price_50kg'] as num?)?.toDouble(),
      binNumber: binNumber,
    );
  }
}
