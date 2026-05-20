import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/review_entry.dart';
import '../../../core/providers/supabase.dart';

class ReviewsRepository {
  const ReviewsRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<ReviewEntry>> fetchReviewsForTarget({
    required String targetType,
    required String targetId,
  }) async {
    final rows = await _supabase
        .from('reviews')
        .select()
        .eq('target_type', targetType)
        .eq('target_id', targetId)
        .order('created_at', ascending: false);

    return rows
        .map<ReviewEntry>(
          (row) => ReviewEntry.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> submitReview({
    required String orderId,
    required String authorId,
    required String targetType,
    required String targetId,
    required int rating,
    required String comment,
  }) {
    return _supabase.from('reviews').insert({
      'order_id': orderId,
      'author_id': authorId,
      'target_type': targetType,
      'target_id': targetId,
      'rating': rating,
      'comment': comment,
      'photo_urls': <String>[],
    });
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(ref.watch(supabaseClientProvider));
});

final productReviewsProvider = FutureProvider.family<List<ReviewEntry>, String>(
  (ref, productId) {
    return ref
        .watch(reviewsRepositoryProvider)
        .fetchReviewsForTarget(targetType: 'product', targetId: productId);
  },
);
