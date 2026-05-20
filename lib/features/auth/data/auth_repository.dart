import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../core/models/app_user.dart';
import '../../../core/providers/supabase.dart';

class AuthRepository {
  const AuthRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<void> signIn({required String email, required String password}) {
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
    String? phone,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppEnv.redirectUrl,
      data: {'full_name': fullName, 'role': role.name, 'phone': phone},
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
