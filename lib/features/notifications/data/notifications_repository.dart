import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/supabase.dart';

class NotificationsRepository {
  const NotificationsRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<AppNotification>> fetchNotifications(String userId) async {
    final rows = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return rows
        .map<AppNotification>(
          (row) => AppNotification.fromMap(Map<String, dynamic>.from(row)),
        )
        .toList();
  }

  Future<void> markRead(String notificationId) {
    return _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }
}

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(supabaseClientProvider));
});

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    return [];
  }

  return ref.watch(notificationsRepositoryProvider).fetchNotifications(userId);
});
