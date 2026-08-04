import 'dart:async';
import 'package:flutter/material.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/auth_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/logging/app_logger.dart';
import '../../../config/routes.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  String? _error;
  Timer? _inactivityTimer;
  static const _inactivityTimeout = Duration(minutes: 30);

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;

  AuthProvider() {
    ApiClient.onSessionExpired = _onSessionExpired;
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_status == AuthStatus.authenticated) {
      _inactivityTimer = Timer(_inactivityTimeout, () {
        AppLogger.info('[Auth] Auto-logout karena 30 menit tidak ada aktivitas');
        _onSessionExpired();
      });
    }
  }

  void _onSessionExpired() {
    _inactivityTimer?.cancel();
    _performLogout();
  }

  Future<void> _performLogout() async {
    await _authService.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Panggil method ini dari screen manapun saat user melakukan aktivitas (tap, scroll, dll)
  void notifyActivity() {
    _resetInactivityTimer();
  }

  Future<void> tryAutoLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        _resetInactivityTimer();
        notifyListeners();
        return;
      }
      // Token expired dan refresh gagal -> clearTokens sudah dilakukan di ApiClient
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login(String credential, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        credential: credential,
        password: password,
      );
      _user = result.user;
      _status = AuthStatus.authenticated;
      _resetInactivityTimer();
      notifyListeners();
    } on Exception catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _inactivityTimer?.cancel();
    try {
      await _authService.logout();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String? get dashboardRoute {
    if (_user == null) return null;
    return AppRoutes.dashboardByRole(_user!.role);
  }
}
