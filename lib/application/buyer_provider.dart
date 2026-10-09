import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local/daos/product_dao.dart';
import '../data/local/daos/store_profile_dao.dart';
import '../domain/entities/buyer_order.dart';
import '../domain/entities/product.dart';
import '../domain/entities/store_profile.dart';

const Uuid _uuid = Uuid();

class BuyerState {
  const BuyerState({
    this.catalog = const <Product>[],
    this.cartItems = const <BuyerOrderItem>[],
    this.searchQuery = '',
    this.selectedCategory,
    this.storeProfile,
    this.stagedOrder,
    this.isLoading = false,
  });

  final List<Product> catalog;
  final List<BuyerOrderItem> cartItems;
  final String searchQuery;
  final String? selectedCategory;
  final StoreProfile? storeProfile;
  final BuyerOrder? stagedOrder;
  final bool isLoading;

  double get cartTotal =>
      cartItems.fold<double>(0.0, (double sum, BuyerOrderItem i) => sum + i.subtotal);

  int get cartCount =>
      cartItems.fold<int>(0, (int sum, BuyerOrderItem i) => sum + i.qty);

  bool get isCartEmpty => cartItems.isEmpty;

  List<Product> get filteredCatalog {
    Iterable<Product> list = catalog;

    if (searchQuery.isNotEmpty) {
      final String q = searchQuery.toLowerCase();
      list = list.where((Product p) =>
          p.name.toLowerCase().contains(q) ||
          (p.categoryName?.toLowerCase().contains(q) ?? false));
    }

    if (selectedCategory != null && selectedCategory!.isNotEmpty) {
      list = list.where((Product p) =>
          (p.categoryName?.toLowerCase() ?? '') ==
          selectedCategory!.toLowerCase());
    }

    return list.toList();
  }

  BuyerState copyWith({
    List<Product>? catalog,
    List<BuyerOrderItem>? cartItems,
    String? searchQuery,
    String? selectedCategory,
    StoreProfile? storeProfile,
    BuyerOrder? stagedOrder,
    bool? isLoading,
    bool clearCategory = false,
    bool clearStagedOrder = false,
  }) {
    return BuyerState(
      catalog: catalog ?? this.catalog,
      cartItems: cartItems ?? this.cartItems,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      storeProfile: storeProfile ?? this.storeProfile,
      stagedOrder: clearStagedOrder ? null : (stagedOrder ?? this.stagedOrder),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BuyerNotifier extends Notifier<BuyerState> {
  final ProductDao _productDao = ProductDao();
  final StoreProfileDao _profileDao = StoreProfileDao();

  @override
  BuyerState build() {
    Future<void>.microtask(loadCatalogAndProfile);
    return const BuyerState(isLoading: true);
  }

  Future<void> loadCatalogAndProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      final List<Product> products = await _productDao.getAllProducts();
      final StoreProfile? profile = await _profileDao.getProfile();
      state = state.copyWith(
        catalog: products,
        storeProfile: profile,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategory(String? category) {
    if (category == null || state.selectedCategory == category) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void addToCart(
    Product product, {
    int qty = 1,
    List<String> addons = const <String>[],
    double addonPrice = 0.0,
  }) {
    final List<BuyerOrderItem> items = List<BuyerOrderItem>.from(state.cartItems);
    final int idx = items.indexWhere((BuyerOrderItem item) =>
        item.id == product.productId &&
        item.addons.join(',') == addons.join(','));

    if (idx >= 0) {
      final BuyerOrderItem existing = items[idx];
      items[idx] = existing.copyWith(qty: existing.qty + qty);
    } else {
      items.add(
        BuyerOrderItem(
          id: product.productId,
          name: product.name,
          unitPrice: product.unitPrice,
          qty: qty,
          addons: addons,
          addonPrice: addonPrice,
        ),
      );
    }
    state = state.copyWith(cartItems: items);
  }

  void updateItemQty(int index, int delta) {
    if (index < 0 || index >= state.cartItems.length) return;
    final List<BuyerOrderItem> items = List<BuyerOrderItem>.from(state.cartItems);
    final BuyerOrderItem item = items[index];
    final int newQty = item.qty + delta;
    if (newQty <= 0) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(qty: newQty);
    }
    state = state.copyWith(cartItems: items);
  }

  void removeItem(int index) {
    if (index < 0 || index >= state.cartItems.length) return;
    final List<BuyerOrderItem> items = List<BuyerOrderItem>.from(state.cartItems);
    items.removeAt(index);
    state = state.copyWith(cartItems: items);
  }

  void clearCart() {
    state = state.copyWith(
      cartItems: const <BuyerOrderItem>[],
      clearStagedOrder: true,
    );
  }

  BuyerOrder stageOrder({String? notes}) {
    final String storeId = state.storeProfile?.id ?? 'STR_LOCAL';
    final BuyerOrder order = BuyerOrder(
      orderId: _uuid.v4().substring(0, 8).toUpperCase(),
      storeId: storeId,
      timestamp: DateTime.now(),
      items: state.cartItems,
      totalAmount: state.cartTotal,
      notes: notes,
    );
    state = state.copyWith(stagedOrder: order);
    return order;
  }
}

final NotifierProvider<BuyerNotifier, BuyerState> buyerProvider =
    NotifierProvider<BuyerNotifier, BuyerState>(BuyerNotifier.new);
