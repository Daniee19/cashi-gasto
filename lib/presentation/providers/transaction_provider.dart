import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final repository = ref.watch(transactionRepositoryProvider);
  return repository.getTransactions();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
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
      return true;
    } catch (e) {
      print('Error al agregar transaccion: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repository.deleteTransaction(id);
      await loadTransactions();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository);
});
