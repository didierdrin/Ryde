import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class IremboPayCheckoutResult {
  final bool ok;
  final String? reason;

  const IremboPayCheckoutResult({required this.ok, this.reason});

  factory IremboPayCheckoutResult.fromMessage(String message) {
    try {
      final decoded = json.decode(message);
      if (decoded is Map<String, dynamic>) {
        return IremboPayCheckoutResult(
          ok: decoded['ok'] == true,
          reason: decoded['reason']?.toString(),
        );
      }
    } catch (_) {}
    return const IremboPayCheckoutResult(ok: false, reason: 'INVALID_MESSAGE');
  }
}

class IremboPayCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;

  const IremboPayCheckoutScreen({super.key, required this.checkoutUrl});

  @override
  State<IremboPayCheckoutScreen> createState() => _IremboPayCheckoutScreenState();
}

class _IremboPayCheckoutScreenState extends State<IremboPayCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..addJavaScriptChannel(
        'PaymentResult',
        onMessageReceived: (msg) {
          final result = IremboPayCheckoutResult.fromMessage(msg.message);
          if (mounted) Navigator.of(context).pop(result);
        },
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Now'),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

