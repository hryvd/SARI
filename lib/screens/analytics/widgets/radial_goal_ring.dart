import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class RadialGoalRing extends StatelessWidget {
  const RadialGoalRing({
    super.key,
    required this.achieved,
    required this.target,
    required this.accentColor,
    this.onTapChangeTarget,
  });

  final double achieved;
  final double target;
  final Color accentColor;
  final VoidCallback? onTapChangeTarget;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final double safeTarget = target > 0 ? target : 1.0;
    final double ratio = (achieved / safeTarget).clamp(0.0, 1.5);
    final int percentage = (ratio * 100).toInt();
    final double gap = target - achieved;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.track_changes_rounded, size: 18, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    'Arawang Target (Sales Goal)',
                    style: TextStyle(
                      color: c.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (onTapChangeTarget != null)
                InkWell(
                  onTap: onTapChangeTarget,
                  child: Text(
                    'Baguhin',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              // ── Canvas-painted radial arc ──────────────────────────────────
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _RadialGoalRingPainter(
                    progress: ratio.clamp(0.0, 1.0),
                    trackColor: c.border.withValues(alpha: 0.45),
                    fillColor: accentColor,
                    strokeWidth: 10,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            color: c.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ratio >= 1.0 ? 'Abot!' : 'Takbo',
                          style: TextStyle(
                            color: ratio >= 1.0 ? const Color(0xFF2E7D32) : c.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // ── Metric Labels ──────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TargetMetricRow(
                      label: 'Arawang Target:',
                      value: '₱${target.toStringAsFixed(2)}',
                      valueColor: c.text,
                    ),
                    const SizedBox(height: 6),
                    _TargetMetricRow(
                      label: 'Naabot:',
                      value: '₱${achieved.toStringAsFixed(2)}',
                      valueColor: accentColor,
                      isBold: true,
                    ),
                    const SizedBox(height: 6),
                    _TargetMetricRow(
                      label: gap > 0 ? 'Kulang na lang:' : 'Lampas ng:',
                      value: gap > 0
                          ? '₱${gap.toStringAsFixed(2)}!'
                          : '+₱${(-gap).toStringAsFixed(2)}',
                      valueColor: gap > 0 ? const Color(0xFFFFB300) : const Color(0xFF2E7D32),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetMetricRow extends StatelessWidget {
  const _TargetMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(color: c.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RadialGoalRingPainter extends CustomPainter {
  const _RadialGoalRingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // Background track ring
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc
    final Paint progressPaint = Paint()
      ..color = fillColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from top (-pi / 2)
    const double startAngle = -math.pi / 2;
    final double sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGoalRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.trackColor != trackColor;
  }
}
