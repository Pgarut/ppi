import '../models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/logging/app_logger.dart';

class AuthService {
  Future<({String token, String refreshToken, UserModel user})> login({
    required String credential,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/login', body: {
      'username': credential,
      'password': password,
    });

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw Exception('Data login tidak valid');

    final token = data['token'] as String?;
    if (token == null) throw Exception('Token tidak ditemukan');

    final refreshToken = data['refresh_token'] as String?;
    if (refreshToken == null) throw Exception('Refresh token tidak ditemukan');

    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) throw Exception('Data user tidak ditemukan');
    final user = UserModel.fromJson(userData);

    await ApiClient.saveToken(token);
    await ApiClient.saveRefreshToken(refreshToken);
    await ApiClient.startRefreshTimer();
    return (token: token, refreshToken: refreshToken, user: user);
  }

  Future<void> logout() async {
    await ApiClient.logout();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.get('/auth/me');
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return UserModel.fromJson(data);
    } catch (e) {
      AppLogger.error('[Auth] Gagal getCurrentUser: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }
}
