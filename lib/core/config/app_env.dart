class AppEnv {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'mamaskitchen',
  );
  static const appHost = String.fromEnvironment(
    'APP_HOST',
    defaultValue: 'login-callback',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  static String get redirectUrl => '$appScheme://$appHost';
}
