import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Kunci orientasi layar hanya portrait (atas/bawah)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await initializeDateFormatting('id', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  final initialRoute = authProvider.status == AuthStatus.authenticated
      ? authProvider.dashboardRoute
      : AppRoutes.login;

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: PpiApp(initialRoute: initialRoute ?? AppRoutes.login),
      ),
    );
  }, (error, stack) {
    AppLogger.error('[ZonedError] $error');
    debugPrint('[ZonedError] $error');
  });
}

class PpiApp extends StatelessWidget {
  final String initialRoute;
  const PpiApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MA PERSIS GARUT',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
