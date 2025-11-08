import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService api;
  final FlutterSecureStorage _storage;
  String? _token;
  User? _user;
  bool _loading = false;

  AuthProvider({required this.api, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    api.onUnauthorized = _handleUnauthorized;
  }

  bool get isLoading => _loading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  User? get user => _user;

  Future<void> _handleUnauthorized() async {
    await logout();
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: TOKEN_KEY);
    if (token != null && token.isNotEmpty) {
      _token = token;
      api.setToken(_token);
      try {
        await fetchProfile();
      } catch (_) {
        // ignore, will force login
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
    required String department,
    required String phoneNumber,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await api.signup(
        name: name,
        email: email,
        password: password,
        department: department,
        phoneNumber: phoneNumber,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await api.login(email: email, password: password);
      final token = data['access_token'] ?? data['token'] ?? '';
      if (token == null || token == '') throw Exception('No token returned');
      _token = token.toString();
      await _storage.write(key: TOKEN_KEY, value: _token);
      api.setToken(_token);
      await fetchProfile();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProfile() async {
    final profile = await api.getProfile();
    _user = User.fromJson(profile);
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    api.setToken(null);
    await _storage.delete(key: TOKEN_KEY);
    notifyListeners();
  }
}
