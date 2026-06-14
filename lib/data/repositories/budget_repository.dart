import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/budget.dart';

class BudgetRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Obtiene todos los presupuestos del usuario
  Future<List<Budget>> getBudgets() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('budgets')
        .select()
        .eq('user_id', _userId!)
        .order('start_date', ascending: false);

    return (response as List)
        .map((json) => Budget.fromJson(json))
        .toList();
  }

  /// Obtiene solo los presupuestos activos (fecha actual dentro del rango)
  Future<List<Budget>> getActiveBudgets() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now().toIso8601String().split('T')[0];

    final response = await _client
        .from('budgets')
        .select()
        .eq('user_id', _userId!)
        .lte('start_date', now)
        .gte('end_date', now)
        .order('start_date', ascending: false);

    return (response as List)
        .map((json) => Budget.fromJson(json))
        .toList();
  }

  /// Crea un nuevo presupuesto
  Future<Budget> addBudget({
    required String categoryId,
    required BudgetPeriod period,
    required double amountBudgeted,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = {
      'user_id': _userId,
      'category_id': categoryId,
      'period': period.value,
      'amount_budgeted': amountBudgeted,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
    };

    final response = await _client
        .from('budgets')
        .insert(data)
        .select()
        .single();

    return Budget.fromJson(response);
  }

  /// Actualiza un presupuesto
  Future<Budget> updateBudget({
    required String id,
    double? amountBudgeted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = <String, dynamic>{};
    if (amountBudgeted != null) data['amount_budgeted'] = amountBudgeted;
    if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
    if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];

    final response = await _client
        .from('budgets')
        .update(data)
        .eq('id', id)
        .eq('user_id', _userId!)
        .select()
        .single();

    return Budget.fromJson(response);
  }

  /// Elimina un presupuesto
  Future<void> deleteBudget(String id) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('budgets')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  /// Calcula el monto gastado para un presupuesto basado en transacciones
  Future<double> getBudgetSpent(Budget budget) async {
    if (_userId == null) throw Exception('Usuario no autenticado');
    if (budget.categoryId == null) return 0;

    final response = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', _userId!)
        .eq('category_id', budget.categoryId!)
        .eq('type', 'expense')
        .gte('transaction_date', budget.startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', budget.endDate.toIso8601String().split('T')[0]);

    double total = 0;
    for (final row in response as List) {
      total += (row['amount'] as num).toDouble();
    }

    return total;
  }

  /// Obtiene presupuestos con el monto gastado calculado
  Future<List<BudgetWithSpent>> getBudgetsWithSpent() async {
    final budgets = await getActiveBudgets();
    final List<BudgetWithSpent> result = [];

    for (final budget in budgets) {
      final spent = await getBudgetSpent(budget);
      result.add(BudgetWithSpent(budget: budget, spent: spent));
    }

    return result;
  }
}

/// Clase auxiliar para presupuesto con monto gastado
class BudgetWithSpent {
  final Budget budget;
  final double spent;

  const BudgetWithSpent({
    required this.budget,
    required this.spent,
  });

  double get remaining => budget.amountBudgeted - spent;
  double get percentUsed => budget.amountBudgeted > 0
      ? (spent / budget.amountBudgeted) * 100
      : 0;
  bool get isOverBudget => spent > budget.amountBudgeted;
  bool get isWarning => percentUsed >= 80 && percentUsed < 100;
}
