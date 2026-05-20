import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/cart_item.dart';
import '../../../core/models/product.dart';
import '../../../core/providers/supabase.dart';

class CartRepository {
  const CartRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<CartItem>> fetchCart(String userId) async {
    final rows = await _supabase
        .from('cart_items')
        .select('id, quantity, products(*, product_images(image_url))')
        .eq('buyer_id', userId)
        .order('created_at');

    return rows
        .map<CartItem>((row) => CartItem.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addToCart({
    required String buyerId,
    required Product product,
  }) async {
    final existing = await _supabase
        .from('cart_items')
        .select()
        .eq('buyer_id', buyerId)
        .eq('product_id', product.id)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('cart_items').insert({
        'buyer_id': buyerId,
        'product_id': product.id,
        'quantity': 1,
      });
      return;
    }

    final quantity = (existing['quantity'] as int? ?? 1) + 1;
    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', existing['id']);
  }

  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await remove(cartItemId);
      return;
    }

    await _supabase
        .from('cart_items')
        .update({'quantity': quantity})
        .eq('id', cartItemId);
  }

  Future<void> remove(String cartItemId) {
    return _supabase.from('cart_items').delete().eq('id', cartItemId);
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.watch(supabaseClientProvider));
});

final cartProvider = FutureProvider<List<CartItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  return ref.watch(cartRepositoryProvider).fetchCart(userId);
});
