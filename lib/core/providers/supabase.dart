import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import '../models/app_user.dart';
import '../../features/profile/data/profile_repository.dart';

Future<void> initializeSupabase() async {
  await Supabase.initialize(
    url: AppEnv.supabaseUrl,
    anonKey: AppEnv.supabasePublishableKey,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
}

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final authStateProvider = StreamProvider<Session?>((ref) {
  final client = ref.watch(supabaseClientProvider);

  final controller = StreamController<Session?>();
  controller.add(client.auth.currentSession);

  final subscription = client.auth.onAuthStateChange.listen((data) {
    controller.add(data.session);
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(authStateProvider).valueOrNull;
  return session?.user.id;
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final currentUserProfileProvider = FutureProvider<AppUser>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw StateError('No active user session');
  }

  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchProfile(userId);
});
