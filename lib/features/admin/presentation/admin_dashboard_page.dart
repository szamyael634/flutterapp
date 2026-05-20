import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/admin_repository.dart';
import '../models/admin_dashboard_data.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueView(
              value: dashboard,
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(
                        label: 'Total users',
                        value: '${data.metrics.totalUsers}',
                      ),
                      _MetricCard(
                        label: 'Active sellers',
                        value: '${data.metrics.activeSellers}',
                      ),
                      _MetricCard(
                        label: 'Completed deliveries',
                        value: '${data.metrics.completedDeliveries}',
                      ),
                      _MetricCard(
                        label: 'Total stores',
                        value: '${data.metrics.totalStores}',
                      ),
                      _MetricCard(
                        label: 'Delivered sales',
                        value: AppFormatters.currency(data.metrics.totalSales),
                      ),
                      _MetricCard(
                        label: 'Pending approvals',
                        value: '${data.metrics.pendingApprovals}',
                      ),
                      _MetricCard(
                        label: 'Reduced commission orders',
                        value: '${data.metrics.reducedCommissionOrders}',
                      ),
                      _MetricCard(
                        label: 'Pending verifications',
                        value: '${data.metrics.pendingVerifications}',
                      ),
                      _MetricCard(
                        label: 'Open disputes',
                        value: '${data.metrics.openDisputes}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InsightCard(metrics: data.metrics),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Recent delivered orders',
                    child: data.recentOrders.isEmpty
                        ? const Text('No delivered orders yet.')
                        : Column(
                            children: data.recentOrders
                                .map((order) => _RecentOrderTile(order: order))
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.metrics});

  final AdminDashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sustainability snapshot',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${metrics.estimatedFoodSaved} reduced-commission orders have contributed to the current food-saving estimate.',
            ),
            const SizedBox(height: 8),
            Text(
              'Reduced commission value: ${AppFormatters.currency(metrics.reducedCommissionValue)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final AdminRecentOrder order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(order.orderNumber),
      subtitle: Text(
        '${order.status} - ${order.paymentMethod.toUpperCase()} - ${AppFormatters.shortDate(order.createdAt)}',
      ),
      trailing: Text(AppFormatters.currency(order.totalAmount)),
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
