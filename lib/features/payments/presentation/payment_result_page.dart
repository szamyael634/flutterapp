import 'package:flutter/material.dart';

class PaymentResultPage extends StatelessWidget {
  const PaymentResultPage({
    super.key,
    required this.orderId,
    required this.status,
  });

  final String orderId;
  final String status;

  bool get isSuccess => status.toLowerCase() == 'success';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSuccess ? Icons.check_circle : Icons.cancel,
                      size: 56,
                      color: isSuccess
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSuccess ? 'Payment successful' : 'Payment not completed',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isSuccess
                          ? 'Your PayMongo checkout finished successfully. You can return to Mama\'s Kitchen and track the order there.'
                          : 'The checkout was cancelled or failed. You can return to Mama\'s Kitchen and try again.',
                    ),
                    const SizedBox(height: 16),
                    SelectableText('Order ID: $orderId'),
                    const SizedBox(height: 8),
                    SelectableText('Status: $status'),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (_) => const _ReturnHintPage(),
                          ),
                          (_) => false,
                        );
                      },
                      child: const Text('Back to app'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnHintPage extends StatelessWidget {
  const _ReturnHintPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You can close this tab and return to Mama\'s Kitchen.',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'If you are using the web app directly, reopen the main site URL to continue browsing.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
