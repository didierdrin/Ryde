import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ryde_rw/config/api_config.dart';
import 'package:ryde_rw/screens/payments/irembopay_checkout.dart';

/// Opens Ryde/IremboPay checkout at `{API host}/api/payments/checkout/{invoiceNumber}`.
/// Prefers the device browser; falls back to in-app WebView if the browser cannot open.
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

  /// Build checkout URL from the invoice number and [ApiConfig.hostBase].
  /// Ignores backend [checkoutUrl] host (Railway may return an internal hostname).
  static String resolveCheckoutUrl(Map<String, dynamic> invoiceResponse) {
    final invoiceNumber = invoiceNumberFromResponse(invoiceResponse);
    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      return checkoutUrl(invoiceNumber);
    }
    throw Exception('Could not resolve payment checkout URL');
  }

  /// Returns [null] when checkout opened in the external browser.
  static Future<IremboPayCheckoutResult?> openCheckout(
    BuildContext context,
    String checkoutUrl, {
    bool preferExternalBrowser = true,
  }) async {
    final uri = Uri.parse(checkoutUrl);

    if (preferExternalBrowser) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return null;
      } catch (_) {}
    }

    if (!context.mounted) return null;
    return Navigator.of(context).push<IremboPayCheckoutResult>(
      MaterialPageRoute(
        builder: (_) => IremboPayCheckoutScreen(checkoutUrl: checkoutUrl),
      ),
    );
  }

  static Future<IremboPayCheckoutResult?> openCheckoutForInvoice(
    BuildContext context,
    Map<String, dynamic> invoiceResponse, {
    bool preferExternalBrowser = true,
  }) {
    return openCheckout(
      context,
      resolveCheckoutUrl(invoiceResponse),
      preferExternalBrowser: preferExternalBrowser,
    );
  }
}
