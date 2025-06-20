import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';
import 'package:flutter/material.dart';
import '../domain/badge_model.dart';
import '../../../core/network/http_interceptor.dart';

class AuthService {
  static const _baseUrl = 'http://10.0.2.2:8080'; // TODO: Config dosyasından al
  static const _loginEndpoint = '/api/auth/login';
  static const _registerEndpoint = '/api/auth/register';
  static const _userMeEndpoint = '/api/users/me';
  static const _refreshTokenEndpoint = '/api/auth/refresh'; // TODO: Backend'de refresh token endpoint'i ekle
  static const _badgesDetailedEndpoint = '/api/gamification/badges/detailed';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<String?> login(String username, String password) async {
    final url = Uri.parse('$_baseUrl$_loginEndpoint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'jwt', value: token);
        return null; // null = başarılı giriş
      } else {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            return _mapErrorMessage(data['message']);
          }
        } catch (_) {}
        return 'Hatalı kullanıcı adı veya şifre';
      }
    } catch (e) {
      return 'Giriş sırasında bir hata oluştu: $e';
    }
  }

  String _mapErrorMessage(String message) {
    switch (message) {
      case 'Invalid username or password':
        return 'Geçersiz kullanıcı adı veya şifre';
      case 'User not found':
        return 'Kullanıcı bulunamadı';
      default:
        return message;
    }
  }

  Future<String?> register(
    String username,
    String password,
    String fullName,
    String email,
  ) async {
    final url = Uri.parse('$_baseUrl$_registerEndpoint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return null; // başarılı kayıt
      } else {
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['message'] != null) {
            return data['message'];
          }
        } catch (_) {}
        return 'Kayıt başarısız';
      }
    } catch (e) {
      return 'Kayıt sırasında bir hata oluştu: $e';
    }
  }

  Future<UserModel?> getCurrentUser() async {
    String? token = await _storage.read(key: 'jwt');
    if (token == null) {
      _redirectToLogin();
      return null;
    }

    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_userMeEndpoint'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    }
    return null;
  }

  Future<bool> updateCurrentUser({required String fullName, String? password}) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) {
      _redirectToLogin();
      return false;
    }

    final body = {
      'fullName': fullName,
      if (password != null && password.isNotEmpty) 'password': password,
    };

    final response = await HttpInterceptor.put(
      Uri.parse('$_baseUrl$_userMeEndpoint'),
      body: jsonEncode(body),
    );

    return response.statusCode == 200;
  }

  void _redirectToLogin() {
    if (navigatorKey.currentContext != null) {
      Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
    _redirectToLogin();
  }

  Future<List<BadgeModel>> getUserBadgesDetailed() async {
    String? token = await _storage.read(key: 'jwt');
    if (token == null) {
      _redirectToLogin();
      return [];
    }
    
    final response = await HttpInterceptor.get(
      Uri.parse('$_baseUrl$_badgesDetailedEndpoint'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => BadgeModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<bool> verifyCurrentPassword(String password) async {
    String? token = await _storage.read(key: 'jwt');
    if (token == null) {
      _redirectToLogin();
      return false;
    }
    // Kullanıcı adını almak için mevcut kullanıcıyı çek
    final user = await getCurrentUser();
    if (user == null) return false;
    final url = Uri.parse('$_baseUrl$_loginEndpoint');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user.username,
        'password': password,
      }),
    );
    return response.statusCode == 200;
  }
}
