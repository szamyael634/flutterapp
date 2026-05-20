import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/delivery.dart';
import '../../../core/providers/supabase.dart';

class DeliveryRepository {
  const DeliveryRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<DeliveryRecord>> fetchAvailableDeliveries() async {
    final rows = await _supabase
        .from('deliveries')
        .select()
        .eq('status', 'unassigned')
        .order('created_at');

    return rows
        .map<DeliveryRecord>(
          (row) => DeliveryRecord.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<List<DeliveryRecord>> fetchAssignedDeliveries(String riderId) async {
    final rows = await _supabase
        .from('deliveries')
        .select()
        .eq('rider_id', riderId)
        .order('created_at');

    return rows
        .map<DeliveryRecord>(
          (row) => DeliveryRecord.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> claimDelivery({
    required String deliveryId,
    required String riderId,
  }) {
    return _supabase.from('deliveries').update({
      'rider_id': riderId,
      'status': 'assigned',
    }).eq('id', deliveryId);
  }

  Future<void> updateStatus({
    required String deliveryId,
    required String status,
  }) {
    return _supabase
        .from('deliveries')
        .update({'status': status})
        .eq('id', deliveryId);
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.watch(supabaseClientProvider));
});
