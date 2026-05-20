import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/product.dart';
import '../../../core/models/product_recommendation.dart';
import '../../../core/models/store_profile.dart';
import '../../../core/providers/supabase.dart';

class SellerRepository {
  const SellerRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<StoreProfile?> fetchStore(String ownerId) async {
    final row = await _supabase
        .from('stores')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return StoreProfile.fromMap(row);
  }

  Future<List<Product>> fetchSellerProducts(String ownerId) async {
    final store = await fetchStore(ownerId);
    if (store == null) {
      return [];
    }

    final rows = await _supabase
        .from('products')
        .select('*, product_images(image_url)')
        .eq('store_id', store.id)
        .order('expiration_at');

    return rows
        .map<Product>((row) => Product.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<ProductRecommendation>> fetchRecommendations(
    String ownerId,
  ) async {
    final store = await fetchStore(ownerId);
    if (store == null) {
      return [];
    }

    final rows = await _supabase
        .from('product_recommendations')
        .select('*, products!inner(store_id)')
        .eq('products.store_id', store.id)
        .order('created_at', ascending: false);

    return rows
        .map<ProductRecommendation>(
          (row) =>
              ProductRecommendation.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> upsertStore({
    required String ownerId,
    required String name,
    required String description,
    required String address,
  }) async {
    await _supabase.from('stores').upsert({
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'is_open': true,
    });
  }

  Future<Map<String, dynamic>> submitVerification({
    required String ownerId,
    required String documentType,
    required String claimedFullName,
    required String claimedCredentialNumber,
    required PlatformFile file,
  }) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('Selected file bytes are not available.');
    }

    final path =
        '$ownerId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    await _supabase.storage
        .from('verification-documents')
        .uploadBinary(path, bytes);

    final response = await _supabase.functions.invoke(
      'screen-verification-credentials',
      body: {
        'file_path': path,
        'document_type': documentType,
        'claimed_full_name': claimedFullName,
        'claimed_credential_number': claimedCredentialNumber,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> createProduct({
    required String ownerId,
    required String name,
    required String description,
    required String category,
    required double originalPrice,
    required int quantity,
    required DateTime preparedAt,
    required DateTime expirationAt,
    required List<String> allergens,
    PlatformFile? image,
  }) async {
    final store = await fetchStore(ownerId);
    if (store == null) {
      throw StateError('Create a store profile before adding products.');
    }

    final inserted = await _supabase
        .from('products')
        .insert({
          'store_id': store.id,
          'name': name,
          'description': description,
          'category': category,
          'original_price': originalPrice,
          'current_price': originalPrice,
          'quantity': quantity,
          'prepared_at': preparedAt.toIso8601String(),
          'expiration_at': expirationAt.toIso8601String(),
          'discount_percent': 0,
          'listing_status': 'active',
          'allergens': allergens,
        })
        .select()
        .single();

    if (image != null) {
      final imageUrl = await _uploadProductImage(
        inserted['id'] as String,
        image,
      );
      await _supabase.from('product_images').insert({
        'product_id': inserted['id'],
        'image_url': imageUrl,
        'is_primary': true,
      });
    }

    await _supabase.rpc(
      'sync_product_recommendation',
      params: {'p_product_id': inserted['id']},
    );
  }

  Future<void> acceptRecommendation({required String recommendationId}) {
    return _supabase.functions.invoke(
      'refresh-product-recommendations',
      body: {'recommendation_id': recommendationId, 'action': 'accept'},
    );
  }

  Future<String> _uploadProductImage(
    String productId,
    PlatformFile file,
  ) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('Selected file bytes are not available.');
    }

    final path =
        '$productId/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    await _supabase.storage.from('product-images').uploadBinary(path, bytes);
    return _supabase.storage.from('product-images').getPublicUrl(path);
  }
}

final sellerRepositoryProvider = Provider<SellerRepository>((ref) {
  return SellerRepository(ref.watch(supabaseClientProvider));
});
