import 'package:flutter/material.dart';
import 'package:ryde_rw/service/payment_polling_service.dart';

/// Payment confirmation dialog.
///
/// When [clientConfirmed] is true (IremboPay widget callback succeeded), success is shown
/// immediately. Optional [poll] runs in the background to sync webhook-updated status.
Future<String?> showPaymentConfirmDialog(
  BuildContext context, {
  required String title,
  Future<String> Function()? poll,
  String? successMessage,
  bool clientConfirmed = false,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PaymentConfirmDialog(
      title: title,
      poll: poll,
      successMessage: successMessage,
      clientConfirmed: clientConfirmed,
    ),
  );
}

class _PaymentConfirmDialog extends StatefulWidget {
  final String title;
  final Future<String> Function()? poll;
  final String? successMessage;
  final bool clientConfirmed;

  const _PaymentConfirmDialog({
    required this.title,
    this.poll,
    this.successMessage,
    this.clientConfirmed = false,
  });

  @override
  State<_PaymentConfirmDialog> createState() => _PaymentConfirmDialogState();
}

class _PaymentConfirmDialogState extends State<_PaymentConfirmDialog> {
  String? _outcome;
  String? _message;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    if (widget.clientConfirmed) {
      _outcome = 'CLIENT_CONFIRMED';
      _message = widget.successMessage ?? 'Payment successful!';
      _runBackgroundPoll();
    } else if (widget.poll != null) {
      _polling = true;
      _runPoll();
    } else {
      _outcome = 'TIMEOUT';
      _message = PaymentPollingService.messageForOutcome('TIMEOUT');
    }
  }

  Future<void> _runPoll() async {
    try {
      final outcome = await widget.poll!();
      if (!mounted) return;
      setState(() {
        _polling = false;
        _outcome = outcome;
        _message = PaymentPollingService.messageForOutcome(
          outcome,
          successMessage: widget.successMessage,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _polling = false;
        _outcome = 'ERROR';
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _runBackgroundPoll() {
    final poll = widget.poll;
    if (poll == null) return;
    poll();
  }

  @override
  Widget build(BuildContext context) {
    final outcome = _outcome ?? 'TIMEOUT';
    final isSuccess = outcome == 'COMPLETED' || outcome == 'CLIENT_CONFIRMED';
    final isFailed = outcome == 'FAILED' || outcome == 'ERROR';

    return AlertDialog(
      title: Text(widget.title),
      content: _polling
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Confirming your payment…'),
              ],
            )
          : Column(
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
                Text(_message ?? '', textAlign: TextAlign.center),
                if (widget.clientConfirmed) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Your receipt will sync automatically.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
      actions: [
        if (!_polling)
          TextButton(
            onPressed: () => Navigator.of(context).pop(outcome),
            child: const Text('OK'),
          ),
      ],
    );
  }
}
