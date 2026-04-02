class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'RYDE_API_BASE_URL',
    defaultValue: 'https://ryde-backend-eqog.onrender.com/api',
  );
}
