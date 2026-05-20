import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/admin_repository.dart';
import '../models/admin_user_record.dart';
import '../models/seller_verification_review.dart';

class AdminUsersPage extends ConsumerWidget {
  const AdminUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(adminUsersProvider);
    final verifications = ref.watch(adminVerificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminUsersProvider);
          ref.invalidate(adminVerificationsProvider);
          ref.invalidate(adminDashboardProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Verification queue',
              child: AsyncValueView(
                value: verifications,
                data: (items) {
                  if (items.isEmpty) {
                    return const Text('No verification records yet.');
                  }

                  return Column(
                    children: items
                        .map(
                          (item) => _VerificationTile(
                            item: item,
                            onReview: (status) async {
                              final notes = await _showNotesDialog(
                                context,
                                title:
                                    '${status[0].toUpperCase()}${status.substring(1)} verification',
                                helper:
                                    'Add optional notes for the seller or rider.',
                              );
                              if (!context.mounted) {
                                return;
                              }

                              await ref
                                  .read(adminRepositoryProvider)
                                  .reviewVerification(
                                    documentId: item.id,
                                    verificationStatus: status,
                                    reviewNotes: notes,
                                  );
                              ref.invalidate(adminVerificationsProvider);
                              ref.invalidate(adminUsersProvider);
                              ref.invalidate(adminDashboardProvider);
                              if (context.mounted) {
                                context.showSnackBar(
                                  'Verification updated to $status',
                                );
                              }
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'User accounts',
              child: AsyncValueView(
                value: users,
                data: (items) => Column(
                  children: items
                      .map(
                        (user) => _UserTile(
                          user: user,
                          onStatusChange: (status) async {
                            final notes = await _showNotesDialog(
                              context,
                              title:
                                  'Set ${user.fullName} to ${status.replaceAll('_', ' ')}',
                              helper:
                                  'Add optional notes to explain this account decision.',
                            );
                            if (!context.mounted) {
                              return;
                            }

                            await ref
                                .read(adminRepositoryProvider)
                                .updateUserStatus(
                                  userId: user.id,
                                  approvalStatus: status,
                                  reviewNotes: notes,
                                );
                            ref.invalidate(adminUsersProvider);
                            ref.invalidate(adminVerificationsProvider);
                            ref.invalidate(adminDashboardProvider);
                            if (context.mounted) {
                              context.showSnackBar(
                                'Account updated to $status',
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  const _VerificationTile({required this.item, required this.onReview});

  final SellerVerificationReview item;
  final Future<void> Function(String status) onReview;

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
                    item.sellerName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(item.verificationStatus)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${item.sellerRole} - ${item.sellerEmail}'),
            const SizedBox(height: 8),
            Text('Document: ${item.documentType.replaceAll('_', ' ')}'),
            Text('Submitted: ${AppFormatters.shortDate(item.createdAt)}'),
            if (item.screeningScore != null)
              Text('Veryfi screening score: ${item.screeningScore}'),
            Text('Screening status: ${item.screeningStatus}'),
            if (item.screeningNotes.isNotEmpty) Text(item.screeningNotes),
            const Divider(height: 24),
            Text(
              'Claimed name: ${item.claimedFullName.ifEmpty('Not provided')}',
            ),
            Text(
              'Extracted name: ${item.extractedFullName.ifEmpty('Not extracted')}',
            ),
            Text(
              'Claimed credential #: ${item.claimedCredentialNumber.ifEmpty('Not provided')}',
            ),
            Text(
              'Extracted credential #: ${item.extractedCredentialNumber.ifEmpty('Not extracted')}',
            ),
            const SizedBox(height: 8),
            Text(
              item.hasMatchSignals
                  ? 'Name fields match between seller input and OCR.'
                  : 'Review this credential closely. The OCR result does not fully match the submitted fields.',
            ),
            if (item.filePath.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText('Stored document path: ${item.filePath}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: () => onReview('approved'),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: () => onReview('rejected'),
                  child: const Text('Reject'),
                ),
                OutlinedButton(
                  onPressed: () => onReview('suspended'),
                  child: const Text('Suspend'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onStatusChange});

  final AdminUserRecord user;
  final Future<void> Function(String status) onStatusChange;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(user.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${user.role} - ${user.email}'),
            Text('Joined ${AppFormatters.shortDate(user.createdAt)}'),
            if (user.phone?.isNotEmpty ?? false) Text(user.phone!),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Chip(label: Text(user.approvalStatus)),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              onSelected: onStatusChange,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'approved', child: Text('Approve')),
                PopupMenuItem(value: 'rejected', child: Text('Reject')),
                PopupMenuItem(value: 'suspended', child: Text('Suspend')),
                PopupMenuItem(value: 'pending', child: Text('Mark pending')),
              ],
            ),
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

Future<String> _showNotesDialog(
  BuildContext context, {
  required String title,
  required String helper,
}) async {
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(helper),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Review notes'),
            ),
          ],
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
      );
    },
  );

  controller.dispose();
  return result ?? '';
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
