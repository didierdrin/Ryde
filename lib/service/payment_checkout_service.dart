import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ryde_rw/config/api_config.dart';
import 'package:ryde_rw/screens/payments/irembopay_checkout.dart';

/// Opens Ryde/IremboPay checkout at `/api/payments/checkout/:invoiceNumber`.
/// The mobile app does not need IremboPay env vars — only the backend checkout page does.
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

  static String resolveCheckoutUrl(Map<String, dynamic> invoiceResponse) {
    final direct = (invoiceResponse['checkoutUrl'] ??
            invoiceResponse['checkout_url'])
        ?.toString();
    if (direct != null && direct.isNotEmpty) return direct;

    final invoiceNumber = invoiceNumberFromResponse(invoiceResponse);
    if (invoiceNumber == null || invoiceNumber.isEmpty) {
      throw Exception('Could not resolve payment checkout URL');
    }
    return checkoutUrl(invoiceNumber);
  }

  /// Prefer the device browser — IremboPay works more reliably there than in WebView.
  /// Returns a WebView result when in-app checkout is used; [null] when opened externally.
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
