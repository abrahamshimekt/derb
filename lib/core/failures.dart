class Failure implements Exception {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message) : super(message);
}
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}

Failure mapSupabaseError(dynamic error) {
  if (error is String && error.contains('Network')) {
    return NetworkFailure(error);
  } else if (error.toString().contains('Auth') || error.toString().contains('Unauthorized')) {
    return AuthFailure(error.toString());
  }
  return UnknownFailure(error.toString());
}