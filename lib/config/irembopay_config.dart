import 'dart:convert';

/// Public key only — use `--dart-define=IREMBOPAY_PUBLIC_KEY=pk_…`
class IremboPayConfig {
  static const String publicKey = String.fromEnvironment(
    'IREMBOPAY_PUBLIC_KEY',
    defaultValue: '',
  );

  static const bool productionWidget = bool.fromEnvironment(
    'IREMBOPAY_PRODUCTION_WIDGET',
    defaultValue: false,
  );

  static String get inlineScriptUrl {
    const prod = 'https://dashboard.irembopay.com/assets/payment/inline.js';
    const sandbox = 'https://dashboard.sandbox.irembopay.com/assets/payment/inline.js';
    if (productionWidget) return prod;
    if (publicKey.startsWith('pk_live')) return prod;
    return sandbox;
  }

  static bool get isConfigured => publicKey.isNotEmpty;

  static String checkoutHtml(String invoiceNumber) {
    final pk = jsonEncode(publicKey);
    final inv = jsonEncode(invoiceNumber);
    final src = inlineScriptUrl;
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
<script src="$src"></script>
</head>
<body style="margin:0;background:#fff;">
<script>
(function() {
  function send(obj) {
    try { IremboPayBridge.postMessage(JSON.stringify(obj)); } catch (e) {}
  }
  function go() {
    if (!window.IremboPay) {
      send({ ok: false, err: 'IremboPay SDK not loaded' });
      return;
    }
    try {
      IremboPay.initiate({
        publicKey: $pk,
        invoiceNumber: $inv,
        locale: IremboPay.locale.EN,
        callback: function(err, resp) {
          if (err) send({ ok: false, err: String(err && err.message ? err.message : err) });
          else send({ ok: true });
        }
      });
    } catch (e) {
      send({ ok: false, err: String(e) });
    }
  }
  setTimeout(go, 600);
})();
</script>
</body>
</html>
''';
  }
}
