import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/application/auth_controller.dart';

// User role enum for type safety
enum UserRole { tenant, guestHouseOwner, unknown }

// Auth state with computed properties
class AuthState {
  final AuthStatus status;
  final String? userId;
  final UserRole role;
  final bool isAuthenticated;
  final bool isOwner;
  final bool isTenant;

  const AuthState({
    required this.status,
    this.userId,
    this.role = UserRole.unknown,
    this.isAuthenticated = false,
    this.isOwner = false,
    this.isTenant = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    UserRole? role,
    bool? isAuthenticated,
    bool? isOwner,
    bool? isTenant,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOwner: isOwner ?? this.isOwner,
      isTenant: isTenant ?? this.isTenant,
    );
  }

  static AuthState fromAuthStatus(AuthStatus status) {
    if (status is AuthAuthenticated) {
      final session = status.session;
      final userId = session.user.id;
      final roleString = session.user.userMetadata?['role']?.toString();
      
      UserRole role;
      switch (roleString) {
        case 'guest_house_owner':
          role = UserRole.guestHouseOwner;
          break;
        case 'tenant':
          role = UserRole.tenant;
          break;
        default:
          role = UserRole.unknown;
      }

      return AuthState(
        status: status,
        userId: userId,
        role: role,
        isAuthenticated: true,
        isOwner: role == UserRole.guestHouseOwner,
        isTenant: role == UserRole.tenant,
      );
    }

    return AuthState(
      status: status,
      isAuthenticated: false,
    );
  }
}

// Computed auth state provider
final authStateProvider = Provider<AuthState>((ref) {
  final authStatus = ref.watch(authControllerProvider);
  return AuthState.fromAuthStatus(authStatus);
});

// Convenience providers for common auth checks
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).userId;
});

final userRoleProvider = Provider<UserRole>((ref) {
  return ref.watch(authStateProvider).role;
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isOwner;
});

final isTenantProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isTenant;
});
