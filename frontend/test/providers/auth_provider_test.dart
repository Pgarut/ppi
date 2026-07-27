import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ppi_frontend/features/auth/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    test('initial status should be uninitialized', () {
      final provider = AuthProvider();
      expect(provider.status, AuthStatus.uninitialized);
      expect(provider.user, isNull);
      expect(provider.error, isNull);
    });

    test('dashboardRoute should return null when no user', () {
      final provider = AuthProvider();
      expect(provider.dashboardRoute, isNull);
    });

    test('logout should reset state', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AuthProvider();
      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
    });

    test('login should fail gracefully without backend', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = AuthProvider();

      expect(provider.status, AuthStatus.uninitialized);

      await provider.login('admin', 'wrong');

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.error, isNotNull);
    });
  });
}
