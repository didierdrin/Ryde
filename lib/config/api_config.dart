/// Backend API configuration for the mobile app.
///
/// **Default:** production Railway (IremboPay checkout works there).
/// The mobile app never reads `IREMBOPAY_*` env vars — payment opens
/// `{API host}/api/payments/checkout/{invoiceNumber}` in the browser or WebView.
class ApiConfig {
  static const String productionBaseUrl =
      'https://ryde-backend-production.up.railway.app/api';

  /// Override at run/build time with `--dart-define=API_BASE_URL=...`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  static String get hostBase =>
      baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  static String checkoutUrl(String invoiceNumber) =>
      '$hostBase/api/payments/checkout/$invoiceNumber';

  static bool get isLocalBackend {
    final lower = baseUrl.toLowerCase();
    return lower.contains('localhost') ||
        lower.contains('127.0.0.1') ||
        lower.contains('10.0.2.2') ||
        RegExp(r':\d{4,5}').hasMatch(lower);
  }

  static bool get usesProductionBackend =>
      !isLocalBackend || baseUrl == productionBaseUrl;
}
