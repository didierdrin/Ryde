import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:ryde_rw/config/irembopay_config.dart';

class IremboPayWebViewScreen extends StatefulWidget {
  final String invoiceNumber;

  const IremboPayWebViewScreen({super.key, required this.invoiceNumber});

  @override
  State<IremboPayWebViewScreen> createState() => _IremboPayWebViewScreenState();
}

class _IremboPayWebViewScreenState extends State<IremboPayWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'IremboPayBridge',
        onMessageReceived: (JavaScriptMessage message) {
          if (!mounted) return;
          try {
            final data = json.decode(message.message) as Map<String, dynamic>?;
            final ok = data?['ok'] == true;
            Navigator.of(context).pop(ok);
          } catch (_) {
            Navigator.of(context).pop(false);
          }
        },
      )
      ..loadHtmlString(IremboPayConfig.checkoutHtml(widget.invoiceNumber));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay with IremboPay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
