import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alert.dart';

class AlertRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene todas las alertas del usuario
  Future<List<Alert>> getAlerts() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('alerts')
        .select()
        .eq('user_id', _userId!)
        .order('alert_date', ascending: false);

    return (response as List)
        .map((json) => Alert.fromJson(json))
        .toList();
  }

  /// Obtiene solo las alertas no leidas
  Future<List<Alert>> getUnreadAlerts() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('alerts')
        .select()
        .eq('user_id', _userId!)
        .eq('is_read', false)
        .order('alert_date', ascending: false);

    return (response as List)
        .map((json) => Alert.fromJson(json))
        .toList();
  }

  /// Obtiene el conteo de alertas no leidas
  Future<int> getUnreadCount() async {
    if (_userId == null) return 0;

    final response = await _client
        .from('alerts')
        .select()
        .eq('user_id', _userId!)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Crea una nueva alerta (with deduplication)
  Future<Alert> addAlert({
    required AlertType alertType,
    required String title,
    required String message,
    DateTime? alertDate,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Check for duplicate alerts in the last 24 hours with same type and title
    final existingAlert = await checkDuplicateAlert(
      alertType: alertType,
      title: title,
    );

    if (existingAlert != null) {
      // Return existing alert instead of creating duplicate
      return existingAlert;
    }

    final data = {
      'user_id': _userId,
      'alert_type': alertType.toJsonString(),
      'title': title,
      'message': message,
      'alert_date': (alertDate ?? DateTime.now()).toIso8601String(),
      'is_read': false,
    };

    final response = await _client
        .from('alerts')
        .insert(data)
        .select()
        .single();

    return Alert.fromJson(response);
  }

  /// Check if a similar alert already exists within the last 24 hours
  Future<Alert?> checkDuplicateAlert({
    required AlertType alertType,
    required String title,
  }) async {
    if (_userId == null) return null;

    final yesterday = DateTime.now().subtract(const Duration(hours: 24));

    final response = await _client
        .from('alerts')
        .select()
        .eq('user_id', _userId!)
        .eq('alert_type', alertType.toJsonString())
        .eq('title', title)
        .gte('created_at', yesterday.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1);

    final list = response as List;
    if (list.isNotEmpty) {
      return Alert.fromJson(list.first);
    }
    return null;
  }

  /// Marca una alerta como leida
  Future<void> markAsRead(String alertId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('alerts')
        .update({'is_read': true})
        .eq('id', alertId)
        .eq('user_id', _userId!);
  }

  /// Marca todas las alertas como leidas
  Future<void> markAllAsRead() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('alerts')
        .update({'is_read': true})
        .eq('user_id', _userId!)
        .eq('is_read', false);
  }

  /// Elimina una alerta
  Future<void> deleteAlert(String alertId) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('alerts')
        .delete()
        .eq('id', alertId)
        .eq('user_id', _userId!);
  }

  /// Elimina todas las alertas
  Future<void> deleteAllAlerts() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('alerts')
        .delete()
        .eq('user_id', _userId!);
  }

  /// Elimina alertas leidas
  Future<void> deleteReadAlerts() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('alerts')
        .delete()
        .eq('user_id', _userId!)
        .eq('is_read', true);
  }
}
