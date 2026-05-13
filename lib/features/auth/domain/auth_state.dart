import '../../../shared/models/models.dart';

/// Estado de autenticación
sealed class AuthStatus {
  const AuthStatus();
}

/// Estado inicial, verificando autenticación
class AuthInitial extends AuthStatus {
  const AuthInitial();
}

/// Usuario autenticado
class AuthAuthenticated extends AuthStatus {
  final UserModel user;

  const AuthAuthenticated(this.user);
}

/// Usuario no autenticado
class AuthUnauthenticated extends AuthStatus {
  const AuthUnauthenticated();
}

/// Error de autenticación
class AuthError extends AuthStatus {
  final String message;

  const AuthError(this.message);
}

/// Cargando
class AuthLoading extends AuthStatus {
  const AuthLoading();
}
