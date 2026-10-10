import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sare/application/auth_provider.dart';
import 'package:sare/application/buyer_provider.dart';
import 'package:sare/application/inventory_provider.dart';
import 'package:sare/application/listahan_provider.dart';
import 'package:sare/domain/adapters/sari_sari_adapter.dart';
import 'package:sare/domain/entities/product.dart';
import 'package:sare/domain/entities/user_credential.dart';
import 'package:sare/screens/buyer/buyer_kiosk_screen.dart';
import 'package:sare/screens/main_shell.dart';
import 'package:sare/screens/inventory/shared/item_box_grid.dart';
import 'package:sare/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('buyer shell starts at Profile and Tindahan opens the catalog',
      (WidgetTester tester) async {
    const AuthState buyerAuth = AuthState(
      user: UserCredential(
        userId: 'buyer-1',
        pinHash: '',
        role: 'buyer',
        storeName: 'Nena',
      ),
      storeId: 'store-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          authProvider.overrideWith(() => _MockAuthNotifier(buyerAuth)),
          buyerProvider.overrideWith(_MockBuyerNotifier.new),
          inventoryProvider.overrideWith(_MockInventoryNotifier.new),
          listahanProvider.overrideWith(_MockListahanNotifier.new),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: const MainShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Wala pang naka-save na order'), findsOneWidget);
    expect(find.text('ORD-8821'), findsNothing);
    expect(find.text('₱120.00'), findsNothing);
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Tindahan'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Tindahan'));
    await tester.pumpAndSettle();

    expect(find.byType(BuyerKioskScreen), findsOneWidget);
    expect(find.text('Maghanap ng bilihin...'), findsOneWidget);
    expect(find.text('Kiosk ng Mamimili (Self-Serve)'), findsNothing);
  });

  testWidgets('shared inventory grid has 16dp side padding',
      (WidgetTester tester) async {
    final Product product = Product(
      productId: 'product-1',
      name: 'Sample item',
      unitPrice: 10,
      costPrice: 5,
      stockQty: 8,
      threshold: 2,
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(
          body: StoreItemBoxGrid(
            items: <Product>[product],
            adapter: const SariSariAdapter(),
            onTapItem: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    final EdgeInsets padding = grid.padding! as EdgeInsets;
    expect(padding.left, 16);
    expect(padding.right, 16);
  });
}

class _MockAuthNotifier extends AuthNotifier {
  _MockAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  Future<AuthState> build() async => _initialState;
}

class _MockBuyerNotifier extends BuyerNotifier {
  @override
  BuyerState build() => const BuyerState(isLoading: false);
}

class _MockInventoryNotifier extends InventoryNotifier {
  @override
  Future<InventoryState> build() async => const InventoryState();
}

class _MockListahanNotifier extends ListahanNotifier {
  @override
  Future<ListahanState> build() async => const ListahanState();
}
