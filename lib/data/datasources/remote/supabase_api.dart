import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApi {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // --- Authentication ---

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: data, // For additional user metadata like name, phone
      );
      return response;
    } catch (e) {
      // Consider more specific error handling
      throw Exception('Signup failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Signin failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Signout failed: ${e.toString()}');
    }
  }

  // --- Add other API methods for Taxi, Excursions etc. later ---
}