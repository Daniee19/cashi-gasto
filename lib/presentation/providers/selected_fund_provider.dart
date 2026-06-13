import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import 'transaction_provider.dart';
import 'fund_provider.dart';

/// Provider para el fondo seleccionado actualmente
/// null significa "Todos los fondos"
final selectedFundIdProvider = StateProvider<String?>((ref) => null);

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
