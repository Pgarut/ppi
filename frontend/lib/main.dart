import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  
  // Kunci orientasi layar hanya portrait untuk mobile
  // Skip di web/desktop karena tidak relevan dan bisa menyebabkan masalah
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  await initializeDateFormatting('id', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // Auto-login dengan error handling yang robust
  // Jika gagal, fallback ke login screen (jangan crash app!)
  String initialRoute = AppRoutes.login;
  try {
    final authProvider = AuthProvider();
    await authProvider.tryAutoLogin();

    if (authProvider.status == AuthStatus.authenticated) {
      initialRoute = authProvider.dashboardRoute ?? AppRoutes.login;
    }

    runZonedGuarded(() {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: authProvider),
          ],
          child: PpiApp(initialRoute: initialRoute),
        ),
      );
    }, (error, stack) {
      AppLogger.error('[ZonedError] $error');
      debugPrint('[ZonedError] $error');
    });
  } catch (e, stack) {
    // Jika auto-login crash total, tetap jalankan app ke login screen
    AppLogger.error('[Main] Auto-login crash, fallback ke login: $e');
    debugPrint('[Main] Auto-login crash, fallback ke login: $e');
    debugPrint('[Main] Stack: $stack');

    runZonedGuarded(() {
      runApp(
        const PpiApp(initialRoute: AppRoutes.login),
      );
    }, (error, stack) {
      AppLogger.error('[ZonedError] $error');
      debugPrint('[ZonedError] $error');
    });
  }
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
