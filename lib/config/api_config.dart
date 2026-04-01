class ApiConfig {
  /// Override at build/run time: `--dart-define=RYDE_API_BASE_URL=https://host/api`
  static const String baseUrl = String.fromEnvironment(
    'RYDE_API_BASE_URL',
    defaultValue: 'https://ryde-backend-eqog.onrender.com/api',
  );
}
