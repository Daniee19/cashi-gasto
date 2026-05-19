import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  /// Inicia sesión y verifica que el perfil exista en la tabla users
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('Error al iniciar sesión');
      }

      // Verificar si existe el perfil en la tabla users
      final profileExists = await _checkUserProfileExists(response.user!.id);

      if (!profileExists) {
        // Cerrar sesión si no tiene perfil
        await _client.auth.signOut();
        return AuthResult.failure(
          'Tu cuenta no está configurada correctamente. '
          'Por favor, contacta al soporte o regístrate nuevamente.',
        );
      }

      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  /// Registra un nuevo usuario y crea su perfil
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        return AuthResult.failure('Error al crear la cuenta');
      }

      // El perfil se crea automáticamente via trigger en Supabase
      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Error inesperado: $e');
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Verifica si el perfil del usuario existe en la tabla users
  Future<bool> _checkUserProfileExists(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error verificando perfil: $e');
      return false;
    }
  }

  /// Mapea errores de Supabase a mensajes amigables
  String _mapAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos';
    }
    if (message.contains('Email not confirmed')) {
      return 'Por favor, confirma tu correo electrónico';
    }
    if (message.contains('User already registered')) {
      return 'Este correo ya está registrado';
    }
    return message;
  }
}

/// Resultado de operaciones de autenticación
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User user) => AuthResult._(
        isSuccess: true,
        user: user,
      );

  factory AuthResult.failure(String message) => AuthResult._(
        isSuccess: false,
        errorMessage: message,
      );
}
