import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/env.dart';
import '../logging/app_logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  static bool _isRefreshing = false;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // ── Token Management ──

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> removeToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<void> removeRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Callback dipanggil saat session expired (token tak bisa di-refresh)
  static void Function()? onSessionExpired;

  // ── HTTP Methods ──

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('${Env.apiUrl}$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _headers());
    return _handleResponse(response, path: path, method: 'GET', queryParams: queryParams);
  }

  static Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Env.apiUrl}$path');
    final response = await http.post(uri, headers: await _headers(), body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response, path: path, method: 'POST', body: body);
  }

  static Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${Env.apiUrl}$path');
    final response = await http.put(uri, headers: await _headers(), body: body != null ? jsonEncode(body) : null);
    return _handleResponse(response, path: path, method: 'PUT', body: body);
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('${Env.apiUrl}$path');
    final response = await http.delete(uri, headers: await _headers());
    return _handleResponse(response, path: path, method: 'DELETE');
  }

  // ── Response Handler with Auto-Refresh ──

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    String? path,
    String? method,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401 && !_isRefreshing && path != '/auth/refresh') {
      _isRefreshing = true;
      try {
        final refreshToken = await getRefreshToken();
        if (refreshToken != null) {
          final refreshResponse = await http.post(
            Uri.parse('${Env.apiUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refreshToken}),
          );

          if (refreshResponse.statusCode == 200) {
            final refreshBody = jsonDecode(refreshResponse.body) as Map<String, dynamic>;
            final data = refreshBody['data'] as Map<String, dynamic>;
            await saveToken(data['token'] as String);
            await saveRefreshToken(data['refresh_token'] as String);

            _isRefreshing = false;

            final headers = await _headers();
            final uri = Uri.parse('${Env.apiUrl}$path').replace(queryParameters: queryParams);
            final retryResponse = await _retryRequest(uri, headers, method, body);
            if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
              return jsonDecode(retryResponse.body) as Map<String, dynamic>;
            }
          }
        }
      } catch (e) {
        AppLogger.error('[ApiClient] Refresh token gagal: $e');
      }

      _isRefreshing = false;
      await clearTokens();
      onSessionExpired?.call();
    }

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    final error = responseBody['error'] as Map<String, dynamic>?;
    final message = error?['message'] as String? ?? 'Unknown error';
    throw ApiException(message, statusCode: response.statusCode);
  }

  static Future<http.Response> _retryRequest(
    Uri uri,
    Map<String, String> headers,
    String? method,
    Map<String, dynamic>? body,
  ) async {
    switch (method) {
      case 'GET': return http.get(uri, headers: headers);
      case 'POST': return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'PUT': return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null);
      case 'DELETE': return http.delete(uri, headers: headers);
      default: return http.get(uri, headers: headers);
    }
  }
}
