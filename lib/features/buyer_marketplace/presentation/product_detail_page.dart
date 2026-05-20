import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/build_context_x.dart';
import '../../../core/models/app_user.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/supabase.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../cart/data/cart_repository.dart';
import '../../profile/data/favorites_repository.dart';
import '../../reviews/data/reviews_repository.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final isFavorite = ref.watch(isFavoriteStoreProvider(product.storeId));
    final reviews = ref.watch(productReviewsProvider(product.id));

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
          if (profile?.role == AppRole.buyer && userId != null) ...[
            const SizedBox(height: 16),
            AsyncValueView(
              value: isFavorite,
              data: (favorite) => Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    if (favorite) {
                      await ref
                          .read(favoritesRepositoryProvider)
                          .removeFavorite(
                            buyerId: userId,
                            storeId: product.storeId,
                          );
                    } else {
                      await ref
                          .read(favoritesRepositoryProvider)
                          .saveFavorite(
                            buyerId: userId,
                            storeId: product.storeId,
                          );
                    }
                    ref.invalidate(isFavoriteStoreProvider(product.storeId));
                    ref.invalidate(favoriteStoresProvider);
                    if (context.mounted) {
                      context.showSnackBar(
                        favorite
                            ? 'Store removed from favorites'
                            : 'Store saved',
                      );
                    }
                  },
                  icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
                  label: Text(favorite ? 'Saved store' : 'Save store'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(AppFormatters.currency(product.currentPrice))),
              Chip(label: Text('Stock ${product.quantity}')),
              Chip(label: Text('Discount ${product.discountPercent}%')),
              Chip(
                label: Text(
                  'Expires ${AppFormatters.shortDate(product.expirationAt)}',
                ),
              ),
            ],
          ),
          if (product.allergens.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Allergens', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(product.allergens.join(', ')),
          ],
          const SizedBox(height: 24),
          Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AsyncValueView(
            value: reviews,
            data: (items) => items.isEmpty
                ? const Text('No reviews yet for this product.')
                : Column(
                    children: items
                        .map(
                          (review) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${review.rating} stars'),
                            subtitle: Text(
                              review.comment.isEmpty
                                  ? 'No comment provided.'
                                  : review.comment,
                            ),
                            trailing: Text(
                              AppFormatters.shortDate(review.createdAt),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
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
            child: const Text('Add to cart'),
          ),
        ],
      ),
    );
  }
}
