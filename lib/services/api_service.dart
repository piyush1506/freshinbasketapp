import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/slide.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/store_settings.dart';
import '../models/review.dart';
import '../models/wishlist_item.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.29.50:8000';
  static VoidCallback? onUnauthorized;

  static Future<Map<String, String>> _headers({bool multipart = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      if (!multipart) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> _request(
    Future<http.Response> Function() sendRequest,
  ) async {
    var response = await sendRequest();
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        response = await sendRequest();
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
       onUnauthorized?.call();
    }
    final body = response.body.isNotEmpty ? json.decode(response.body) : {};
    throw Exception(_extractError(body) ?? 'Request failed');
  }

  static Future<dynamic> _requestFromStream(
    Future<http.StreamedResponse> Function() sendRequest,
  ) async {
    var streamed = await sendRequest();
    var response = await http.Response.fromStream(streamed);
    if (response.statusCode == 401) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        streamed = await sendRequest();
        response = await http.Response.fromStream(streamed);
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }
    if (response.statusCode == 401 || response.statusCode == 403) {
       onUnauthorized?.call();
    }
    final body = response.body.isNotEmpty ? json.decode(response.body) : {};
    throw Exception(_extractError(body) ?? 'Request failed');
  }

  static String? _extractError(Map<String, dynamic> body) {
    if (body.containsKey('detail')) {
      final detail = body['detail'] as String?;
      if (detail != null && detail.contains('token is not valid')) {
        return 'Your session has expired. Please log in again.';
      }
      if (detail != null && detail.contains('Authentication credentials were not provided')) {
        return 'Please log in to continue.';
      }
      return detail;
    }
    if (body.containsKey('message')) return body['message'] as String?;
    if (body.containsKey('non_field_errors')) {
      final v = body['non_field_errors'];
      return v is List ? v.join(', ') : v.toString();
    }
    final messages = <String>[];
    for (final entry in body.entries) {
      final v = entry.value;
      if (v is List && v.isNotEmpty) {
        messages.add('${entry.key}: ${v.join(', ')}');
      } else if (v is String) {
        messages.add('${entry.key}: $v');
      }
    }
    return messages.isNotEmpty ? messages.join('\n') : null;
  }

  static Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh == null) {
        onUnauthorized?.call();
        return false;
      }
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refresh}),
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        await prefs.setString('access_token', data['access']);
        return true;
      }
      // If refresh fails, clear auth data so user can re-login
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('user_data');
      onUnauthorized?.call();
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Slide>> fetchHomeSlides() async {
    final data = await fetchHome();
    return (data['slides'] as List?)?.map((s) => Slide.fromJson(s)).toList() ?? [];
  }

  static Future<List<Category>> fetchHomeCategories() async {
    final data = await fetchHome();
    return (data['categories'] as List?)?.map((c) => Category.fromJson(c)).toList() ?? [];
  }

  static Future<Map<String, dynamic>> fetchHome() async {
    return await _request(() async => http.get(
      Uri.parse('$baseUrl/api/home/'),
      headers: await _headers(),
    ));
  }

  static Future<List<Product>> fetchProducts({String? category}) async {
    final uri = Uri.parse('$baseUrl/api/products/').replace(
      queryParameters: category != null ? {'category': category} : null,
    );
    final data = await _request(() async => http.get(uri, headers: await _headers()));
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  static Future<Product> fetchProduct(int id) async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/products/$id/'),
      headers: await _headers(),
    ));
    return Product.fromJson(data);
  }

  static Future<List<Product>> searchProducts(String query) async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/products/search/?q=$query'),
      headers: await _headers(),
    ));
    return (data as List).map((p) => Product.fromJson(p)).toList();
  }

  static Future<List<Category>> fetchCategories() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/categories/'),
      headers: await _headers(),
    ));
    return (data as List).map((c) => Category.fromJson(c)).toList();
  }

  static Future<Category?> fetchCategory(String slug) async {
    final categories = await fetchCategories();
    try {
      return categories.firstWhere((c) => c.slug == slug);
    } catch (_) {
      return null;
    }
  }

  static Future<StoreSettings> fetchStoreSettings() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/store-info/'),
      headers: await _headers(),
    ));
    return StoreSettings.fromJson(data);
  }

  static Future<List<CartItem>> fetchCart() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/cart/'),
      headers: await _headers(),
    ));
    return (data['items'] as List?)?.map((i) => CartItem.fromJson(i)).toList() ?? [];
  }

  static Future<void> addToCart(int productId, int quantity) async {
    await _request(() async => http.post(
      Uri.parse('$baseUrl/api/cart/add_item/'),
      headers: await _headers(),
      body: json.encode({'product_id': productId, 'quantity': quantity}),
    ));
  }

  static Future<void> removeFromCart(int productId) async {
    await _request(() async => http.delete(
      Uri.parse('$baseUrl/api/cart/remove_item/'),
      headers: await _headers(),
      body: json.encode({'product_id': productId}),
    ));
  }

  static Future<void> clearCart() async {
    await _request(() async => http.delete(
      Uri.parse('$baseUrl/api/cart/clear/'),
      headers: await _headers(),
    ));
  }

  static Future<void> mergeCart(List<Map<String, dynamic>> items) async {
    await _request(() async => http.post(
      Uri.parse('$baseUrl/api/cart/merge/'),
      headers: await _headers(),
      body: json.encode({'items': items}),
    ));
  }

  static Future<Map<String, dynamic>> createRazorpayOrder() async {
    return await _request(() async => http.post(
      Uri.parse('$baseUrl/api/payment/create-order/'),
      headers: await _headers(),
    ));
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String deliveryAddress,
    String? deliveryLatitude,
    String? deliveryLongitude,
  }) async {
    return await _request(() async => http.post(
      Uri.parse('$baseUrl/api/payment/verify/'),
      headers: await _headers(),
      body: json.encode({
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
        'delivery_address': deliveryAddress,
        if (deliveryLatitude != null) 'delivery_latitude': deliveryLatitude,
        if (deliveryLongitude != null) 'delivery_longitude': deliveryLongitude,
      }),
    ));
  }

  static Future<Map<String, dynamic>> createCODOrder({
    required String deliveryAddress,
    String? deliveryLatitude,
    String? deliveryLongitude,
  }) async {
    return await _request(() async => http.post(
      Uri.parse('$baseUrl/api/payment/cod/'),
      headers: await _headers(),
      body: json.encode({
        'delivery_address': deliveryAddress,
        if (deliveryLatitude != null) 'delivery_latitude': deliveryLatitude,
        if (deliveryLongitude != null) 'delivery_longitude': deliveryLongitude,
      }),
    ));
  }

  static Future<List<Order>> fetchOrders() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/orders/'),
      headers: await _headers(),
    ));
    return (data as List).map((o) => Order.fromJson(o)).toList();
  }

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    await _request(() async => http.patch(
      Uri.parse('$baseUrl/api/users/me/'),
      headers: await _headers(),
      body: json.encode(data),
    ));
  }

  static Future<List<dynamic>> fetchContactQueries() async {
    return await _request(() async => http.get(
      Uri.parse('$baseUrl/api/contact/'),
      headers: await _headers(),
    )) as List;
  }

  static Future<void> submitContact({
    required String name,
    required String email,
    required String message,
  }) async {
    await _request(() async => http.post(
      Uri.parse('$baseUrl/api/contact/'),
      headers: await _headers(),
      body: json.encode({'name': name, 'email': email, 'message': message}),
    ));
  }

  // ─── Wishlist ──────────────────────────────────────────────

  static Future<List<WishlistItem>> fetchWishlist() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/wishlist/'),
      headers: await _headers(),
    ));
    return (data as List).map((i) => WishlistItem.fromJson(i)).toList();
  }

  static Future<void> addToWishlist(int productId) async {
    await _request(() async => http.post(
      Uri.parse('$baseUrl/api/wishlist/'),
      headers: await _headers(),
      body: json.encode({'product': productId}),
    ));
  }

  static Future<void> removeFromWishlist(int productId) async {
    await _request(() async => http.delete(
      Uri.parse('$baseUrl/api/wishlist/remove/'),
      headers: await _headers(),
      body: json.encode({'product_id': productId}),
    ));
  }

  static Future<List<int>> fetchWishlistIds() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/wishlist/ids/'),
      headers: await _headers(),
    ));
    return (data as List).cast<int>();
  }

  // ─── Reviews ───────────────────────────────────────────────

  static Future<List<Review>> fetchReviews() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/reviews/'),
      headers: await _headers(),
    ));
    return (data as List).map((r) => Review.fromJson(r)).toList();
  }

  static Future<Review> createReview({
    required int orderId,
    required int rating,
    String? comment,
  }) async {
    final data = await _request(() async => http.post(
      Uri.parse('$baseUrl/api/reviews/'),
      headers: await _headers(),
      body: json.encode({
        'order': orderId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      }),
    ));
    return Review.fromJson(data);
  }

  // ─── Image Upload ──────────────────────────────────────────

  static Future<String> uploadImage(File file) async {
    final headers = await _headers(multipart: true);
    final data = await _requestFromStream(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/'),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      return request.send();
    });
    return data['secure_url'] as String;
  }

  static Future<String> uploadAvatar(File file) async {
    final headers = await _headers(multipart: true);
    final data = await _requestFromStream(() async {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/users/avatar/'),
      );
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('avatar', file.path));
      return request.send();
    });
    return data['avatar'] as String;
  }

  // ─── Slides ─────────────────────────────────────────────────

  static Future<List<Slide>> fetchSlides() async {
    final data = await _request(() async => http.get(
      Uri.parse('$baseUrl/api/slides/'),
      headers: await _headers(),
    ));
    return (data as List).map((s) => Slide.fromJson(s)).toList();
  }
}
