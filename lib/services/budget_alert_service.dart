import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/alert.dart';
import '../data/repositories/budget_repository.dart';
import '../presentation/providers/alert_provider.dart';
import '../presentation/providers/budget_provider.dart';

/// Service that monitors budgets and creates alerts when thresholds are reached
class BudgetAlertService {
  final Ref _ref;
  static const String _alertedBudgetsKey = 'alerted_budgets';

  BudgetAlertService(this._ref);

  /// Check all budgets and create alerts for those exceeding thresholds
  Future<void> checkBudgetsAndAlert() async {
    final budgetsState = _ref.read(budgetNotifierProvider);

    await budgetsState.whenOrNull(
      data: (budgets) async {
        final prefs = await SharedPreferences.getInstance();
        final alertedBudgets = prefs.getStringList(_alertedBudgetsKey) ?? [];

        for (final budgetWithSpent in budgets) {
          final budget = budgetWithSpent.budget;
          final percentUsed = budgetWithSpent.percentUsed;

          // Key for tracking alerts: budgetId_threshold
          final warningKey = '${budget.id}_80';
          final exceededKey = '${budget.id}_100';

          // Check if budget exceeds 100% (over budget)
          if (budgetWithSpent.isOverBudget && !alertedBudgets.contains(exceededKey)) {
            await _createAlert(
              title: 'Presupuesto excedido',
              message: 'Has superado tu presupuesto ${budget.period.displayName.toLowerCase()} '
                  'en un ${(percentUsed - 100).toStringAsFixed(0)}%',
              alertType: AlertType.budgetWarning,
            );
            alertedBudgets.add(exceededKey);
          }
          // Check if budget is at warning level (80-99%)
          else if (budgetWithSpent.isWarning && !alertedBudgets.contains(warningKey)) {
            await _createAlert(
              title: 'Alerta de presupuesto',
              message: 'Has usado el ${percentUsed.toStringAsFixed(0)}% de tu presupuesto '
                  '${budget.period.displayName.toLowerCase()}',
              alertType: AlertType.budgetWarning,
            );
            alertedBudgets.add(warningKey);
          }
        }

        await prefs.setStringList(_alertedBudgetsKey, alertedBudgets);
      },
    );
  }

  Future<void> _createAlert({
    required String title,
    required String message,
    required AlertType alertType,
  }) async {
    await _ref.read(alertNotifierProvider.notifier).addAlert(
      alertType: alertType,
      title: title,
      message: message,
    );
  }

  /// Reset alerted budgets for a specific budget (called when budget is deleted or reset)
  Future<void> resetAlertsForBudget(String budgetId) async {
    final prefs = await SharedPreferences.getInstance();
    final alertedBudgets = prefs.getStringList(_alertedBudgetsKey) ?? [];

    alertedBudgets.removeWhere((key) => key.startsWith('${budgetId}_'));
    await prefs.setStringList(_alertedBudgetsKey, alertedBudgets);
  }

  /// Reset all alerted budgets (called at period boundaries)
  Future<void> resetAllAlertedBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_alertedBudgetsKey);
  }
}

/// Provider for budget alert service
final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  return BudgetAlertService(ref);
});

/// Provider that triggers budget alert checks when budgets change
final budgetAlertTriggerProvider = Provider<void>((ref) {
  // Listen to budget changes
  ref.listen<AsyncValue<List<BudgetWithSpent>>>(
    budgetNotifierProvider,
    (previous, next) {
      // Only check when we have new data
      next.whenData((budgets) {
        // Delay slightly to avoid race conditions
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(budgetAlertServiceProvider).checkBudgetsAndAlert();
        });
      });
    },
  );
});
