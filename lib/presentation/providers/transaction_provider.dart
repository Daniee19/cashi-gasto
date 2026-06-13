import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import 'budget_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  /// Refresca los presupuestos después de modificar transacciones
  void _refreshBudgets() {
    _ref.read(budgetNotifierProvider.notifier).loadBudgets();
  }

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _repository.getTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime transactionDate,
    String? categoryId,
    String? fundId,
    TransactionMethod? transactionMethod,
    String? note,
  }) async {
    try {
      print('DEBUG: Intentando agregar transaccion...');
      print('DEBUG: categoryId=$categoryId, fundId=$fundId');

      await _repository.addTransaction(
        amount: amount,
        type: type,
        transactionDate: transactionDate,
        categoryId: categoryId,
        fundId: fundId,
        transactionMethod: transactionMethod,
        note: note,
      );
      await loadTransactions();
      _refreshBudgets(); // Actualizar presupuestos al agregar gasto
      print('DEBUG: Transaccion agregada exitosamente');
      return true;
    } catch (e, stackTrace) {
      print('ERROR al agregar transaccion: $e');
      print('StackTrace: $stackTrace');
      return false;
    }
  }

  Future<bool> updateTransaction(Transaction transaction) async {
    try {
      await _repository.updateTransaction(transaction);
      await loadTransactions();
      _refreshBudgets(); // Actualizar presupuestos al modificar transacción
      return true;
    } catch (e) {
      print('Error al actualizar transaccion: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadTransactions();
      _refreshBudgets(); // Actualizar presupuestos al eliminar transacción
      return true;
    } catch (e) {
      print('Error al eliminar transaccion: $e');
      return false;
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository, ref);
});
