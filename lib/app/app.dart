import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_env.dart';
import '../core/extensions/build_context_x.dart';
import '../core/providers/supabase.dart';
import '../core/widgets/async_value_view.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_shell.dart';
import 'theme.dart';

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mama\'s Kitchen',
      theme: buildAppTheme(),
      home: const AppBootstrap(),
    );
  }
}

class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppEnv.hasSupabaseConfig) {
      return const _MissingConfigurationPage();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (session) {
        if (session?.user == null) {
          return const LoginPage();
        }

        final profile = ref.watch(currentUserProfileProvider);
        return AsyncValueView(
          value: profile,
          data: (user) => HomeShell(user: user),
        );
      },
      loading: () => const _SplashScreen(),
      error: (error, stackTrace) => _AppErrorScreen(error: error),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AppErrorScreen extends StatelessWidget {
  const _AppErrorScreen({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load Mama\'s Kitchen',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MissingConfigurationPage extends StatelessWidget {
  const _MissingConfigurationPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supabase setup required',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Run the app with Dart defines for the Supabase URL and publishable key. '
                      'This keeps secrets out of the repo and lets the same build target multiple environments.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const SelectableText(
                        'flutter run '
                        '--dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co '
                        '--dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx '
                        '--dart-define=APP_SCHEME=mamaskitchen '
                        '--dart-define=APP_HOST=login-callback',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current URL: ${AppEnv.supabaseUrl.isEmpty ? 'not set' : AppEnv.supabaseUrl}',
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => context.showSnackBar(
                        'Add the required Dart defines, then restart the app.',
                      ),
                      child: const Text('How to configure'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
