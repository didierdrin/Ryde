/// Backend API configuration for the mobile app.
///
/// **Default:** production Railway API. Payments use the IremboPay inline widget
/// in a WebView (same as ryde-web), not the backend-hosted checkout page.
class ApiConfig {
  static const String productionBaseUrl =
      'https://ryde-backend-production.up.railway.app/api';

  /// Override at run/build time with `--dart-define=API_BASE_URL=...`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: productionBaseUrl,
  );

  /// IremboPay widget public key (`pk_…`). Same as ryde-web `REACT_APP_IPAY_PUBLIC_KEY`.
  /// Override with `--dart-define=IPAY_PUBLIC_KEY=pk_...`
  static const String ipayPublicKey = String.fromEnvironment(
    'IPAY_PUBLIC_KEY',
    defaultValue: '',
  );

  /// `sandbox`, `checkout`, or `production` — must match the public key.
  static const String irembopayEnvironment = String.fromEnvironment(
    'IREMBOPAY_ENVIRONMENT',
    defaultValue: 'sandbox',
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
