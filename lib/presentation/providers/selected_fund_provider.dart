import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../services/fund_preferences_service.dart';
import 'transaction_provider.dart';
import 'fund_provider.dart';

/// Provider para el servicio de persistencia de fondos
final fundPreferencesServiceProvider = Provider<FundPreferencesService>((ref) {
  return FundPreferencesService();
});

/// Notifier para manejar la selección de fondo con persistencia
class SelectedFundNotifier extends StateNotifier<String?> {
  final FundPreferencesService _prefsService;

  SelectedFundNotifier(this._prefsService) : super(null) {
    _loadSavedFund();
  }

  Future<void> _loadSavedFund() async {
    final savedFundId = await _prefsService.getSelectedFundId();
    if (savedFundId != null) {
      state = savedFundId;
    }
  }

  Future<void> setSelectedFund(String? fundId) async {
    state = fundId;
    await _prefsService.setSelectedFundId(fundId);
  }

  Future<void> clearSelection() async {
    state = null;
    await _prefsService.clearSelectedFund();
  }
}

/// Provider para el fondo seleccionado actualmente
/// null significa "Todos los fondos"
final selectedFundIdProvider = StateNotifierProvider<SelectedFundNotifier, String?>((ref) {
  final prefsService = ref.watch(fundPreferencesServiceProvider);
  return SelectedFundNotifier(prefsService);
});

/// Provider que filtra transacciones por el fondo seleccionado
final filteredTransactionsProvider = Provider<AsyncValue<List<Transaction>>>((ref) {
  final selectedFundId = ref.watch(selectedFundIdProvider);
  final transactionsAsync = ref.watch(transactionNotifierProvider);

  return transactionsAsync.whenData((transactions) {
    if (selectedFundId == null) {
      // Sin filtro - mostrar todas las transacciones
      return transactions;
    }
    // Filtrar por fondo seleccionado
    return transactions.where((t) => t.fundId == selectedFundId).toList();
  });
});

/// Provider para calcular el balance filtrado por fondo
final filteredBalanceProvider = Provider<({double income, double expense, double balance})>((ref) {
  final filteredTransactions = ref.watch(filteredTransactionsProvider);

  return filteredTransactions.when(
    loading: () => (income: 0.0, expense: 0.0, balance: 0.0),
    error: (_, __) => (income: 0.0, expense: 0.0, balance: 0.0),
    data: (transactions) {
      double totalIncome = 0;
      double totalExpense = 0;

      for (final t in transactions) {
        if (t.type == TransactionType.income) {
          totalIncome += t.amount;
        } else if (t.type == TransactionType.expense) {
          totalExpense += t.amount;
        }
      }

      return (
        income: totalIncome,
        expense: totalExpense,
        balance: totalIncome - totalExpense,
      );
    },
  );
});

/// Provider para obtener el nombre del fondo seleccionado
final selectedFundNameProvider = Provider<String>((ref) {
  final selectedFundId = ref.watch(selectedFundIdProvider);

  if (selectedFundId == null) {
    return 'Todos los fondos';
  }

  final fundsAsync = ref.watch(fundNotifierProvider);
  return fundsAsync.when(
    loading: () => 'Cargando...',
    error: (_, __) => 'Error',
    data: (funds) {
      final fund = funds.where((f) => f.id == selectedFundId).firstOrNull;
      return fund?.name ?? 'Fondo desconocido';
    },
  );
});
