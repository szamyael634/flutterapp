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

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
    String? phone,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: AppEnv.redirectUrl,
      data: {'full_name': fullName, 'role': role.name, 'phone': phone},
    );

    final requiresVerification = response.session == null;
    if (requiresVerification) {
      await sendEmailVerificationCode(email: email);
    }

    return requiresVerification;
  }

  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    await _supabase.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
  }

  Future<void> resendSignUpCode({required String email}) async {
    await sendEmailVerificationCode(email: email);
  }

  Future<void> sendEmailVerificationCode({required String email}) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: AppEnv.redirectUrl,
      shouldCreateUser: false,
    );
  }

  Future<void> signOut() => _supabase.auth.signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});
