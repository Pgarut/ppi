import '../models/user_model.dart';
import '../../core/network/api_client.dart';

class AuthService {
  Future<({String token, String refreshToken, UserModel user})> login({
    required String username,
    required String password,
  }) async {
    final response = await ApiClient.post('/auth/login', body: {
      'username': username,
      'password': password,
    });

    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final refreshToken = data['refresh_token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await ApiClient.saveToken(token);
    await ApiClient.saveRefreshToken(refreshToken);
    return (token: token, refreshToken: refreshToken, user: user);
  }

  Future<void> logout() async {
    await ApiClient.clearTokens();
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await ApiClient.get('/auth/me');
      final data = response['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data);
    } catch (e) {
      // ignore: avoid_print
      print('[Auth] Gagal getCurrentUser: $e');
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await ApiClient.getToken();
    return token != null;
  }
}
