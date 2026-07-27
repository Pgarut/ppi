class Env {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  static const String apiPrefix = '/api';
  static String get apiUrl => '$baseUrl$apiPrefix';

  static const String appName = 'Sistem Informasi Madrasah PPI';
  static const String appVersion = '1.0.0';
}
