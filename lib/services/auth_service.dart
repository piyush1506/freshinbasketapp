import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://192.168.29.50:8000';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      await _storeTokens(data['access'], data['refresh']);
      await _storeUser(User.fromJson(data['user']));
      return data;
    }
    final body = res.body.isNotEmpty ? json.decode(res.body) : {};
    throw Exception(_extractError(body) ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    String? address,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email,
        'password': password,
        'confirm_password': confirmPassword,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (address != null) 'address': address,
      }),
    );
    if (res.statusCode == 201) {
      final data = json.decode(res.body);
      await _storeTokens(data['access'], data['refresh']);
      await _storeUser(User.fromJson(data['user']));
      return data;
    }
    final body = res.body.isNotEmpty ? json.decode(res.body) : {};
    throw Exception(_extractError(body) ?? 'Registration failed');
  }

  static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/send-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone_number': phoneNumber}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body);
    }
    final body = res.body.isNotEmpty ? json.decode(res.body) : {};
    throw Exception(_extractError(body) ?? 'Failed to send OTP');
  }

  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otpCode) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'phone_number': phoneNumber, 'otp_code': otpCode}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = json.decode(res.body);
      if (data['access'] != null && data['refresh'] != null) {
        await _storeTokens(data['access'], data['refresh']);
      }
      if (data['user'] != null) {
        await _storeUser(User.fromJson(data['user']));
      }
      return data;
    }
    final body = res.body.isNotEmpty ? json.decode(res.body) : {};
    throw Exception(_extractError(body) ?? 'Invalid OTP');
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');
      if (refresh != null) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'refresh': refresh}),
        );
      }
    } catch (_) {}
    await _clearAuth();
  }

  static Future<void> _storeTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  static Future<void> _storeUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode({
      'id': user.id,
      'username': user.username,
      'email': user.email,
      'role': user.role,
      'phone_number': user.phoneNumber,
      'address': user.address,
      'avatar': user.avatar,
    }));
  }

  static Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data == null) return null;
    return User.fromJson(json.decode(data));
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> updateLocalUser(User user) async {
    await _storeUser(user);
  }

  static String? _extractError(Map<String, dynamic> body) {
    if (body.containsKey('detail')) {
      final detail = body['detail'] as String?;
      if (detail != null && detail.contains('token is not valid')) {
        return 'Your session has expired. Please log in again.';
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

  static Future<void> updateProfile(Map<String, dynamic> data) async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.patch(
      Uri.parse('$baseUrl/api/users/me/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    if (res.statusCode != 200) {
      final body = res.body.isNotEmpty ? json.decode(res.body) : {};
      throw Exception(body['detail'] ?? 'Failed to update profile');
    }
  }
}
