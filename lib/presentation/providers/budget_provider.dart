import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/budget.dart';
import '../../data/repositories/budget_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});

final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgets();
});

final activeBudgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getActiveBudgets();
});

/// Provider para presupuestos activos con monto gastado calculado
final budgetsWithSpentProvider = FutureProvider<List<BudgetWithSpent>>((ref) async {
  final repository = ref.watch(budgetRepositoryProvider);
  return repository.getBudgetsWithSpent();
});

class BudgetNotifier extends StateNotifier<AsyncValue<List<BudgetWithSpent>>> {
  final BudgetRepository _repository;

  BudgetNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    state = const AsyncValue.loading();
    try {
      final budgets = await _repository.getBudgetsWithSpent();
      state = AsyncValue.data(budgets);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addBudget({
    required String categoryId,
    required BudgetPeriod period,
    required double amountBudgeted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Calcular fechas basadas en el período si no se proporcionan
      final now = DateTime.now();
      DateTime start = startDate ?? now;
      DateTime end;

      if (endDate != null) {
        end = endDate;
      } else {
        switch (period) {
          case BudgetPeriod.weekly:
            start = DateTime(start.year, start.month, start.day);
            end = start.add(const Duration(days: 6));
            break;
          case BudgetPeriod.monthly:
            start = DateTime(start.year, start.month, 1);
            end = DateTime(start.year, start.month + 1, 0);
            break;
          case BudgetPeriod.yearly:
            start = DateTime(start.year, 1, 1);
            end = DateTime(start.year, 12, 31);
            break;
        }
      }

      await _repository.addBudget(
        categoryId: categoryId,
        period: period,
        amountBudgeted: amountBudgeted,
        startDate: start,
        endDate: end,
      );
      await loadBudgets();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateBudget({
    required String id,
    double? amountBudgeted,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      await _repository.updateBudget(
        id: id,
        amountBudgeted: amountBudgeted,
        startDate: startDate,
        endDate: endDate,
      );
      await loadBudgets();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    try {
      await _repository.deleteBudget(id);
      await loadBudgets();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<List<BudgetWithSpent>>>((ref) {
  final repository = ref.watch(budgetRepositoryProvider);
  return BudgetNotifier(repository);
});

/// Provider para obtener presupuestos que necesitan alerta (>= 80%)
final budgetsNeedingAlertProvider = Provider<AsyncValue<List<BudgetWithSpent>>>((ref) {
  final budgetsState = ref.watch(budgetNotifierProvider);
  return budgetsState.whenData(
    (budgets) => budgets.where((b) => b.percentUsed >= 80).toList(),
  );
});

/// Provider para obtener presupuestos excedidos (> 100%)
final overBudgetProvider = Provider<AsyncValue<List<BudgetWithSpent>>>((ref) {
  final budgetsState = ref.watch(budgetNotifierProvider);
  return budgetsState.whenData(
    (budgets) => budgets.where((b) => b.isOverBudget).toList(),
  );
});
