import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/delivery.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/delivery_repository.dart';

enum DeliveryMode { available, assigned }

class DeliveryPage extends ConsumerWidget {
  const DeliveryPage({super.key, required this.mode});

  final DeliveryMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riderId = ref.watch(currentUserIdProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final future = switch (mode) {
      DeliveryMode.available => ref.watch(_availableDeliveriesProvider),
      DeliveryMode.assigned => ref.watch(
        _assignedDeliveriesProvider(riderId ?? ''),
      ),
    };

    if (!(profile?.canDeliver ?? false)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            mode == DeliveryMode.available
                ? 'Delivery requests'
                : 'Assigned deliveries',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              profile?.isAdmin ?? false
                  ? 'Admin accounts can monitor the system but cannot claim or update deliveries.'
                  : 'Only approved rider accounts can access delivery handling.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          mode == DeliveryMode.available
              ? 'Delivery requests'
              : 'Assigned deliveries',
        ),
      ),
      body: AsyncValueView(
        value: future,
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final delivery = items[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  title: Text('Order ${delivery.orderId.substring(0, 8)}'),
                  subtitle: Text(
                    '${delivery.pickupAddress}\n${delivery.dropoffAddress}',
                  ),
                  trailing: mode == DeliveryMode.available
                      ? FilledButton(
                          onPressed: riderId == null
                              ? null
                              : () async {
                                  await ref
                                      .read(deliveryRepositoryProvider)
                                      .claimDelivery(
                                        deliveryId: delivery.id,
                                        riderId: riderId,
                                      );
                                  ref.invalidate(_availableDeliveriesProvider);
                                  ref.invalidate(
                                    _assignedDeliveriesProvider(riderId),
                                  );
                                },
                          child: const Text('Claim'),
                        )
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            await ref
                                .read(deliveryRepositoryProvider)
                                .updateStatus(
                                  deliveryId: delivery.id,
                                  status: value,
                                );
                            ref.invalidate(
                              _assignedDeliveriesProvider(riderId ?? ''),
                            );
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'picked_up',
                              child: Text('Picked up'),
                            ),
                            PopupMenuItem(
                              value: 'near_dropoff',
                              child: Text('Near dropoff'),
                            ),
                            PopupMenuItem(
                              value: 'completed',
                              child: Text('Completed'),
                            ),
                          ],
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final _availableDeliveriesProvider = FutureProvider<List<DeliveryRecord>>((
  ref,
) {
  return ref.watch(deliveryRepositoryProvider).fetchAvailableDeliveries();
});

final _assignedDeliveriesProvider =
    FutureProvider.family<List<DeliveryRecord>, String>((ref, riderId) {
      if (riderId.isEmpty) {
        return Future.value([]);
      }
      return ref
          .watch(deliveryRepositoryProvider)
          .fetchAssignedDeliveries(riderId);
    });
