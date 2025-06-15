import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://localhost:8080';  // Update this with your actual backend URL

  Future<void> register(String username, String password, String fullName, String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fullName': fullName,
          'email': email,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Registration failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }
} 