import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_profile_repository.dart';

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(userProfileRepositoryProvider);
  return repository.getUserProfile();
});

class UserProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final UserProfileRepository _repository;

  UserProfileNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getUserProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    HelpMode? helpMode,
    String? profilePhoto,
  }) async {
    try {
      await _repository.updateUserProfile(
        fullName: fullName,
        helpMode: helpMode,
        profilePhoto: profilePhoto,
      );
      await loadUserProfile();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserProfileNotifier(repository);
});
