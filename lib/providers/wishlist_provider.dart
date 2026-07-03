import 'package:flutter/material.dart';
import '../models/wishlist_item.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class WishlistProvider extends ChangeNotifier {
  List<WishlistItem> _items = [];
  Set<int> _productIds = {};
  bool _loading = false;
  bool _authInitialized = false;

  Future<void> initAuthState() async {
    if (_authInitialized) return;
    _authInitialized = true;
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      await fetchWishlist();
    }
  }

  List<WishlistItem> get items => _items;
  Set<int> get productIds => _productIds;
  bool get loading => _loading;

  bool isWishlisted(int productId) => _productIds.contains(productId);

  Future<void> fetchWishlist() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await ApiService.fetchWishlist();
      _productIds = _items.map((i) => i.productId).toSet();
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> toggle(int productId) async {
    if (_productIds.contains(productId)) {
      await remove(productId);
    } else {
      await add(productId);
    }
  }

  Future<void> add(int productId) async {
    _productIds.add(productId);
    notifyListeners();
    try {
      await ApiService.addToWishlist(productId);
      await fetchWishlist();
    } catch (_) {
      _productIds.remove(productId);
      notifyListeners();
    }
  }

  Future<void> remove(int productId) async {
    _productIds.remove(productId);
    _items.removeWhere((i) => i.productId == productId);
    notifyListeners();
    try {
      await ApiService.removeFromWishlist(productId);
    } catch (_) {
      await fetchWishlist();
    }
  }

  void clear() {
    _items.clear();
    _productIds.clear();
    notifyListeners();
  }

  void logout() {
    _authInitialized = false;
    _items.clear();
    _productIds.clear();
    notifyListeners();
  }
}
