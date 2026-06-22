import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  String? _error;

  AuthProvider() {
    ApiService.onUnauthorized = logout;
  }

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> checkAuth() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      _user = await AuthService.getCurrentUser();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.login(email, password);
      _user = User.fromJson(data['user']);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phoneNumber,
    String? address,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.register(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: phoneNumber,
        address: address,
      );
      _user = User.fromJson(data['user']);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendOtp(String phoneNumber) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await AuthService.sendOtp(phoneNumber);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String phoneNumber, String otpCode) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.verifyOtp(phoneNumber, otpCode);
      if (data['user'] != null) {
        _user = User.fromJson(data['user']);
      }
      _loading = false;
      notifyListeners();
      return data;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await AuthService.updateProfile(data);
      _user = User(
        id: _user!.id,
        username: data['username'] ?? _user!.username,
        email: data['email'] ?? _user!.email,
        role: _user!.role,
        phoneNumber: data['phone_number'] ?? _user!.phoneNumber,
        address: data['address'] ?? _user!.address,
        avatar: data['avatar'] ?? _user!.avatar,
      );
      await AuthService.updateLocalUser(_user!);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
