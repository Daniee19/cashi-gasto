import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financial_goal.dart';

class FinancialGoalRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene todas las metas del usuario
  Future<List<FinancialGoal>> getGoals() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('financial_goals')
        .select()
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FinancialGoal.fromJson(json))
        .toList();
  }

  /// Obtiene metas filtradas por estado
  Future<List<FinancialGoal>> getGoalsByStatus(GoalStatus status) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('financial_goals')
        .select()
        .eq('user_id', _userId!)
        .eq('status', status.value)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FinancialGoal.fromJson(json))
        .toList();
  }

  /// Obtiene solo las metas activas
  Future<List<FinancialGoal>> getActiveGoals() async {
    return getGoalsByStatus(GoalStatus.active);
  }

  /// Crea una nueva meta
  Future<FinancialGoal> addGoal({
    required String title,
    String? description,
    required double targetAmount,
    double initialAmount = 0,
    DateTime? deadline,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = {
      'user_id': _userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': initialAmount,
      'deadline': deadline?.toIso8601String().split('T')[0],
      'status': GoalStatus.active.value,
    };

    final response = await _client
        .from('financial_goals')
        .insert(data)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  /// Actualiza una meta
  Future<FinancialGoal> updateGoal({
    required String id,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (targetAmount != null) data['target_amount'] = targetAmount;
    if (deadline != null) data['deadline'] = deadline.toIso8601String().split('T')[0];

    final response = await _client
        .from('financial_goals')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  /// Agrega una contribucion a una meta
  Future<FinancialGoal> addContribution({
    required String goalId,
    required double amount,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    if (amount <= 0) throw Exception('El monto debe ser mayor a 0');

    // Obtener la meta actual
    final goalResponse = await _client
        .from('financial_goals')
        .select()
        .eq('id', goalId)
        .eq('user_id', _userId!)
        .single();

    final currentGoal = FinancialGoal.fromJson(goalResponse);
    final newAmount = currentGoal.currentAmount + amount;

    // Actualizar el monto y posiblemente el estado
    final data = <String, dynamic>{
      'current_amount': newAmount,
    };

    // Auto-completar si se alcanza la meta
    if (newAmount >= currentGoal.targetAmount) {
      data['status'] = GoalStatus.completed.value;
    }

    final response = await _client
        .from('financial_goals')
        .update(data)
        .eq('id', goalId)
        .eq('user_id', _userId!)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  /// Actualiza el estado de una meta
  Future<FinancialGoal> updateStatus({
    required String id,
    required GoalStatus status,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('financial_goals')
        .update({'status': status.value})
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return FinancialGoal.fromJson(response);
  }

  /// Elimina una meta
  Future<void> deleteGoal(String id) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('financial_goals')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }
}
