import 'dart:async';
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
  static const String _tokenExpiryKey = 'token_expiry';

  static bool _isRefreshing = false;
  static Timer? _refreshTimer;
  static const Duration _refreshBeforeExpiry = Duration(minutes: 5);

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
    await _storage.delete(key: _tokenExpiryKey);
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // Callback dipanggil saat session expired (token tak bisa di-refresh)
  static void Function()? onSessionExpired;

  // ── Proactive Token Refresh ──

  /// Simpan expiry time saat token baru didapat
  static Future<void> _saveTokenExpiry(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return;
      final payload = jsonDecode(utf8.decode(base64Url.decode(parts[1])));
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        await _storage.write(key: _tokenExpiryKey, value: expiryTime.toIso8601String());
        _scheduleRefresh(expiryTime);
      }
    } catch (e) {
      AppLogger.error('[ApiClient] Gagal parse token expiry: $e');
    }
  }

  /// Cek apakah token hampir expired (dalam 5 menit)
  static Future<bool> _isTokenExpiringSoon() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return true;
      final expiryTime = DateTime.parse(expiryStr);
      return DateTime.now().add(_refreshBeforeExpiry).isAfter(expiryTime);
    } catch (_) {
      return true;
    }
  }

  /// Schedule refresh otomatis sebelum token expired
  static void _scheduleRefresh(DateTime expiryTime) {
    _refreshTimer?.cancel();
    final refreshAt = expiryTime.subtract(_refreshBeforeExpiry);
    final now = DateTime.now();
    if (refreshAt.isAfter(now)) {
      final delay = refreshAt.difference(now);
      _refreshTimer = Timer(delay, () async {
        AppLogger.info('[ApiClient] Proactive refresh token');
        await _proactiveRefresh();
      });
    } else {
      // Sudah lewat waktu refresh, refresh sekarang
      _proactiveRefresh();
    }
  }

  /// Refresh token secara proaktif (tanpa menunggu 401)
  static Future<bool> _proactiveRefresh() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final refreshToken = await getRefreshToken();
      final currentToken = await getToken();

      if (refreshToken == null || currentToken == null) {
        _isRefreshing = false;
        return false;
      }

      final refreshResponse = await http.post(
        Uri.parse('${Env.apiUrl}/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': refreshToken,
          'token': currentToken,
        }),
      );

      if (refreshResponse.statusCode == 200) {
        final refreshBody = jsonDecode(refreshResponse.body) as Map<String, dynamic>;
        final data = refreshBody['data'] as Map<String, dynamic>;
        final newToken = data['token'] as String;
        await saveToken(newToken);
        await saveRefreshToken(data['refresh_token'] as String);
        await _saveTokenExpiry(newToken);
        _isRefreshing = false;
        AppLogger.info('[ApiClient] Proactive refresh berhasil');
        return true;
      }

      _isRefreshing = false;
      return false;
    } catch (e) {
      AppLogger.error('[ApiClient] Proactive refresh gagal: $e');
      _isRefreshing = false;
      return false;
    }
  }

  /// Pastikan token valid sebelum request (proactive check)
  static Future<String?> _ensureValidToken() async {
    final token = await getToken();
    if (token == null) return null;

    if (await _isTokenExpiringSoon()) {
      AppLogger.info('[ApiClient] Token hampir expired, refresh proaktif...');
      final refreshed = await _proactiveRefresh();
      if (refreshed) {
        return await getToken();
      }
      // Refresh gagal, token mungkin masih bisa dipakai sebentar
      return token;
    }

    return token;
  }

  /// Mulai proactive refresh timer (panggil saat login berhasil)
  static Future<void> startRefreshTimer() async {
    final token = await getToken();
    if (token != null) {
      await _saveTokenExpiry(token);
    }
  }

  /// Cek apakah user masih punya session valid
  static Future<bool> hasValidSession() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();
    if (token == null && refreshToken == null) return false;
    if (token != null && !(await _isTokenExpiringSoon())) return true;
    if (refreshToken != null) return true;
    return false;
  }

  // ── HTTP Methods ──

  static Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final token = await _ensureValidToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Kirim request logout ke backend untuk revoke session
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await post('/auth/logout', body: {'token': token});
      }
    } catch (e) {
      AppLogger.error('[ApiClient] Logout gagal: $e');
    }
    await clearTokens();
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
        final currentToken = await getToken();

        if (refreshToken == null || currentToken == null) {
          _isRefreshing = false;
          await clearTokens();
          onSessionExpired?.call();
          throw ApiException('Sesi telah berakhir. Silakan login kembali.', statusCode: 401);
        }

        final refreshResponse = await http.post(
          Uri.parse('${Env.apiUrl}/auth/refresh'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'refresh_token': refreshToken,
            'token': currentToken,
          }),
        );

        if (refreshResponse.statusCode == 200) {
          final refreshBody = jsonDecode(refreshResponse.body) as Map<String, dynamic>;
          final data = refreshBody['data'] as Map<String, dynamic>;
          final newToken = data['token'] as String;
          await saveToken(newToken);
          await saveRefreshToken(data['refresh_token'] as String);
          await _saveTokenExpiry(newToken);

          _isRefreshing = false;

          final headers = await _headers();
          final uri = Uri.parse('${Env.apiUrl}$path').replace(queryParameters: queryParams);
          final retryResponse = await _retryRequest(uri, headers, method, body);
          if (retryResponse.statusCode >= 200 && retryResponse.statusCode < 300) {
            return jsonDecode(retryResponse.body) as Map<String, dynamic>;
          }

          final retryBody = jsonDecode(retryResponse.body) as Map<String, dynamic>;
          final retryError = retryBody['error'] as Map<String, dynamic>?;
          final retryMessage = retryError?['message'] as String? ?? 'Unknown error';
          throw ApiException(retryMessage, statusCode: retryResponse.statusCode);
        }

        _isRefreshing = false;
        await clearTokens();
        onSessionExpired?.call();
        throw ApiException('Sesi telah berakhir. Silakan login kembali.', statusCode: 401);
      } on ApiException {
        rethrow;
      } catch (e) {
        AppLogger.error('[ApiClient] Refresh token gagal: $e');
        _isRefreshing = false;
        await clearTokens();
        onSessionExpired?.call();
        throw ApiException('Sesi telah berakhir. Silakan login kembali.', statusCode: 401);
      }
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
