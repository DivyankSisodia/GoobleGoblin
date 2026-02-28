import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  // TODO: Replace with your actual Supabase credentials
  static const String _supabaseUrl = 'https://ctmfmusvkymgtrbdedah.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN0bWZtdXN2a3ltZ3RyYmRlZGFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwNzA2OTYsImV4cCI6MjA4NjY0NjY5Nn0.nk6ZjV5Di6oYG9ih0KjDqjFhqOLqFxO4PB2jbBl3Yf4';

  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      _logger.i('Supabase initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize Supabase: $e');
      // App should still work offline even if Supabase init fails
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  /// Check if Supabase is properly configured (not placeholder values)
  static bool get isConfigured =>
      _supabaseUrl != 'YOUR_SUPABASE_URL' &&
      _supabaseAnonKey != 'YOUR_SUPABASE_ANON_KEY';

  /// Get the current user ID (for row-level security)
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;

  /// Table names
  static const String cardsTable = 'cards';
  static const String categoriesTable = 'categories';
  static const String paymentsTable = 'payments';
  static const String wishlistTable = 'wishlist';
  static const String appSettingsTable = 'app_settings';
}
