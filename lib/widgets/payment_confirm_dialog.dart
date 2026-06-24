import 'package:flutter/material.dart';
import 'package:ryde_rw/service/payment_polling_service.dart';

/// Blocking dialog that polls until webhook confirms payment.
Future<String?> showPaymentConfirmDialog(
  BuildContext context, {
  required String title,
  required Future<String> Function() poll,
  String? successMessage,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentConfirmDialog(
      title: title,
      poll: poll,
      successMessage: successMessage,
    ),
  );
}

class _PaymentConfirmDialog extends StatefulWidget {
  final String title;
  final Future<String> Function() poll;
  final String? successMessage;

  const _PaymentConfirmDialog({
    required this.title,
    required this.poll,
    this.successMessage,
  });

  @override
  State<_PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<_PaymentConfirmDialog> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.poll();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Confirming your payment…'),
                SizedBox(height: 8),
                Text(
                  'Waiting for payment confirmation from the server.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          final outcome = snapshot.data ?? 'TIMEOUT';
          final message = PaymentPollingService.messageForOutcome(
            outcome,
            successMessage: widget.successMessage,
          );
          final isSuccess = outcome == 'COMPLETED';
          final isFailed = outcome == 'FAILED';

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuccess
                    ? Icons.check_circle
                    : isFailed
                        ? Icons.cancel
                        : Icons.schedule,
                color: isSuccess
                    ? Colors.green
                    : isFailed
                        ? Colors.red
                        : Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          );
        },
      ),
      actions: [
        FutureBuilder<String>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            return TextButton(
              onPressed: () => Navigator.of(context).pop(snapshot.data),
              child: const Text('OK'),
            );
          },
        ),
      ],
    );
  }
}
