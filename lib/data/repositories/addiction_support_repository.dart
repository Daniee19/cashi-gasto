import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/abstinence_tracker.dart';
import '../models/blocked_app.dart';
import '../models/blocked_domain.dart';

class AddictionSupportRepository {
  final SupabaseClient _client;

  AddictionSupportRepository(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ─── Abstinence Tracker ─────────────────────────────────────

  Future<AbstinenceTracker?> getTracker() async {
    final response = await _client
        .from('abstinence_tracker')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();

    if (response == null) return null;
    return AbstinenceTracker.fromJson(response);
  }

  Future<AbstinenceTracker> createTracker({
    required double dailyBetAverage,
  }) async {
    final now = DateTime.now();
    final response = await _client.from('abstinence_tracker').insert({
      'user_id': _userId,
      'start_date': now.toIso8601String().split('T')[0],
      'current_streak_days': 0,
      'longest_streak': 0,
      'daily_bet_average': dailyBetAverage,
      'estimated_saved_amount': 0,
      'updated_at': now.toIso8601String(),
    }).select().single();

    return AbstinenceTracker.fromJson(response);
  }

  Future<AbstinenceTracker> updateTracker(AbstinenceTracker tracker) async {
    final response = await _client
        .from('abstinence_tracker')
        .update({
          'current_streak_days': tracker.currentStreakDays,
          'longest_streak': tracker.longestStreak,
          'daily_bet_average': tracker.dailyBetAverage,
          'estimated_saved_amount': tracker.estimatedSavedAmount,
          'last_reset': tracker.lastReset?.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', tracker.id)
        .select()
        .single();

    return AbstinenceTracker.fromJson(response);
  }

  Future<AbstinenceTracker> resetStreak(AbstinenceTracker tracker) async {
    final now = DateTime.now();
    final response = await _client
        .from('abstinence_tracker')
        .update({
          'start_date': now.toIso8601String().split('T')[0],
          'current_streak_days': 0,
          'last_reset': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        })
        .eq('id', tracker.id)
        .select()
        .single();

    return AbstinenceTracker.fromJson(response);
  }

  Future<void> incrementStreak(AbstinenceTracker tracker) async {
    final newStreak = tracker.currentStreakDays + 1;
    final newLongest = newStreak > tracker.longestStreak ? newStreak : tracker.longestStreak;
    final newSaved = newStreak * tracker.dailyBetAverage;

    await _client.from('abstinence_tracker').update({
      'current_streak_days': newStreak,
      'longest_streak': newLongest,
      'estimated_saved_amount': newSaved,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', tracker.id);
  }

  // ─── Blocked Apps ───────────────────────────────────────────

  Future<List<BlockedApp>> getBlockedApps() async {
    final response = await _client
        .from('blocked_apps')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BlockedApp.fromJson(e)).toList();
  }

  Future<BlockedApp> addBlockedApp({
    required String appName,
    required String packageName,
  }) async {
    final response = await _client.from('blocked_apps').insert({
      'user_id': _userId,
      'app_name': appName,
      'package_name': packageName,
    }).select().single();

    return BlockedApp.fromJson(response);
  }

  Future<void> removeBlockedApp(String id) async {
    await _client.from('blocked_apps').delete().eq('id', id);
  }

  // ─── Blocked Domains ────────────────────────────────────────

  Future<List<BlockedDomain>> getBlockedDomains() async {
    final response = await _client
        .from('blocked_domains')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => BlockedDomain.fromJson(e)).toList();
  }

  Future<BlockedDomain> addBlockedDomain(String url) async {
    final response = await _client.from('blocked_domains').insert({
      'user_id': _userId,
      'url': url,
    }).select().single();

    return BlockedDomain.fromJson(response);
  }

  Future<void> removeBlockedDomain(String id) async {
    await _client.from('blocked_domains').delete().eq('id', id);
  }
}
