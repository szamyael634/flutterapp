import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/product.dart';
import '../../../core/models/product_recommendation.dart';
import '../../../core/models/store_profile.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../data/seller_repository.dart';

final sellerStoreProvider = FutureProvider<StoreProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return null;
  }
  return ref.watch(sellerRepositoryProvider).fetchStore(userId);
});

final sellerProductsProvider = FutureProvider<List<Product>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }
  return ref.watch(sellerRepositoryProvider).fetchSellerProducts(userId);
});

final sellerRecommendationsProvider =
    FutureProvider<List<ProductRecommendation>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }
  return ref.watch(sellerRepositoryProvider).fetchRecommendations(userId);
});

class SellerDashboardPage extends ConsumerStatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  ConsumerState<SellerDashboardPage> createState() =>
      _SellerDashboardPageState();
}

class _SellerDashboardPageState extends ConsumerState<SellerDashboardPage> {
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _allergensController = TextEditingController();
  final _verificationNameController = TextEditingController();
  final _verificationNumberController = TextEditingController();
  String _category = 'Meals';
  String _verificationDocumentType = 'government_id';
  DateTime _preparedAt = DateTime.now();
  DateTime _expirationAt = DateTime.now().add(const Duration(days: 2));
  PlatformFile? _verificationFile;
  PlatformFile? _productImage;

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _storeAddressController.dispose();
    _productNameController.dispose();
    _productDescriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _allergensController.dispose();
    _verificationNameController.dispose();
    _verificationNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final store = ref.watch(sellerStoreProvider);
    final products = ref.watch(sellerProductsProvider);
    final recommendations = ref.watch(sellerRecommendationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seller Center')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sellerStoreProvider);
          ref.invalidate(sellerProductsProvider);
          ref.invalidate(sellerRecommendationsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionCard(
              title: 'Store profile',
              child: Column(
                children: [
                  TextField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(labelText: 'Store name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeAddressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  AsyncValueView(
                    value: store,
                    data: (storeValue) {
                      if (storeValue != null) {
                        _storeNameController.text = storeValue.name;
                        _storeDescriptionController.text = storeValue.description;
                        _storeAddressController.text = storeValue.address;
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: () async {
                            await ref.read(sellerRepositoryProvider).upsertStore(
                                  ownerId: userId,
                                  name: _storeNameController.text.trim(),
                                  description:
                                      _storeDescriptionController.text.trim(),
                                  address: _storeAddressController.text.trim(),
                                );
                            ref.invalidate(sellerStoreProvider);
                            if (context.mounted) {
                              context.showSnackBar('Store profile saved');
                            }
                          },
                          child: const Text('Save store'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Verification documents',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _verificationDocumentType,
                    decoration: const InputDecoration(
                      labelText: 'Credential type',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'government_id',
                        child: Text('Government ID'),
                      ),
                      DropdownMenuItem(
                        value: 'business_permit',
                        child: Text('Business Permit'),
                      ),
                      DropdownMenuItem(
                        value: 'food_safety_certificate',
                        child: Text('Food Safety Certificate'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _verificationDocumentType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _verificationNameController,
                    decoration: const InputDecoration(
                      labelText: 'Credential holder name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _verificationNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Credential number / reference',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() => _verificationFile = result.files.first);
                      }
                    },
                    child: Text(
                      _verificationFile == null
                          ? 'Choose document'
                          : _verificationFile!.name,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _verificationFile == null
                        ? null
                        : () async {
                            final screening = await ref
                                .read(sellerRepositoryProvider)
                                .submitVerification(
                                  ownerId: userId,
                                  documentType: _verificationDocumentType,
                                  claimedFullName:
                                      _verificationNameController.text.trim(),
                                  claimedCredentialNumber:
                                      _verificationNumberController.text.trim(),
                                  file: _verificationFile!,
                                );
                            if (context.mounted) {
                              final status =
                                  screening['screening_status']?.toString() ??
                                      'pending';
                              final notes =
                                  screening['screening_notes']?.toString() ??
                                      'Verification submitted';
                              context.showSnackBar(
                                'Screening: $status. $notes',
                              );
                            }
                          },
                    child: const Text('Submit verification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Add product',
              child: Column(
                children: [
                  TextField(
                    controller: _productNameController,
                    decoration:
                        const InputDecoration(labelText: 'Product name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _productDescriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      'Bento Boxes',
                      'Meals',
                      'Snacks',
                      'Desserts',
                      'Drinks',
                      'Bakery Items',
                      'Frozen Foods',
                      'Ready-to-Eat Foods',
                    ]
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    decoration:
                        const InputDecoration(labelText: 'Original price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _allergensController,
                    decoration: const InputDecoration(
                      labelText: 'Allergens (comma separated)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _preparedAt,
                            firstDate:
                                DateTime.now().subtract(const Duration(days: 7)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _preparedAt = picked);
                          }
                        },
                        child: Text(
                          'Prepared ${_preparedAt.toLocal().toString().split(' ').first}',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expirationAt,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 30)),
                          );
                          if (picked != null) {
                            setState(() => _expirationAt = picked);
                          }
                        },
                        child: Text(
                          'Expires ${_expirationAt.toLocal().toString().split(' ').first}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        withData: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        setState(() => _productImage = result.files.first);
                      }
                    },
                    child: Text(
                      _productImage == null
                          ? 'Choose image'
                          : _productImage!.name,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await ref.read(sellerRepositoryProvider).createProduct(
                            ownerId: userId,
                            name: _productNameController.text.trim(),
                            description:
                                _productDescriptionController.text.trim(),
                            category: _category,
                            originalPrice:
                                double.tryParse(_priceController.text) ?? 0,
                            quantity:
                                int.tryParse(_quantityController.text) ?? 1,
                            preparedAt: _preparedAt,
                            expirationAt: _expirationAt,
                            allergens: _allergensController.text
                                .split(',')
                                .map((item) => item.trim())
                                .where((item) => item.isNotEmpty)
                                .toList(),
                            image: _productImage,
                          );
                      ref.invalidate(sellerProductsProvider);
                      if (context.mounted) {
                        context.showSnackBar('Product created');
                      }
                    },
                    child: const Text('Add product'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Recommendations',
              child: AsyncValueView(
                value: recommendations,
                data: (items) => Column(
                  children: items
                      .map((item) => _RecommendationTile(item: item))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Inventory',
              child: AsyncValueView(
                value: products,
                data: (items) => Column(
                  children: items
                      .map((product) => _InventoryTile(product: product))
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

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

class _RecommendationTile extends ConsumerWidget {
  const _RecommendationTile({required this.item});

  final ProductRecommendation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.message),
      subtitle: Text('${item.suggestedDiscountPercent}% suggested discount'),
      trailing: FilledButton.tonal(
        onPressed: () async {
          await ref.read(sellerRepositoryProvider).acceptRecommendation(
                recommendationId: item.id,
              );
          ref.invalidate(sellerRecommendationsProvider);
          ref.invalidate(sellerProductsProvider);
        },
        child: const Text('Apply'),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(product.name),
      subtitle: Text(
        '${AppFormatters.currency(product.currentPrice)} * ${product.listingStatus.name}',
      ),
      trailing: Text('Qty ${product.quantity}'),
    );
  }
}
