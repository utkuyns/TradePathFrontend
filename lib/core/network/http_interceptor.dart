import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

class HttpInterceptor {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static GlobalKey<NavigatorState>? navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final token = await _storage.read(key: 'jwt');
    final updatedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    if (token != null) {
      updatedHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: updatedHeaders);
      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    final token = await _storage.read(key: 'jwt');
    final updatedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    if (token != null) {
      updatedHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.post(url, headers: updatedHeaders, body: body);
      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    final token = await _storage.read(key: 'jwt');
    final updatedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    if (token != null) {
      updatedHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.put(url, headers: updatedHeaders, body: body);
      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) async {
    final token = await _storage.read(key: 'jwt');
    final updatedHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };
    
    if (token != null) {
      updatedHeaders['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.delete(url, headers: updatedHeaders, body: body);
      await _handleResponse(response);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Token geçersiz, kullanıcıyı login sayfasına yönlendir
      await _storage.delete(key: 'jwt');
      _redirectToLogin();
    }
  }

  static void _redirectToLogin() {
    if (navigatorKey?.currentContext != null) {
      Navigator.of(navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }
} 