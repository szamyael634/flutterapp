import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user.dart';
import '../data/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signIn(email: email, password: password),
    );
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required AppRole role,
    String? phone,
  }) async {
    state = const AsyncLoading();
    var requiresVerification = false;
    state = await AsyncValue.guard(() async {
      requiresVerification = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: role,
        phone: phone,
      );
    });
    return requiresVerification;
  }

  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.verifySignUpCode(email: email, code: code),
    );
  }

  Future<void> resendSignUpCode({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.resendSignUpCode(email: email),
    );
  }
}
