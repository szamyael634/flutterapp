import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/favorite_store.dart';
import '../../../core/providers/supabase.dart';

class FavoritesRepository {
  const FavoritesRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<FavoriteStore>> fetchFavorites(String buyerId) async {
    final rows = await _supabase
        .from('favorite_stores')
        .select('*, stores(name, description, address)')
        .eq('buyer_id', buyerId)
        .order('created_at', ascending: false);

    return rows
        .map<FavoriteStore>(
          (row) => FavoriteStore.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<bool> isFavorite({
    required String buyerId,
    required String storeId,
  }) async {
    final row = await _supabase
        .from('favorite_stores')
        .select('id')
        .eq('buyer_id', buyerId)
        .eq('store_id', storeId)
        .maybeSingle();
    return row != null;
  }

  Future<void> saveFavorite({
    required String buyerId,
    required String storeId,
  }) {
    return _supabase.from('favorite_stores').insert({
      'buyer_id': buyerId,
      'store_id': storeId,
    });
  }

  Future<void> removeFavorite({
    required String buyerId,
    required String storeId,
  }) {
    return _supabase
        .from('favorite_stores')
        .delete()
        .eq('buyer_id', buyerId)
        .eq('store_id', storeId);
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(supabaseClientProvider));
});

final favoriteStoresProvider = FutureProvider<List<FavoriteStore>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }
  return ref.watch(favoritesRepositoryProvider).fetchFavorites(userId);
});

final isFavoriteStoreProvider = FutureProvider.family<bool, String>((
  ref,
  storeId,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return false;
  }
  return ref
      .watch(favoritesRepositoryProvider)
      .isFavorite(buyerId: userId, storeId: storeId);
});
