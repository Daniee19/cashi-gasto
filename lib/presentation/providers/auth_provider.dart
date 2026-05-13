import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null)) {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = _repository.currentUser;
    if (user != null) {
      state = AsyncValue.data(user);
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repository.signIn(
      email: email,
      password: password,
    );

    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
    } else {
      state = const AsyncValue.data(null);
    }

    return result;
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();

    final result = await _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (result.isSuccess) {
      state = AsyncValue.data(result.user);
    } else {
      state = const AsyncValue.data(null);
    }

    return result;
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
