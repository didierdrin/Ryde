/// Builds the same hosted-checkout HTML as ryde-backend `/api/payments/checkout/:invoice`,
/// but runs inside the app WebView with the public key (like ryde-web's inline widget).
class IremboPayWidgetHtml {
  static String scriptSrcForEnv(String env) {
    final e = env.toLowerCase();
    if (e == 'production' || e == 'prod') {
      return 'https://dashboard.irembopay.com/assets/payment/inline.js';
    }
    if (e == 'checkout') {
      return 'https://dashboard.checkout.irembopay.com/assets/payment/inline.js';
    }
    return 'https://dashboard.sandbox.irembopay.com/assets/payment/inline.js';
  }

  static String baseUrlForEnvironment(String env) {
    final uri = Uri.parse(scriptSrcForEnv(env));
    return '${uri.scheme}://${uri.host}';
  }

  static String build({
    required String publicKey,
    required String invoiceNumber,
    String environment = 'sandbox',
  }) {
    final scriptSrc = scriptSrcForEnv(environment);
    final safeKey = _escapeJs(publicKey.trim());
    final safeInvoice = _escapeJs(invoiceNumber.trim());

    return '''<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Ryde • Pay</title>
    <script src="$scriptSrc"></script>
    <style>
      body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; margin: 0; padding: 16px; background: #f6f7fb; }
      .card { max-width: 560px; margin: 0 auto; background: #fff; border-radius: 12px; padding: 16px; box-shadow: 0 8px 24px rgba(0,0,0,.08); }
      .muted { color: #6b7280; font-size: 14px; margin-top: 8px; }
      .btn { margin-top: 12px; display: inline-block; background: #111827; color: #fff; padding: 10px 12px; border-radius: 10px; text-decoration: none; }
    </style>
  </head>
  <body>
    <div class="card">
      <div><strong>Pay with IremboPay</strong></div>
      <div class="muted">Invoice: $safeInvoice</div>
      <div id="status" class="muted">Opening payment…</div>
      <a class="btn" href="javascript:void(0)" onclick="start()">Open again</a>
    </div>
    <script>
      function postResult(payload) {
        try {
          if (window.PaymentResult && window.PaymentResult.postMessage) {
            window.PaymentResult.postMessage(JSON.stringify(payload));
          }
        } catch (_) {}
      }
      function start() {
        var statusEl = document.getElementById('status');
        if (!window.IremboPay || !window.IremboPay.initiate) {
          statusEl.textContent = 'Payment system not ready. Please refresh.';
          postResult({ ok: false, reason: 'IREMBO_WIDGET_NOT_READY' });
          return;
        }
        statusEl.textContent = 'Payment widget opened.';
        window.IremboPay.initiate({
          publicKey: "$safeKey",
          invoiceNumber: "$safeInvoice",
          locale: window.IremboPay.locale ? window.IremboPay.locale.EN : "EN",
          callback: function(err) {
            if (!err) {
              statusEl.textContent = 'Payment submitted. You can close this window.';
              postResult({ ok: true });
            } else {
              statusEl.textContent = 'Payment cancelled or failed. You can close this window.';
              postResult({ ok: false, reason: 'CANCELLED_OR_FAILED' });
            }
          }
        });
      }
      setTimeout(start, 50);
    </script>
  </body>
</html>''';
  }

  static String _escapeJs(String value) =>
      value.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
}
