import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/user_model.dart';

class AuthService {
  static const _baseUrl = 'http://10.0.2.2:8080'; // TODO: Config dosyasından al
  static const _loginEndpoint = '/api/auth/login';
  static const _registerEndpoint = '/api/auth/register';
  static const _userMeEndpoint = '/api/users/me';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
      print('Login yanıtı: \\${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        await _storage.write(key: 'jwt', value: token);
        print('JWT token: $token');
        return null; // null = başarılı giriş
      } else {
        // Backend'den dönen hata mesajını göster
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
        return 'Kayıt başarısız: ${response.body}';
      }
    } catch (e) {
      return 'Kayıt sırasında bir hata oluştu: $e';
    }
  }

  Future<UserModel?> getCurrentUser() async {
    String? token = await _storage.read(key: 'jwt');
    if (token == null) return null;
    final url = Uri.parse('$_baseUrl$_userMeEndpoint');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    print('getCurrentUser status: ${response.statusCode}');
    print('getCurrentUser body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data);
    } else {
      print('Kullanıcı bilgileri alınamadı: ${response.body}');
    }
    return null;
  }

  Future<bool> updateCurrentUser({required String fullName, String? password}) async {
    final token = await _storage.read(key: 'jwt');
    if (token == null) return false;
    final url = Uri.parse('$_baseUrl$_userMeEndpoint');
    final body = {
      'fullName': fullName,
      if (password != null && password.isNotEmpty) 'password': password,
    };
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      print('Kullanıcı bilgileri güncellenirken hata oluştu: ${response.body}');
    }
    return response.statusCode == 200;
  }
}
