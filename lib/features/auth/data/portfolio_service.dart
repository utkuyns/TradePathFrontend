import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../domain/portfolio_item_model.dart';

class PortfolioService {
  static const _baseUrl = 'http://10.0.2.2:8080';
  static const _portfolioEndpoint = '/api/portfolio';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<PortfolioItemModel>> fetchPortfolio() async {
    final token = await _storage.read(key: 'jwt');
    final response = await http.get(
      Uri.parse('$_baseUrl$_portfolioEndpoint'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => PortfolioItemModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load portfolio');
    }
  }
} 