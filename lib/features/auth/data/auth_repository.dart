import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// Repositorio de autenticación
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository(this._client);

  /// Usuario actual
  User? get currentUser => _client.auth.currentUser;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Registrar usuario con email y contraseña
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    // Crear perfil de usuario en la tabla users
    if (response.user != null) {
      await _createUserProfile(response.user!.id, fullName, email);
    }

    return response;
  }

  /// Crear perfil de usuario
  Future<void> _createUserProfile(
    String userId,
    String fullName,
    String email,
  ) async {
    await createUserProfileIfNotExists(
      userId: userId,
      fullName: fullName,
      email: email,
    );
  }

  /// Crear perfil si no existe (público para recovery)
  Future<void> createUserProfileIfNotExists({
    required String userId,
    required String email,
    required String fullName,
  }) async {
    try {
      // Usar upsert para evitar conflictos
      await _client.from('users').upsert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      // Verificar si ya tiene fondo
      final existingFund = await _client
          .from('funds')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingFund == null) {
        await _client.from('funds').insert({
          'user_id': userId,
          'bank': 0,
          'cash': 0,
          'saving': 0,
        });
      }
    } catch (e) {
      // Ignorar errores de duplicado, el usuario ya existe
      if (!e.toString().contains('23505')) {
        rethrow;
      }
    }
  }

  /// Cerrar sesión
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Obtener perfil de usuario
  Future<UserModel?> getUserProfile(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserModel.fromJson(response);
  }

  /// Actualizar perfil de usuario
  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? profilePhoto,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (profilePhoto != null) updates['profile_photo'] = profilePhoto;

    await _client.from('users').update(updates).eq('id', userId);
  }

  /// Enviar email de recuperación de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
