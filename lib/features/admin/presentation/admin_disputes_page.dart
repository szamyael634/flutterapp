import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/admin_repository.dart';
import '../models/admin_dispute_record.dart';

class AdminDisputesPage extends ConsumerWidget {
  const AdminDisputesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disputes = ref.watch(adminDisputesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Disputes')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDisputesProvider);
          ref.invalidate(adminDashboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueView(
              value: disputes,
              data: (items) => items.isEmpty
                  ? const Text('No disputes reported yet.')
                  : Column(
                      children: items
                          .map(
                            (item) => _DisputeTile(
                              dispute: item,
                              onUpdate: (status) async {
                                final notes = await _showResolutionDialog(
                                  context,
                                  status,
                                );
                                if (!context.mounted) {
                                  return;
                                }
                                await ref
                                    .read(adminRepositoryProvider)
                                    .updateDisputeStatus(
                                      disputeId: item.id,
                                      status: status,
                                      resolutionNotes: notes,
                                    );
                                ref.invalidate(adminDisputesProvider);
                                if (context.mounted) {
                                  context.showSnackBar(
                                    'Dispute updated to $status',
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeTile extends StatelessWidget {
  const _DisputeTile({required this.dispute, required this.onUpdate});

  final AdminDisputeRecord dispute;
  final Future<void> Function(String status) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dispute.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(dispute.status)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${dispute.orderNumber} - ${dispute.category}'),
            if (dispute.reporterEmail.isNotEmpty) Text(dispute.reporterEmail),
            Text(AppFormatters.shortDate(dispute.createdAt)),
            const SizedBox(height: 8),
            Text(dispute.description),
            if ((dispute.resolutionNotes ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Resolution: ${dispute.resolutionNotes}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onUpdate('reviewing'),
                  child: const Text('Mark reviewing'),
                ),
                FilledButton(
                  onPressed: () => onUpdate('resolved'),
                  child: const Text('Resolve'),
                ),
                OutlinedButton(
                  onPressed: () => onUpdate('rejected'),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> _showResolutionDialog(
  BuildContext context,
  String status,
) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Update dispute to $status'),
      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(labelText: 'Resolution notes'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(''),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result ?? '';
}
