import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<UserProfile?> getUserProfile() async {
    if (_userId == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<UserProfile> updateUserProfile({
    String? fullName,
    HelpMode? helpMode,
    String? profilePhoto,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) data['full_name'] = fullName;
    if (helpMode != null) data['help_mode'] = helpMode.value;
    if (profilePhoto != null) data['profile_photo'] = profilePhoto;

    final response = await _client
        .from('users')
        .update(data)
        .eq('id', _userId!)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }
}
