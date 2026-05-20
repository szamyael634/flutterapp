import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/dispute_record.dart';
import '../../../core/providers/supabase.dart';

class DisputesRepository {
  const DisputesRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<DisputeRecord>> fetchDisputes(String reporterId) async {
    final rows = await _supabase
        .from('disputes')
        .select()
        .eq('reporter_id', reporterId)
        .order('created_at', ascending: false);

    return rows
        .map<DisputeRecord>(
          (row) => DisputeRecord.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> createDispute({
    required String orderId,
    required String reporterId,
    required String category,
    required String title,
    required String description,
  }) {
    return _supabase.from('disputes').insert({
      'order_id': orderId,
      'reporter_id': reporterId,
      'category': category,
      'title': title,
      'description': description,
    });
  }
}

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  return DisputesRepository(ref.watch(supabaseClientProvider));
});

final disputesProvider = FutureProvider<List<DisputeRecord>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }
  return ref.watch(disputesRepositoryProvider).fetchDisputes(userId);
});
