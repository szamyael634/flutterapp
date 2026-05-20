import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/product.dart';
import '../../../core/providers/supabase.dart';

class MarketplaceRepository {
  const MarketplaceRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Product>> fetchMarketplaceProducts() async {
    final rows = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .inFilter('listing_status', ['active', 'near_expiry', 'flash_sale'])
        .order('expiration_at');

    return rows
        .map<Product>((row) => Product.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<Product>> fetchDiscountDeals() async {
    final rows = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .gt('discount_percent', 0)
        .inFilter('listing_status', ['near_expiry', 'flash_sale'])
        .order('discount_percent', ascending: false);

    return rows
        .map<Product>((row) => Product.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Product> fetchProduct(String productId) async {
    final row = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .eq('id', productId)
        .single();

    return Product.fromMap(row);
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository(ref.watch(supabaseClientProvider));
});

final marketplaceProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(marketplaceRepositoryProvider).fetchMarketplaceProducts();
});

final discountDealsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(marketplaceRepositoryProvider).fetchDiscountDeals();
});
