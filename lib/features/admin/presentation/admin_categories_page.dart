import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/product_category.dart';
import '../../../core/providers/catalog.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/admin_repository.dart';

class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            onPressed: () async {
              await _showCategoryEditor(context, ref);
            },
            icon: const Icon(Icons.add),
            tooltip: 'Add category',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminCategoriesProvider);
          ref.invalidate(publicCategoriesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Product categories',
              child: AsyncValueView(
                value: categories,
                data: (items) => Column(
                  children: items
                      .map(
                        (category) => _CategoryTile(
                          category: category,
                          onEdit: () => _showCategoryEditor(
                            context,
                            ref,
                            category: category,
                          ),
                          onToggle: () async {
                            await ref
                                .read(adminRepositoryProvider)
                                .toggleCategory(
                                  id: category.id,
                                  isActive: !category.isActive,
                                );
                            ref.invalidate(adminCategoriesProvider);
                            ref.invalidate(publicCategoriesProvider);
                            if (context.mounted) {
                              context.showSnackBar(
                                category.isActive
                                    ? 'Category archived'
                                    : 'Category activated',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add category'),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onToggle,
  });

  final ProductCategory category;
  final Future<void> Function() onEdit;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(category.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              category.description.isEmpty
                  ? 'No description provided.'
                  : category.description,
            ),
            const SizedBox(height: 4),
            Text('Slug: ${category.slug} - Sort order: ${category.sortOrder}'),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: category.isActive, onChanged: (_) => onToggle()),
            TextButton(onPressed: onEdit, child: const Text('Edit')),
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

Future<void> _showCategoryEditor(
  BuildContext context,
  WidgetRef ref, {
  ProductCategory? category,
}) async {
  final nameController = TextEditingController(text: category?.name ?? '');
  final descriptionController = TextEditingController(
    text: category?.description ?? '',
  );
  final sortOrderController = TextEditingController(
    text: '${category?.sortOrder ?? 0}',
  );
  var isActive = category?.isActive ?? true;

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(category == null ? 'Add category' : 'Edit category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sortOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Sort order'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: isActive,
                    title: const Text('Active'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => isActive = value),
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
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );

  if (shouldSave == true) {
    await ref
        .read(adminRepositoryProvider)
        .saveCategory(
          id: category?.id,
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          isActive: isActive,
          sortOrder: int.tryParse(sortOrderController.text.trim()) ?? 0,
        );
    ref.invalidate(adminCategoriesProvider);
    ref.invalidate(publicCategoriesProvider);
    ref.invalidate(adminDashboardProvider);
    if (context.mounted) {
      context.showSnackBar(
        category == null ? 'Category created' : 'Category updated',
      );
    }
  }

  nameController.dispose();
  descriptionController.dispose();
  sortOrderController.dispose();
}
