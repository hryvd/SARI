import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/inventory_provider.dart';
import '../application/listahan_provider.dart';
import '../application/auth_provider.dart';
import '../application/sync_provider.dart';
import '../theme/app_theme.dart';
import '../theme/store_theme.dart';

// ─── Setup flow mode ────────────────────────────────────────────────────────
enum _SetupMode {
  landing, // Step 0: choose Google or Offline
  storeType, // Step 1: pick store type (NEW — persists to SharedPreferences)
  googleNew, // Step 2a: Google OK, new store → enter name + PIN
  googleExisting, // Step 2b: Google OK, existing store → enter PIN only
  offline, // Step 2c: local-only → enter name + PIN
}

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with SingleTickerProviderStateMixin {
  _SetupMode _mode = _SetupMode.landing;
  bool _isLoading = false;
  String? _error;
  GoogleLinkResult? _googleResult; // set after a successful Google Sign-In
  bool _isResettingPin =
      false; // true when user taps "Forgot PIN?" on existing store
  StoreType _selectedStoreType =
      StoreType.sariSari; // chosen in store-type step

  // Form fields
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _pinVisible = false;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ────────────────────────────────────────────────────────────

  Future<void> _goToStoreTypeSelection({required bool isGoogle}) async {
    // After auth we first let the user pick their store type
    _fadeCtrl.reset();
    setState(() {
      _mode = _SetupMode.storeType;
      _error = null;
      _isLoading = false;
    });
    _fadeCtrl.forward();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final GoogleLinkResult? result =
        await ref.read(authProvider.notifier).linkStoreWithGoogle();

    if (!mounted) return;

    if (result == null) {
      // Error is already set on authProvider, but also surface it locally
      final String? msg = ref.read(authProvider).value?.errorMessage;
      setState(() {
        _isLoading = false;
        _error = msg ?? 'Google Sign-In failed. Please try again.';
      });
      return;
    }

    _googleResult = result;
    if (result.isExistingStore) {
      _nameCtrl.text = result.existingStoreName ?? '';
    }

    // Go to store type selection before the form
    await _goToStoreTypeSelection(isGoogle: true);
  }

  Future<void> _goOffline() async {
    // Still select store type first
    _fadeCtrl.reset();
    setState(() {
      _mode = _SetupMode.storeType;
      _error = null;
    });
    _fadeCtrl.forward();
  }

  /// Called when user confirms their store type and taps Continue.
  void _confirmStoreType() {
    _fadeCtrl.reset();
    final bool isGoogle = _googleResult != null;
    _SetupMode next;
    if (isGoogle && (_googleResult?.isExistingStore ?? false)) {
      next = _SetupMode.googleExisting;
    } else if (isGoogle) {
      next = _SetupMode.googleNew;
    } else {
      next = _SetupMode.offline;
    }
    setState(() {
      _mode = next;
      _error = null;
    });
    _fadeCtrl.forward();
  }

  Future<void> _submitForm() async {
    final String pin = _pinCtrl.text;
    final String confirm = _confirmCtrl.text;
    final String name = _nameCtrl.text.trim();

    // ── googleExisting: verify PIN against cloud hash (or reset) ──
    if (_mode == _SetupMode.googleExisting && !_isResettingPin) {
      if (pin.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits.');
        return;
      }
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final String enteredHash = hashPin(pin);
      final String? cloudHash = _googleResult?.cloudPinHash;

      // If no cloud hash (legacy store), fall back to creating a new record
      if (cloudHash == null || cloudHash.isEmpty) {
        final bool ok = await ref
            .read(authProvider.notifier)
            .register(pin, _googleResult?.existingStoreName ?? 'My Store');
        if (mounted && !ok) {
          setState(() {
            _isLoading = false;
            _error = 'Setup failed.';
          });
        }
        return;
      }

      if (enteredHash != cloudHash) {
        setState(() {
          _isLoading = false;
          _error = 'Invalid PIN. Try again or tap Forgot PIN.';
        });
        return;
      }

      // PIN matches — create local user record
      final bool ok = await ref
          .read(authProvider.notifier)
          .register(pin, _googleResult?.existingStoreName ?? 'My Store');
      if (ok) {
        // Restore all data from cloud for this returning user
        await ref.read(syncProvider.notifier).restoreFromCloud();
        ref.invalidate(inventoryProvider);
        ref.invalidate(listahanProvider);
      }
      if (mounted && !ok) {
        setState(() {
          _isLoading = false;
          _error = 'Setup failed.';
        });
      }
      return;
    }

    // ── googleExisting + resetting PIN ──
    if (_mode == _SetupMode.googleExisting && _isResettingPin) {
      if (pin.length < 4) {
        setState(() => _error = 'PIN must be at least 4 digits.');
        return;
      }
      if (pin != confirm) {
        setState(() => _error = 'PINs do not match.');
        return;
      }
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final bool ok = await ref.read(authProvider.notifier).resetPinFromSetup(
          pin, _googleResult?.existingStoreName ?? 'My Store');
      if (ok) {
        // Restore all data from cloud after PIN reset
        await ref.read(syncProvider.notifier).restoreFromCloud();
        ref.invalidate(inventoryProvider);
        ref.invalidate(listahanProvider);
      }
      if (mounted && !ok) {
        setState(() {
          _isLoading = false;
          _error = 'Reset failed.';
        });
      }
      return;
    }

    // ── googleNew / offline: original flow ──
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your store name.');
      return;
    }
    if (pin.length < 4) {
      setState(() => _error = 'PIN must be at least 4 digits.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    bool ok = false;
    if (_mode == _SetupMode.offline) {
      ok = await ref.read(authProvider.notifier).continueOffline(pin, name);
    } else {
      ok = await ref.read(authProvider.notifier).register(pin, name);
    }

    // Persist the chosen store type BEFORE the auth state triggers navigation
    if (ok) {
      await ref.read(authProvider.notifier).saveStoreType(_selectedStoreType);
    }

    if (mounted && !ok) {
      final String? msg = ref.read(authProvider).value?.errorMessage;
      setState(() {
        _isLoading = false;
        _error = msg ?? 'Setup failed.';
      });
    }
  }

  void _back() {
    _fadeCtrl.reset();
    setState(() {
      _mode = _SetupMode.landing;
      _error = null;
      _pinCtrl.clear();
      _confirmCtrl.clear();
      _nameCtrl.clear();
    });
    _fadeCtrl.forward();
  }

  // ─── Builders ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final AppColors c = appColors(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: _buildCurrentStep(c),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(AppColors c) {
    return switch (_mode) {
      _SetupMode.landing => _buildLanding(c),
      _SetupMode.storeType => _buildStoreTypeSelector(c),
      _SetupMode.googleNew => _buildForm(
          c,
          title: 'Set Up Your Store',
          subtitle: 'Google account linked. Enter your store details.',
          showNameField: true,
        ),
      _SetupMode.googleExisting => _isResettingPin
          ? _buildForm(
              c,
              title: 'Reset Your PIN 🔒',
              subtitle:
                  'Create a new PIN for "${_googleResult?.existingStoreName ?? 'My Store'}".',
              showNameField: false,
            )
          : _buildForm(
              c,
              title: 'Welcome Back! 👋',
              subtitle:
                  'Found your store "${_googleResult?.existingStoreName ?? 'My Store'}". Enter your PIN to continue.',
              showNameField: false,
              isEnterPinMode: true,
            ),
      _SetupMode.offline => _buildForm(
          c,
          title: 'Offline Setup',
          subtitle: 'Your data stays on this device only (no cloud sync).',
          showNameField: true,
        ),
    };
  }

  // ─── Landing Screen ──────────────────────────────────────────────────────

  Widget _buildLanding(AppColors c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.borderSubtle),
                ),
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/sare_logo.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(height: 28),
              Text(
                'Welcome to SARI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your store and start your day with a clear view of what matters.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 36),
              if (_isLoading)
                SizedBox(
                  height: 116,
                  child: Center(
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                )
              else ...<Widget>[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const _GoogleIcon(),
                    label: const Text('Continue with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.surface,
                      foregroundColor: c.text,
                      elevation: 0,
                      side: BorderSide(color: c.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: _goOffline,
                    icon: const Icon(Icons.wifi_off_rounded),
                    label: const Text('Continue without account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.primary,
                      side:
                          BorderSide(color: c.primary.withValues(alpha: 0.55)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: c.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: c.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google enables backup and multi-device sync. Offline setup keeps data on this device.',
                      style: TextStyle(color: c.textTertiary, fontSize: 12),
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

  // ─── Form Screen (shared by all 3 flow paths) ────────────────────────────

  Widget _buildForm(
    AppColors c, {
    required String title,
    required String subtitle,
    required bool showNameField,
    bool isEnterPinMode = false,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: _isLoading ? null : _back,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: 12),

            // Offline badge
            if (_mode == _SetupMode.offline)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: c.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.wifi_off_rounded, size: 14, color: c.warning),
                    const SizedBox(width: 6),
                    Text('Offline Mode — No cloud sync',
                        style: TextStyle(fontSize: 12, color: c.warning)),
                  ],
                ),
              ),

            Text(title,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, color: c.text)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(color: c.textSecondary, fontSize: 14)),
            const SizedBox(height: 28),

            if (showNameField) ...<Widget>[
              _label('Store Name', c),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                enabled: !_isLoading,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDec(
                    'e.g. Maria\'s Sari-Sari Store', Icons.store_outlined),
              ),
              const SizedBox(height: 20),
            ],

            _label(isEnterPinMode ? 'Enter PIN' : 'Create PIN', c),
            const SizedBox(height: 6),
            TextField(
              controller: _pinCtrl,
              enabled: !_isLoading,
              obscureText: !_pinVisible,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: _inputDec(
                isEnterPinMode ? 'Enter your PIN' : 'At least 4 digits',
                Icons.lock_outline,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _pinVisible ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _pinVisible = !_pinVisible),
                ),
              ),
              onSubmitted: isEnterPinMode ? (_) => _submitForm() : null,
            ),

            // "Forgot PIN?" link for existing stores
            if (isEnterPinMode) ...<Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _pinCtrl.clear();
                    _confirmCtrl.clear();
                    setState(() {
                      _isResettingPin = true;
                      _error = null;
                    });
                  },
                  child: Text('Forgot PIN?',
                      style: TextStyle(color: c.primary, fontSize: 13)),
                ),
              ),
            ],

            // Show confirm field only when NOT in enter-pin mode
            if (!isEnterPinMode) ...<Widget>[
              const SizedBox(height: 16),
              _label('Confirm PIN', c),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmCtrl,
                enabled: !_isLoading,
                obscureText: !_pinVisible,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: _inputDec('Re-enter PIN', Icons.lock_outline),
                onSubmitted: (_) => _submitForm(),
              ),
            ],

            if (_error != null) ...<Widget>[
              const SizedBox(height: 14),
              Text(_error!, style: TextStyle(color: c.error, fontSize: 13)),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Finish Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Store Type Selector ─────────────────────────────────────────────────

  Widget _buildStoreTypeSelector(AppColors c) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(height: 12),
            Text(
              'What kind of store is this?',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: c.text),
            ),
            const SizedBox(height: 6),
            Text(
              'The app will adapt its inventory, POS, and features to match your store type.',
              style: TextStyle(color: c.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 28),

            // Store type cards
            ...StoreType.values.map((StoreType type) {
              final bool selected = _selectedStoreType == type;
              final Color brand = StoreColors.forType(type);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStoreType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          selected ? brand.withValues(alpha: 0.14) : c.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? brand : c.border,
                        width: selected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: brand.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              type.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? brand : c.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                type.tagline,
                                style: TextStyle(
                                    fontSize: 12, color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_circle_rounded,
                              color: brand, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmStoreType,
                style: ElevatedButton.styleFrom(
                  backgroundColor: StoreColors.forType(_selectedStoreType),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _label(String text, AppColors c) => Text(
        text,
        style: TextStyle(
            fontWeight: FontWeight.w600, fontSize: 13, color: c.textSecondary),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}

/// Google 'G' icon using official brand colors — no Canvas artifacts.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
          // The 'G' is split into 4 spans to fake the Google multicolor effect
          // Blue (#4285F4) top-right, rest use a gradient-like trick via bold G
          children: <TextSpan>[
            TextSpan(
              text: 'G',
              style: TextStyle(color: Color(0xFF4285F4)),
            ),
          ],
        ),
      ),
    );
  }
}
