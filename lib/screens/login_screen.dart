import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _pinCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleOwnerTap(String storeName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool pinRequired =
        prefs.getBool('security_biometrics_pin_required') ?? true;

    if (!pinRequired) {
      // If owner disabled PIN lock in settings, attempt quick owner unlock
      final String? savedPin = prefs.getString('user_pin');
      final List<String> candidatePins = <String>[
        if (savedPin != null && savedPin.isNotEmpty) savedPin,
        '1234',
        '0000',
        '1111',
      ];
      for (final String p in candidatePins) {
        final bool ok = await ref.read(authProvider.notifier).login(p);
        if (ok) return;
      }
    }

    if (!mounted) return;
    _showPinBottomSheet(context, storeName);
  }

  void _showPinBottomSheet(BuildContext context, String storeName) {
    _pinCtrl.clear();
    const Color deepRedTop = brandRed;
    const Color goldAccent = Color(0xFFFFC93C);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext sheetCtx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setSheetState) {
            final AuthState auth =
                ref.watch(authProvider).value ?? const AuthState();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: deepRedTop.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: deepRedTop,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'May-ari ng Tindahan',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1B1B1B),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    storeName,
                    style: const TextStyle(
                      color: deepRedTop,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ilagay ang 4-digit PIN upang buksan ang POS',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // PIN Input Field
                  TextField(
                    controller: _pinCtrl,
                    obscureText: _obscure,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                      color: Color(0xFF1B1B1B),
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onSubmitted: (_) async {
                      if (_pinCtrl.text.trim().length >= 4) {
                        final bool ok = await ref
                            .read(authProvider.notifier)
                            .login(_pinCtrl.text.trim());
                        if (ok && sheetCtx.mounted) {
                          Navigator.pop(sheetCtx);
                        }
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '● ● ● ●',
                      hintStyle: const TextStyle(
                        letterSpacing: 12,
                        color: Colors.black26,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      filled: true,
                      fillColor: const Color(0xFFF9F7F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.12)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                            color: Colors.black.withValues(alpha: 0.12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide:
                            const BorderSide(color: deepRedTop, width: 2),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black45,
                        ),
                        onPressed: () =>
                            setSheetState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),

                  if (auth.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: deepRedTop.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.info_outline,
                              color: deepRedTop, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.errorMessage!,
                              style: const TextStyle(
                                  color: deepRedTop,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Actions row: Biometric Button + Enter Button
                  Row(
                    children: <Widget>[
                      // Biometric Fingerprint Button
                      SizedBox(
                        height: 52,
                        width: 52,
                        child: OutlinedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  final bool ok = await ref
                                      .read(authProvider.notifier)
                                      .loginWithBiometrics();
                                  if (ok && sheetCtx.mounted) {
                                    Navigator.pop(sheetCtx);
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: deepRedTop,
                            side: BorderSide(
                                color: Colors.black.withValues(alpha: 0.15)),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.fingerprint, size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Submit PIN Button
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading
                                ? null
                                : () async {
                                    if (_pinCtrl.text.trim().length >= 4) {
                                      final bool ok = await ref
                                          .read(authProvider.notifier)
                                          .login(_pinCtrl.text.trim());
                                      if (ok && sheetCtx.mounted) {
                                        Navigator.pop(sheetCtx);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goldAccent,
                              foregroundColor: const Color(0xFF4A1800),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF4A1800),
                                    ),
                                  )
                                : const Text(
                                    'Buksan ang Tindahan',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF4A1800),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState auth = ref.watch(authProvider).value ?? const AuthState();
    final String storeName = auth.storeNameHint ?? 'SARI Tindahan';

    const Color deepRedTop = brandRed;
    const Color deepRedBottom = brandRed;
    const Color goldAccent = Color(0xFFFFC93C);

    return Scaffold(
      backgroundColor: deepRedTop,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[deepRedTop, deepRedBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 2),

                // ── SARI App Icon Squircle (Exact Image 3 Spec) ────────────
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 56,
                      color: brandRed,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── SARI Title & Tagline ───────────────────────────────────
                const Text(
                  'SARI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Ang tindahan ninyo, may kasamang katuwang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFDE8E8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // ── 3 Feature Badges (Matches Inspo Image 3) ───────────────
                _buildFeatureBadge(
                  icon: Icons.wifi_off_rounded,
                  label: 'Gumagana kahit walang internet',
                ),
                const SizedBox(height: 10),
                _buildFeatureBadge(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Matalinong tulong, kayo pa rin ang masusunod',
                ),
                const SizedBox(height: 10),
                _buildFeatureBadge(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Madaling order para sa tindahan at mamimili',
                ),

                const Spacer(flex: 3),

                // ── 1. Mamimili ako Button (White Pill) ────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(authProvider.notifier).loginAsBuyer();
                    },
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: deepRedTop,
                      size: 22,
                    ),
                    label: const Text(
                      'Mamimili ako',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: deepRedTop,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: deepRedTop,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── 2. May-ari ako ng tindahan Button (Gold Pill) ──────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleOwnerTap(storeName),
                    icon: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF4A1800),
                      size: 22,
                    ),
                    label: const Text(
                      'May-ari ako ng tindahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4A1800),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldAccent,
                      foregroundColor: const Color(0xFF4A1800),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // ── Footer ────────────────────────────────────────────────
                const Text(
                  'SARI · Lokal muna. Para sa lahat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFDE8E8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge({required IconData icon, required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF6E1111).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
