import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  SupabaseClientHelper._();

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => currentUser?.id;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => auth.onAuthStateChange;
}
