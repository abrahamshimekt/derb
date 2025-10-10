import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../../core/failures.dart';

abstract class IAuthRepository {
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required role,
  });
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> resetPassword(String newPassword);
  Session? get session;
  Stream<AuthState> onAuthStateChange();
}

class SupabaseAuthRepository implements IAuthRepository {
  final _client = AppSupabase.client;

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required role,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone_number': phoneNumber,
          'role': role,
        },
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
  // Added method
  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> resetPassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Session? get session => _client.auth.currentSession;

  @override
  Stream<AuthState> onAuthStateChange() => _client.auth.onAuthStateChange;
}
