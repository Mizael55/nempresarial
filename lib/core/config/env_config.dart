import 'package:flutter/foundation.dart';

/// Environment and global application configuration for NUBIKO
class EnvConfig {
  EnvConfig._();

  static const String appName = 'NUBIKO';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Sistema Empresarial Inteligente';

  /// Supabase Configuration.
  /// Note: In production or client installations, these can be injected via
  /// --dart-define or loaded from a secure client config file.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nspyjpnlqpqexpnmhxgc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5zcHlqcG5scXBxZXhwbm1oeGdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyOTI1MzgsImV4cCI6MjEwNjg2ODUzOH0.huQTJSXdKoN4UKqjZS4-jNzWOEfTUOR_d2Hn7uHHhL0',
  );

  /// Check whether Supabase is configured with valid live credentials
  static bool get isSupabaseConfigured =>
      !supabaseUrl.contains('placeholder') &&
      !supabaseAnonKey.contains('placeholder');

  /// Enable mock fallback data when running without live Supabase connection
  /// to ensure the UI and demo flows operate flawlessly.
  static bool get enableMockFallback => !isSupabaseConfigured || kDebugMode;
}
