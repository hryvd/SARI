import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../domain/entities/transaction.dart';
import '../../../theme/app_theme.dart';

class PeakHourHeatStrip extends StatelessWidget {
  const PeakHourHeatStrip({
    super.key,
    required this.transactions,
    required this.accentColor,
  });

  final List<Transaction> transactions;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);

    // Compute hourly transaction buckets (0..23)
    final List<int> hourlyCounts = List<int>.filled(24, 0);
    for (final Transaction t in transactions) {
      final int hour = t.timestamp.hour.clamp(0, 23);
      hourlyCounts[hour]++;
    }

    // Morning hours: 6 AM to 11 AM (indices 6 to 11)
    final List<int> morningCounts = hourlyCounts.sublist(6, 12);
    // Afternoon hours: 12 PM to 7 PM (indices 12 to 20)
    final List<int> afternoonCounts = hourlyCounts.sublist(12, 20);

    // Identify peak morning block
    final int morningMax = morningCounts.fold<int>(0, math.max);
    final int morningPeakIdx = morningCounts.indexOf(morningMax);
    final String morningPeakStr = morningMax > 0
        ? 'Peak: ${6 + morningPeakIdx}-${6 + morningPeakIdx + 2} AM'
        : 'Normal';

    // Identify peak afternoon block
    final int afternoonMax = afternoonCounts.fold<int>(0, math.max);
    final int afternoonPeakIdx = afternoonCounts.indexOf(afternoonMax);
    final int aftHour = (12 + afternoonPeakIdx);
    final int aftDisplay = aftHour > 12 ? aftHour - 12 : aftHour;
    final String afternoonPeakStr = afternoonMax > 0
        ? 'Peak: $aftDisplay-${aftDisplay + 2} PM'
        : 'Normal';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
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
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded, size: 18, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'Oras ng Bugso (Peak Hour Heat Strip)',
                style: TextStyle(
                  color: c.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Morning strip
          _HeatStripRow(
            label: 'Umaga (Morning):',
            peakText: morningPeakStr,
            counts: morningCounts,
            accentColor: accentColor,
            c: c,
          ),
          const SizedBox(height: 12),

          // Afternoon strip
          _HeatStripRow(
            label: 'Hapon (Afternoon):',
            peakText: afternoonPeakStr,
            counts: afternoonCounts,
            accentColor: accentColor,
            c: c,
          ),
        ],
      ),
    );
  }
}

class _HeatStripRow extends StatelessWidget {
  const _HeatStripRow({
    required this.label,
    required this.peakText,
    required this.counts,
    required this.accentColor,
    required this.c,
  });

  final String label;
  final String peakText;
  final List<int> counts;
  final Color accentColor;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    final int maxCount = counts.fold<int>(0, math.max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                peakText,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Strip cells
        Row(
          children: counts.map((count) {
            final double intensity = maxCount > 0 ? (count / maxCount) : 0.0;
            final Color cellColor;
            final BoxBorder border;

            if (count == 0) {
              cellColor = c.border.withValues(alpha: 0.3);
              border = Border.all(color: c.border.withValues(alpha: 0.6));
            } else if (intensity < 0.4) {
              cellColor = accentColor.withValues(alpha: 0.35);
              border = Border.all(color: accentColor.withValues(alpha: 0.5));
            } else if (intensity < 0.8) {
              cellColor = accentColor.withValues(alpha: 0.70);
              border = Border.all(color: accentColor.withValues(alpha: 0.8));
            } else {
              cellColor = accentColor;
              border = Border.all(color: Colors.white, width: 1.2);
            }

            return Expanded(
              child: Container(
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: cellColor,
                  borderRadius: BorderRadius.circular(4),
                  border: border,
                  boxShadow: count > 0 && intensity >= 0.8
                      ? <BoxShadow>[
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
