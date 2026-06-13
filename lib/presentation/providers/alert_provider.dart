import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/alert.dart';
import '../../data/repositories/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository();
});

final alertsProvider = FutureProvider<List<Alert>>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getAlerts();
});

final unreadAlertsCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(alertRepositoryProvider);
  return repository.getUnreadCount();
});

class AlertNotifier extends StateNotifier<AsyncValue<List<Alert>>> {
  final AlertRepository _repository;

  AlertNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAlerts();
  }

  Future<void> loadAlerts() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _repository.getAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addAlert({
    required AlertType alertType,
    required String title,
    required String message,
    DateTime? alertDate,
  }) async {
    try {
      await _repository.addAlert(
        alertType: alertType,
        title: title,
        message: message,
        alertDate: alertDate,
      );
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsRead(String alertId) async {
    try {
      await _repository.markAsRead(alertId);
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      await _repository.deleteAlert(alertId);
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAllAlerts() async {
    try {
      await _repository.deleteAllAlerts();
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteReadAlerts() async {
    try {
      await _repository.deleteReadAlerts();
      await loadAlerts();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final alertNotifierProvider =
    StateNotifierProvider<AlertNotifier, AsyncValue<List<Alert>>>((ref) {
  final repository = ref.watch(alertRepositoryProvider);
  return AlertNotifier(repository);
});

/// Provider para alertas filtradas por tipo
final alertsByTypeProvider = Provider.family<AsyncValue<List<Alert>>, AlertType>((ref, type) {
  final alertsState = ref.watch(alertNotifierProvider);
  return alertsState.whenData(
    (alerts) => alerts.where((a) => a.alertType == type).toList(),
  );
});

/// Provider para alertas no leidas
final unreadAlertsProvider = Provider<AsyncValue<List<Alert>>>((ref) {
  final alertsState = ref.watch(alertNotifierProvider);
  return alertsState.whenData(
    (alerts) => alerts.where((a) => !a.isRead).toList(),
  );
});
