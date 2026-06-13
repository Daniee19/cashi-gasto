import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/financial_goal.dart';
import '../../data/repositories/financial_goal_repository.dart';

final financialGoalRepositoryProvider = Provider<FinancialGoalRepository>((ref) {
  return FinancialGoalRepository();
});

final goalsProvider = FutureProvider<List<FinancialGoal>>((ref) async {
  final repository = ref.watch(financialGoalRepositoryProvider);
  return repository.getGoals();
});

final activeGoalsProvider = FutureProvider<List<FinancialGoal>>((ref) async {
  final repository = ref.watch(financialGoalRepositoryProvider);
  return repository.getActiveGoals();
});

class FinancialGoalNotifier extends StateNotifier<AsyncValue<List<FinancialGoal>>> {
  final FinancialGoalRepository _repository;

  FinancialGoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addGoal({
    required String title,
    String? description,
    required double targetAmount,
    double initialAmount = 0,
    DateTime? deadline,
  }) async {
    try {
      await _repository.addGoal(
        title: title,
        description: description,
        targetAmount: targetAmount,
        initialAmount: initialAmount,
        deadline: deadline,
      );
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGoal({
    required String id,
    String? title,
    String? description,
    double? targetAmount,
    DateTime? deadline,
  }) async {
    try {
      await _repository.updateGoal(
        id: id,
        title: title,
        description: description,
        targetAmount: targetAmount,
        deadline: deadline,
      );
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<({bool success, String? error})> addContribution({
    required String goalId,
    required double amount,
  }) async {
    try {
      await _repository.addContribution(
        goalId: goalId,
        amount: amount,
      );
      await loadGoals();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  Future<bool> updateStatus({
    required String id,
    required GoalStatus status,
  }) async {
    try {
      await _repository.updateStatus(id: id, status: status);
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsCompleted(String id) async {
    return updateStatus(id: id, status: GoalStatus.completed);
  }

  Future<bool> markAsCancelled(String id) async {
    return updateStatus(id: id, status: GoalStatus.cancelled);
  }

  Future<bool> reactivate(String id) async {
    return updateStatus(id: id, status: GoalStatus.active);
  }

  Future<bool> deleteGoal(String id) async {
    try {
      await _repository.deleteGoal(id);
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final financialGoalNotifierProvider =
    StateNotifierProvider<FinancialGoalNotifier, AsyncValue<List<FinancialGoal>>>((ref) {
  final repository = ref.watch(financialGoalRepositoryProvider);
  return FinancialGoalNotifier(repository);
});

/// Provider para metas filtradas por estado
final goalsByStatusProvider = Provider.family<AsyncValue<List<FinancialGoal>>, GoalStatus>((ref, status) {
  final goalsState = ref.watch(financialGoalNotifierProvider);
  return goalsState.whenData(
    (goals) => goals.where((g) => g.status == status).toList(),
  );
});

/// Provider para metas activas solamente
final activeGoalsNotifierProvider = Provider<AsyncValue<List<FinancialGoal>>>((ref) {
  return ref.watch(goalsByStatusProvider(GoalStatus.active));
});

/// Provider para metas completadas
final completedGoalsProvider = Provider<AsyncValue<List<FinancialGoal>>>((ref) {
  return ref.watch(goalsByStatusProvider(GoalStatus.completed));
});

/// Provider para metas que estan cerca de su fecha limite (menos de 7 dias)
final urgentGoalsProvider = Provider<AsyncValue<List<FinancialGoal>>>((ref) {
  final goalsState = ref.watch(financialGoalNotifierProvider);
  return goalsState.whenData(
    (goals) => goals.where((g) {
      if (g.status != GoalStatus.active) return false;
      final daysRemaining = g.daysRemaining;
      return daysRemaining != null && daysRemaining <= 7 && daysRemaining >= 0;
    }).toList(),
  );
});

/// Provider para el progreso total de todas las metas activas
final totalGoalsProgressProvider = Provider<double>((ref) {
  final goalsState = ref.watch(financialGoalNotifierProvider);
  return goalsState.when(
    loading: () => 0,
    error: (_, __) => 0,
    data: (goals) {
      final activeGoals = goals.where((g) => g.status == GoalStatus.active).toList();
      if (activeGoals.isEmpty) return 0;

      double totalProgress = 0;
      for (final goal in activeGoals) {
        totalProgress += goal.progressPercentage;
      }
      return totalProgress / activeGoals.length;
    },
  );
});
