import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/data/cart_repository.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              product.category,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(AppFormatters.currency(product.currentPrice))),
              Chip(label: Text('Stock ${product.quantity}')),
              Chip(label: Text('Discount ${product.discountPercent}%')),
              Chip(label: Text('Expires ${AppFormatters.shortDate(product.expirationAt)}')),
            ],
          ),
          if (product.allergens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Allergens', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(product.allergens.join(', ')),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              final userId = ref.read(currentUserIdProvider);
              if (userId == null) {
                context.showSnackBar('Please log in first.', isError: true);
                return;
              }
              await ref.read(cartRepositoryProvider).addToCart(
                    buyerId: userId,
                    product: product,
                  );
              ref.invalidate(cartProvider);
              if (context.mounted) {
                context.showSnackBar('${product.name} added to cart');
              }
            },
            child: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
