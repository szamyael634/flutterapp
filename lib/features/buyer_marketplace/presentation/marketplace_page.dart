import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../cart/data/cart_repository.dart';
import '../data/marketplace_repository.dart';
import 'product_detail_page.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(marketplaceProductsProvider);
    final deals = ref.watch(discountDealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Save Food Deals')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketplaceProductsProvider);
          ref.invalidate(discountDealsProvider);
          await Future.wait([
            ref.read(marketplaceProductsProvider.future),
            ref.read(discountDealsProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Near-expiry meals with a purpose',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Every discounted order helps local kitchens recover revenue while reducing food waste.',
            ),
            const SizedBox(height: 20),
            Text(
              'Featured deals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 188,
              child: AsyncValueView(
                value: deals,
                data: (items) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final product = items[index];
                    return SizedBox(
                      width: 280,
                      child: _DealCard(product: product),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Marketplace', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            AsyncValueView(
              value: products,
              data: (items) => Column(
                children: items
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ProductCard(product: product),
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

class _DealCard extends StatelessWidget {
  const _DealCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(label: Text('${product.discountPercent}% off')),
              const Spacer(),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(AppFormatters.currency(product.currentPrice)),
              const SizedBox(height: 8),
              Text('Expires ${AppFormatters.shortDate(product.expirationAt)}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(product.description),
            const SizedBox(height: 8),
            Text(
              '${AppFormatters.currency(product.currentPrice)} - ${product.category}',
            ),
            const SizedBox(height: 8),
            Text('Expires ${AppFormatters.shortDate(product.expirationAt)}'),
          ],
        ),
        trailing: FilledButton(
          onPressed: () async {
            final userId = ref.read(currentUserIdProvider);
            if (userId == null) {
              context.showSnackBar('Please log in first.', isError: true);
              return;
            }
            await ref
                .read(cartRepositoryProvider)
                .addToCart(buyerId: userId, product: product);
            ref.invalidate(cartProvider);
            if (context.mounted) {
              context.showSnackBar('${product.name} added to cart');
            }
          },
          child: const Text('Add'),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailPage(product: product),
            ),
          );
        },
      ),
    );
  }
}
