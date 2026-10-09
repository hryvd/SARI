import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../domain/entities/store_profile.dart';
import '../../../theme/app_theme.dart';

class CredibilityBadgeSheet extends StatelessWidget {
  const CredibilityBadgeSheet({
    super.key,
    this.profile,
  });

  final StoreProfile? profile;

  static void show(BuildContext context, StoreProfile? profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => CredibilityBadgeSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    final String storeName = profile?.storeName ?? 'Sar-E Store';
    final String ownerName = profile?.ownerName ?? 'Tindero / Tindera';
    final String storeType = profile?.storeType ?? 'sari_sari';

    Map<String, dynamic> permitMap = <String, dynamic>{};
    if (profile?.permitDocsJson != null &&
        profile!.permitDocsJson!.isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(profile!.permitDocsJson!);
        if (decoded is Map<String, dynamic>) {
          permitMap = decoded;
        }
      } catch (_) {}
    }

    final String permitNumber =
        permitMap['permit_number'] as String? ?? 'VERIFIED-LOCAL-001';
    final String barangayClearance =
        permitMap['barangay_clearance'] as String? ?? 'Barangay Micro-Business Permit';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Grabber handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header with Trust Shield
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified_user, color: c.accent, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Dokumento ay Nakakabit sa Telepono',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Self-Declared Verified Documents Attached',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                children: <Widget>[
                  _buildRow('Pangalan ng Tindahan', storeName, c),
                  const Divider(height: 16),
                  _buildRow('May-ari', ownerName, c),
                  const Divider(height: 16),
                  _buildRow('Uri ng Negosyo', storeType.toUpperCase(), c),
                  const Divider(height: 16),
                  _buildRow('Municipal Permit #', permitNumber, c),
                  const Divider(height: 16),
                  _buildRow('Barangay Clearance', barangayClearance, c),
                  if (profile?.latitude != null &&
                      profile?.longitude != null) ...<Widget>[
                    const Divider(height: 16),
                    _buildRow(
                      'GPS Coordinates',
                      '${profile!.latitude!.toStringAsFixed(4)}, ${profile!.longitude!.toStringAsFixed(4)}',
                      c,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Explanatory note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline, size: 16, color: c.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ang tindahang ito ay lokal na nakarehistro. Ang lahat ng datos at presyo ay galing direkta sa sariling database ng tindera nang walang server intermediary.',
                    style: TextStyle(
                      fontSize: 11,
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Naintindihan Ko',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, AppColors c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.text,
            ),
          ),
        ),
      ],
    );
  }
}
