import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

/// Fallback in-app checkout when the external browser cannot be opened.
class IremboPayCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;

  const IremboPayCheckoutScreen({super.key, required this.checkoutUrl});

  @override
  State<IremboPayCheckoutScreen> createState() => _IremboPayCheckoutScreenState();
}

class _IremboPayCheckoutScreenState extends State<IremboPayCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() { _loading = true; _loadError = null; });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (err) {
            if (mounted) {
              setState(() {
                _loading = false;
                _loadError = err.description;
              });
            }
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

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.checkoutUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Now'),
        actions: [
          IconButton(
            tooltip: 'Open in browser',
            onPressed: _openInBrowser,
            icon: const Icon(Icons.open_in_browser),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
          if (_loadError != null && !_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load payment page in the app.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openInBrowser,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in browser'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
