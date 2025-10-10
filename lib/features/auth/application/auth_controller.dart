import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';
import '../../../core/failures.dart';
import 'dart:developer' as developer;

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return SupabaseAuthRepository();
});

sealed class AuthStatus {
  const AuthStatus();
}

class AuthInitial extends AuthStatus {
  const AuthInitial();
}

class AuthLoading extends AuthStatus {
  const AuthLoading();
}

class AuthAuthenticated extends AuthStatus {
  final Session session;
  const AuthAuthenticated(this.session);
}

class AuthLoggedOut extends AuthStatus {
  const AuthLoggedOut();
}

class AuthError extends AuthStatus {
  final String message;
  const AuthError(this.message);
}

class AuthController extends StateNotifier<AuthStatus> {
  AuthController(this._repo) : super(const AuthInitial()) {
    // Ensure Supabase is initialized before setting up subscription
    if (Supabase.instance.client.auth.currentSession != null) {
      state = AuthAuthenticated(Supabase.instance.client.auth.currentSession!);
    } else {
      state = const AuthLoggedOut();
    }

    // Keep UI in sync with Supabase session changes
    _sub = _repo.onAuthStateChange().listen((event) {
      if (_repo.session != null) {
        state = AuthAuthenticated(_repo.session!);
      } else {
        state = const AuthLoggedOut();
      }
    }, onError: (error, stackTrace) {
      developer.log('Auth state change error: $error', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(error));
    });
  }

  final IAuthRepository _repo;
  late final StreamSubscription _sub;

  String _mapSupabaseErrorToMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Incorrect email or password.';
        case 'Email not confirmed':
          return 'Please confirm your email address.';
        case 'User already registered':
          return 'This email is already registered.';
        case 'Invalid email':
          return 'Please enter a valid email address.';
        case 'Weak password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'Password should be at least 6 characters':
          return 'Password must be at least 6 characters long.';
        case 'Unable to validate email address: invalid format':
          return 'Please enter a valid email address.';
        case 'User not found':
          return 'No account found with this email address.';
        case 'Email rate limit exceeded':
          return 'Too many requests. Please try again later.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    } else if (error is Failure) {
      return error.message;
    } else {
      return 'An unexpected error occurred: $error';
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthLoading();
    try {
      await _repo.signIn(email: email, password: password);
      if (_repo.session != null) {
        state = AuthAuthenticated(_repo.session!);
      } else {
        state = const AuthError('Failed to retrieve session after sign-in');
      }
    } catch (e, stackTrace) {
      developer.log('Sign-in error: $e', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(e));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    state = const AuthLoading();
    try {
      // Validate role
      if (!['guest_house_owner', 'tenant'].contains(role)) {
        throw AuthFailure('Invalid role: must be "guest_house_owner" or "tenant"');
      }
      await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
      );
      if (_repo.session != null) {
        state = AuthAuthenticated(_repo.session!);
      } else {
        state = const AuthError('Failed to retrieve session after sign-up');
      }
    } catch (e, stackTrace) {
      developer.log('Sign-up error: $e', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(e));
    }
  }

  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repo.signOut();
      state = const AuthLoggedOut();
    } catch (e, stackTrace) {
      developer.log('Sign-out error: $e', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(e));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AuthLoading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AuthLoggedOut(); // Return to logged out state after sending email
    } catch (e, stackTrace) {
      developer.log('Password reset email error: $e', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(e));
    }
  }

  Future<void> resetPassword(String newPassword) async {
    state = const AuthLoading();
    try {
      await _repo.resetPassword(newPassword);
      state = const AuthLoggedOut(); // Return to logged out state after password reset
    } catch (e, stackTrace) {
      developer.log('Password reset error: $e', stackTrace: stackTrace);
      state = AuthError(_mapSupabaseErrorToMessage(e));
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthStatus>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
