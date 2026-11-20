import 'package:flutter/material.dart';

class RetryPanel extends StatelessWidget {
  final String message;
  final VoidCallback? retry;
  const RetryPanel(this.message, this.retry, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(message, textAlign: TextAlign.center),
      TextButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh),
        label: const Text('Повторить'),
      ),
    ],
  );
}
