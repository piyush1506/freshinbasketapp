import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/store_settings.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  StoreSettings _settings = StoreSettings();
  bool _loading = false;
  bool _isLoggedIn = false;
  bool _authInitialized = false;

  Future<void> initAuthState() async {
    if (_authInitialized) return;
    _authInitialized = true;
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      _isLoggedIn = true;
      try {
        await _fetchFromBackend();
      } catch (_) {
        _loading = false;
      }
      notifyListeners();
    }
  }

  List<CartItem> get items => _items;
  StoreSettings get settings => _settings;
  bool get loading => _loading;
  bool get isLoggedIn => _isLoggedIn;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get deliveryCharge =>
      subtotal >= _settings.freeDeliveryThreshold ? 0.0 : _settings.deliveryCharge;

  double get grandTotal => subtotal + deliveryCharge;

  bool get isCartEmpty => _items.isEmpty;

  void setLoggedIn(bool value) {
    _isLoggedIn = value;
    notifyListeners();
  }

  // ─── Add (handles local + backend) ───────────────────────

  void addItem(Product product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.productId == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        productId: product.id,
        name: product.name,
        price: product.price,
        image: product.imageUrl,
        unit: product.unit,
        quantity: quantity,
      ));
    }
    _persist();
    notifyListeners();
  }

  Future<void> addToBackend(Product product, {int quantity = 1}) async {
    if (!_isLoggedIn) {
      addItem(product, quantity: quantity);
      return;
    }
    try {
      await ApiService.addToCart(product.id, quantity);
    } catch (_) {
      addItem(product, quantity: quantity);
      return;
    }
    try {
      await _fetchFromBackend();
    } catch (_) {
      addItem(product, quantity: quantity);
    }
  }

  // ─── Update quantity ─────────────────────────────────────

  Future<void> updateQuantity(int productId, int quantity) async {
    if (_isLoggedIn) {
      try {
        if (quantity <= 0) {
          await ApiService.removeFromCart(productId);
        } else {
          await ApiService.addToCart(productId, quantity);
        }
      } catch (_) {
        _updateLocalQuantity(productId, quantity);
        return;
      }
      try {
        await _fetchFromBackend();
      } catch (_) {
        _updateLocalQuantity(productId, quantity);
      }
      return;
    }
    _updateLocalQuantity(productId, quantity);
  }

  void _updateLocalQuantity(int productId, int quantity) {
    final index = _items.indexWhere((i) => i.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      _persist();
      notifyListeners();
    }
  }

  // ─── Remove ──────────────────────────────────────────────

  Future<void> removeFromBackend(int productId) async {
    if (_isLoggedIn) {
      try {
        await ApiService.removeFromCart(productId);
      } catch (_) {
        _removeLocal(productId);
        return;
      }
      try {
        await _fetchFromBackend();
      } catch (_) {
        _removeLocal(productId);
      }
      return;
    }
    _removeLocal(productId);
  }

  void _removeLocal(int productId) {
    _items.removeWhere((i) => i.productId == productId);
    _persist();
    notifyListeners();
  }

  // ─── Clear ───────────────────────────────────────────────

  Future<void> clearBackendCart() async {
    if (_isLoggedIn) {
      try {
        await ApiService.clearCart();
      } catch (_) {}
    }
    _items.clear();
    _persist();
    notifyListeners();
  }

  // ─── Sync after login ────────────────────────────────────

  Future<void> syncAfterLogin() async {
    _isLoggedIn = true;
    final localItems = List<CartItem>.from(_items);
    if (localItems.isNotEmpty) {
      try {
        await ApiService.mergeCart(
          localItems.map((i) => i.toJson()).toList(),
        );
      } catch (_) {}
    }
    try {
      await _fetchFromBackend();
    } catch (_) {}
  }

  // ─── Fetch from backend ──────────────────────────────────

  Future<void> fetchCart() async {
    if (_isLoggedIn) {
      try {
        await _fetchFromBackend();
      } catch (_) {
        _loading = false;
        notifyListeners();
      }
    } else {
      await loadGuestCart();
    }
  }

  Future<void> _fetchFromBackend() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await ApiService.fetchCart();
      _clearGuestCart();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Guest cart (local) ──────────────────────────────────

  Future<void> loadGuestCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cart = prefs.getString('guest_cart');
    if (cart != null) {
      final list = json.decode(cart) as List;
      _items = list.map((i) => CartItem.fromJson(i)).toList();
      notifyListeners();
    }
  }

  void _persist() {
    if (_isLoggedIn) return;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(
          'guest_cart', json.encode(_items.map((i) => i.toJson()).toList()));
    });
  }

  void _clearGuestCart() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('guest_cart');
    });
  }

  // ─── Store settings ──────────────────────────────────────

  Future<void> fetchStoreSettings() async {
    try {
      _settings = await ApiService.fetchStoreSettings();
      notifyListeners();
    } catch (_) {}
  }
}
