import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fund.dart';

class FundRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene todos los fondos del usuario
  Future<List<Fund>> getFunds() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('funds')
        .select()
        .eq('user_id', _userId!)
        .order('name');

    return (response as List)
        .map((json) => Fund.fromJson(json))
        .toList();
  }

  /// Crea un nuevo fondo
  Future<Fund> addFund({
    required String name,
    required FundType type,
    double balance = 0,
    String? icon,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = {
      'user_id': _userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'icon': icon,
    };

    final response = await _client
        .from('funds')
        .insert(data)
        .select()
        .single();

    return Fund.fromJson(response);
  }

  /// Actualiza el balance de un fondo
  Future<void> updateBalance(String fundId, double newBalance) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('funds')
        .update({'balance': newBalance})
        .eq('id', fundId)
        .eq('user_id', _userId!);
  }

  /// Elimina un fondo
  Future<void> deleteFund(String id) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('funds')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }
}
