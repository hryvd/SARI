import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

class BuyerQrView extends StatelessWidget {
  const BuyerQrView({
    super.key,
    required this.data,
    this.size = 220,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
  });

  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final QrCode qr = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    );
    final QrImage qrImage = QrImage(qr);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: _QrCustomPainter(
          qrImage: qrImage,
          moduleCount: qr.moduleCount,
          darkColor: color,
          lightColor: backgroundColor,
        ),
      ),
    );
  }
}

class _QrCustomPainter extends CustomPainter {
  const _QrCustomPainter({
    required this.qrImage,
    required this.moduleCount,
    required this.darkColor,
    required this.lightColor,
  });

  final QrImage qrImage;
  final int moduleCount;
  final Color darkColor;
  final Color lightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint darkPaint = Paint()..color = darkColor;
    final Paint lightPaint = Paint()..color = lightColor;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    final double cellSize = size.width / moduleCount;

    for (int row = 0; row < moduleCount; row++) {
      for (int col = 0; col < moduleCount; col++) {
        if (qrImage.isDark(row, col)) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * cellSize,
              row * cellSize,
              cellSize,
              cellSize,
            ),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCustomPainter oldDelegate) =>
      oldDelegate.qrImage != qrImage ||
      oldDelegate.darkColor != darkColor ||
      oldDelegate.lightColor != lightColor;
}
