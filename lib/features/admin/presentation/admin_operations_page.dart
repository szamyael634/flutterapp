import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/admin_repository.dart';
import '../models/admin_operations_data.dart';

class AdminOperationsPage extends ConsumerWidget {
  const AdminOperationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(adminOperationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Operations Monitor')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminOperationsProvider);
          ref.invalidate(adminDashboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueView(
              value: operations,
              data: (data) => Column(
                children: [
                  _SectionCard(
                    title: 'Order monitoring',
                    child: data.orders.isEmpty
                        ? const Text('No orders available yet.')
                        : Column(
                            children: data.orders
                                .map((order) => _OrderTile(order: order))
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Product monitoring',
                    child: data.products.isEmpty
                        ? const Text('No products available yet.')
                        : Column(
                            children: data.products
                                .map(
                                  (product) => _ProductTile(product: product),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final AdminMonitoredOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(order.orderNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${order.status} - ${order.paymentMethod.toUpperCase()} - ${order.paymentStatus}',
            ),
            Text(order.storeName),
            if (order.buyerEmail.isNotEmpty) Text(order.buyerEmail),
            Text(AppFormatters.shortDate(order.createdAt)),
          ],
        ),
        trailing: Text(AppFormatters.currency(order.totalAmount)),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final AdminMonitoredProduct product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${product.storeName} - ${product.category}'),
            Text(
              '${product.listingStatus} - ${product.recommendationStatus} - Qty ${product.quantity}',
            ),
            Text('Expires ${AppFormatters.shortDate(product.expirationAt)}'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppFormatters.currency(product.currentPrice)),
            if (product.discountPercent > 0)
              Text('${product.discountPercent}% off'),
            if (product.isNearExpiry) const Chip(label: Text('Near expiry')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
