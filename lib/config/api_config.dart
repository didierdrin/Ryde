/// Backend API configuration for the mobile app.
///
/// **Default:** production Railway (IremboPay is configured there).
///
/// To point at a local backend during development:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
/// ```
/// Android emulator: `http://10.0.2.2:3000/api`
/// iOS simulator: `http://localhost:3000/api`
/// Physical device: `http://YOUR_LAN_IP:3000/api`
///
/// Local backend requires the same IremboPay env vars as production (`IREMBOPAY_*`
/// in `ryde-backend/.env`). Otherwise invoice creation fails with
/// "IremboPay is not configured" errors.
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
