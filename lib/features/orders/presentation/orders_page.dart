import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/order.dart';
import '../../../core/models/order_review_target.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../disputes/data/disputes_repository.dart';
import '../../reviews/data/reviews_repository.dart';
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
            if (user != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (order.status == OrderStatus.delivered &&
                      user!.role == AppRole.buyer)
                    FilledButton.tonal(
                      onPressed: () async {
                        final targets = await ref
                            .read(ordersRepositoryProvider)
                            .fetchReviewTargets(order: order);
                        if (!context.mounted) {
                          return;
                        }
                        await _showReviewDialog(
                          context,
                          ref,
                          order: order,
                          authorId: user!.id,
                          targets: targets,
                        );
                      },
                      child: const Text('Leave review'),
                    ),
                  OutlinedButton(
                    onPressed: () async {
                      if (user == null) {
                        return;
                      }
                      await _showDisputeDialog(
                        context,
                        ref,
                        order: order,
                        reporterId: user!.id,
                      );
                    },
                    child: const Text('Report issue'),
                  ),
                ],
              ),
            ],
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

Future<void> _showReviewDialog(
  BuildContext context,
  WidgetRef ref, {
  required OrderRecord order,
  required String authorId,
  required List<OrderReviewTarget> targets,
}) async {
  if (targets.isEmpty) {
    context.showSnackBar(
      'No review targets found for this order.',
      isError: true,
    );
    return;
  }

  int rating = 5;
  String selectedTargetId = targets.first.targetId;
  String selectedTargetType = targets.first.targetType;
  final commentController = TextEditingController();

  final shouldSubmit = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Review ${order.orderNumber}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedTargetId,
                  decoration: const InputDecoration(labelText: 'Review target'),
                  items: targets
                      .map(
                        (target) => DropdownMenuItem(
                          value: target.targetId,
                          child: Text('${target.targetType}: ${target.label}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final selected = targets.firstWhere(
                      (target) => target.targetId == value,
                      orElse: () => targets.first,
                    );
                    setState(() {
                      selectedTargetId = selected.targetId;
                      selectedTargetType = selected.targetType;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: rating,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  items: [5, 4, 3, 2, 1]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text('$value stars'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => rating = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Comment'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );

  if (shouldSubmit == true) {
    await ref
        .read(reviewsRepositoryProvider)
        .submitReview(
          orderId: order.id,
          authorId: authorId,
          targetType: selectedTargetType,
          targetId: selectedTargetId,
          rating: rating,
          comment: commentController.text.trim(),
        );
    if (context.mounted) {
      context.showSnackBar('Review submitted');
    }
  }

  commentController.dispose();
}

Future<void> _showDisputeDialog(
  BuildContext context,
  WidgetRef ref, {
  required OrderRecord order,
  required String reporterId,
}) async {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String category = 'general';

  final shouldSubmit = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Report issue for ${order.orderNumber}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(
                        value: 'general',
                        child: Text('General concern'),
                      ),
                      DropdownMenuItem(
                        value: 'payment',
                        child: Text('Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'delivery',
                        child: Text('Delivery'),
                      ),
                      DropdownMenuItem(
                        value: 'product_quality',
                        child: Text('Product quality'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 4,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Describe the issue',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );

  if (shouldSubmit == true) {
    await ref
        .read(disputesRepositoryProvider)
        .createDispute(
          orderId: order.id,
          reporterId: reporterId,
          category: category,
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
        );
    ref.invalidate(disputesProvider);
    if (context.mounted) {
      context.showSnackBar('Dispute submitted');
    }
  }

  titleController.dispose();
  descriptionController.dispose();
}
