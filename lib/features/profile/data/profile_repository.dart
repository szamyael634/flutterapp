import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/app_user.dart';

class ProfileRepository {
  const ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<AppUser> fetchProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return AppUser.fromMap(data);
  }

  Future<void> ensureProfile({
    required String userId,
    required String email,
    required String fullName,
    required AppRole role,
    String? phone,
  }) {
    return _supabase.from('profiles').upsert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': role.name,
      'phone': phone,
    });
  }

  Future<void> updateProfile({
    required String userId,
    required String fullName,
    required String? phone,
  }) {
    return _supabase.from('profiles').update({
      'full_name': fullName,
      'phone': phone,
    }).eq('id', userId);
  }
}
