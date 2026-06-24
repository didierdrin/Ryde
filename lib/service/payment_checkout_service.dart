import 'package:flutter/material.dart';
import 'package:ryde_rw/config/api_config.dart';
import 'package:ryde_rw/screens/payments/irembopay_checkout.dart';
import 'package:ryde_rw/service/irembopay_widget_html.dart';

/// Opens IremboPay checkout with the inline widget (same flow as ryde-web).
/// The backend creates the invoice; the app opens the widget with the public key.
class PaymentCheckoutService {
  static String checkoutUrl(String invoiceNumber) =>
      ApiConfig.checkoutUrl(invoiceNumber.trim());

  static String? invoiceNumberFromResponse(Map<String, dynamic> res) {
    final fromBody = (res['invoiceNumber'] ?? res['invoice_number'])?.toString();
    if (fromBody != null && fromBody.isNotEmpty) return fromBody;

    final checkout = (res['checkoutUrl'] ?? res['checkout_url'])?.toString();
    if (checkout != null && checkout.isNotEmpty) {
      final uri = Uri.tryParse(checkout);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    }
    return null;
  }

  static String resolveEnvironment(Map<String, dynamic> invoiceResponse) {
    final fromApi = (invoiceResponse['irembopayEnvironment'] ??
            invoiceResponse['irembopay_environment'])
        ?.toString();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return ApiConfig.irembopayEnvironment;
  }

  static String resolvePublicKey(Map<String, dynamic> invoiceResponse) {
    final fromApi =
        (invoiceResponse['publicKey'] ?? invoiceResponse['irembopay_public_key'])
            ?.toString();
    if (fromApi != null && fromApi.isNotEmpty) return fromApi;
    return ApiConfig.ipayPublicKey;
  }

  /// Prefer invoice number + [ApiConfig.hostBase]; ignore backend [checkoutUrl] host
  /// (Railway may return an internal hostname that is not reachable from the device).
  static String resolveCheckoutUrl(Map<String, dynamic> invoiceResponse) {
    final invoiceNumber = invoiceNumberFromResponse(invoiceResponse);
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      return checkoutUrl(invoiceNumber);
    }
    throw Exception('Could not resolve payment checkout URL');
  }

  static Future<IremboPayCheckoutResult?> openCheckoutForInvoice(
    BuildContext context,
    Map<String, dynamic> invoiceResponse,
  ) async {
    final invoiceNumber = invoiceNumberFromResponse(invoiceResponse);
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      throw Exception('Could not resolve payment invoice number');
    }

    final publicKey = resolvePublicKey(invoiceResponse);
    if (publicKey.isEmpty) {
      throw Exception(
        'IremboPay public key is not configured. Build with '
        '--dart-define=IPAY_PUBLIC_KEY=pk_... (same as REACT_APP_IPAY_PUBLIC_KEY on ryde-web), '
        'or set IREMBOPAY_PUBLIC_KEY on the backend.',
      );
    }

    final environment = resolveEnvironment(invoiceResponse);
    final html = IremboPayWidgetHtml.build(
      publicKey: publicKey,
      invoiceNumber: invoiceNumber,
      environment: environment,
    );
    final baseUrl = IremboPayWidgetHtml.baseUrlForEnvironment(environment);

    if (!context.mounted) return null;
    return Navigator.of(context).push<IremboPayCheckoutResult>(
      MaterialPageRoute(
        builder: (_) => IremboPayCheckoutScreen(
          htmlContent: html,
          baseUrl: baseUrl,
          invoiceNumber: invoiceNumber,
        ),
      ),
    );
  }
}
