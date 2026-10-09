import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/adapters/carinderia_adapter.dart';
import '../domain/adapters/gulay_adapter.dart';
import '../domain/adapters/rice_adapter.dart';
import '../domain/adapters/sari_sari_adapter.dart';
import '../domain/adapters/store_adapter.dart';
import '../theme/store_theme.dart';
import 'auth_provider.dart';

/// Riverpod provider that exposes the active [StoreAdapter].
/// Automatically switches when the active storeType changes in [authProvider].
final Provider<StoreAdapter> storeAdapterProvider =
    Provider<StoreAdapter>((Ref ref) {
  final AuthState auth =
      ref.watch(authProvider).value ?? const AuthState();
  return storeAdapterForType(auth.storeType);
});

/// Pure mapper from [StoreType] to the corresponding [StoreAdapter] implementation.
StoreAdapter storeAdapterForType(StoreType type) => switch (type) {
      StoreType.sariSari => const SariSariAdapter(),
      StoreType.gulay => const GulayAdapter(),
      StoreType.rice => const RiceAdapter(),
      StoreType.carinderia => const CarinderiaAdapter(),
    };
