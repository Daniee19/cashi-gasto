import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/models.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

/// Provider del cliente de Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Provider del repositorio de autenticación
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthRepository(client);
});

/// Provider del estado de autenticación
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// Notifier de autenticación
class AuthNotifier extends StateNotifier<AuthStatus> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _init();
  }

  void _init() {
    // Verificar sesión actual al iniciar
    _checkCurrentSession();

    // Escuchar cambios de autenticación
    _repository.authStateChanges.listen((authState) async {
      await _handleAuthState(authState.session);
    });
  }

  Future<void> _checkCurrentSession() async {
    final currentUser = _repository.currentUser;
    if (currentUser != null) {
      await _handleAuthState(Supabase.instance.client.auth.currentSession);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> _handleAuthState(Session? session) async {
    if (session == null) {
      state = const AuthUnauthenticated();
      return;
    }

    try {
      // Intentar obtener perfil
      var user = await _repository.getUserProfile(session.user.id);

      // Si no existe el perfil, crearlo
      if (user == null) {
        await _repository.createUserProfileIfNotExists(
          userId: session.user.id,
          email: session.user.email ?? '',
          fullName: session.user.userMetadata?['full_name'] ?? 'Usuario',
        );
        user = await _repository.getUserProfile(session.user.id);
      }

      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        // Si aún no hay perfil, crear uno temporal para no bloquear
        state = AuthAuthenticated(
          UserModel(
            id: session.user.id,
            fullName: session.user.userMetadata?['full_name'] ?? 'Usuario',
            email: session.user.email ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      // En caso de error, intentar autenticar con datos básicos
      state = AuthAuthenticated(
        UserModel(
          id: session.user.id,
          fullName: session.user.userMetadata?['full_name'] ?? 'Usuario',
          email: session.user.email ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Iniciar sesión
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.session != null) {
        await _handleAuthState(response.session);
      } else {
        state = const AuthError('No se pudo iniciar sesión');
      }
    } catch (e) {
      state = AuthError(_parseError(e.toString()));
    }
  }

  String _parseError(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Email o contraseña incorrectos';
    }
    if (error.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión';
    }
    return 'Error al iniciar sesión';
  }

  /// Registrarse
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AuthLoading();
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.session != null) {
        await _handleAuthState(response.session);
      } else if (response.user != null) {
        // Usuario creado pero necesita confirmar email
        state = const AuthError('Revisa tu email para confirmar tu cuenta');
      } else {
        state = const AuthError('No se pudo crear la cuenta');
      }
    } catch (e) {
      state = AuthError(_parseSignUpError(e.toString()));
    }
  }

  String _parseSignUpError(String error) {
    if (error.contains('already registered')) {
      return 'Este email ya está registrado';
    }
    if (error.contains('23505')) {
      return 'Este usuario ya existe. Intenta iniciar sesión';
    }
    return 'Error al crear cuenta';
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthUnauthenticated();
  }
}
