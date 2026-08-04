import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  // Unhandled errors
  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const PpiApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error('[ZonedError] $error');
    debugPrint('[ZonedError] $error');
  });
}

class PpiApp extends StatelessWidget {
  const PpiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistem Informasi PPI',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (_, auth, __) {
          if (auth.status == AuthStatus.uninitialized || auth.status == AuthStatus.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (auth.status == AuthStatus.authenticated && auth.dashboardRoute != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed(auth.dashboardRoute!);
            });
          }
          return const LoginScreen();
        },
      ),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
