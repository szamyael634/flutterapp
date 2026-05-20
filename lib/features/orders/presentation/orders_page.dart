import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../../../core/models/order.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/orders_repository.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final user = ref.watch(currentUserProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: AsyncValueView(
        value: orders,
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final order = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OrderCard(order: order, user: user),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.user});

  final OrderRecord order;
  final AppUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.orderNumber,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Status: ${order.status.name}'),
            Text('Payment: ${order.paymentStatus}'),
            Text('Total: ${AppFormatters.currency(order.totalAmount)}'),
            Text('Created: ${AppFormatters.shortDate(order.createdAt)}'),
            if (user?.role == AppRole.seller) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(ordersRepositoryProvider)
                          .updateOrderStatus(
                            orderId: order.id,
                            status: 'seller_confirmed',
                          );
                      ref.invalidate(ordersProvider);
                    },
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(ordersRepositoryProvider)
                          .updateOrderStatus(
                            orderId: order.id,
                            status: 'preparing',
                          );
                      ref.invalidate(ordersProvider);
                    },
                    child: const Text('Preparing'),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await ref
                          .read(ordersRepositoryProvider)
                          .updateOrderStatus(
                            orderId: order.id,
                            status: 'ready_for_pickup',
                          );
                      ref.invalidate(ordersProvider);
                    },
                    child: const Text('Ready'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
