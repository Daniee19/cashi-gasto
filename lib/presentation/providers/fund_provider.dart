import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fund.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/fund_repository.dart';
import 'transaction_provider.dart';

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository();
});

final fundsProvider = FutureProvider<List<Fund>>((ref) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getFunds();
});

/// Provider that returns funds with calculated balances from transactions
final fundsWithCalculatedBalanceProvider = Provider<AsyncValue<List<Fund>>>((ref) {
  final fundsAsync = ref.watch(fundNotifierProvider);
  final transactionsAsync = ref.watch(transactionNotifierProvider);

  // If either is loading, return loading
  if (fundsAsync.isLoading || transactionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // If either has an error, return the first error
  if (fundsAsync.hasError) {
    return AsyncValue.error(fundsAsync.error!, fundsAsync.stackTrace ?? StackTrace.current);
  }
  if (transactionsAsync.hasError) {
    return AsyncValue.error(transactionsAsync.error!, transactionsAsync.stackTrace ?? StackTrace.current);
  }

  final funds = fundsAsync.value ?? [];
  final transactions = transactionsAsync.value ?? [];

  // Calculate balance for each fund from transactions
  final Map<String, double> fundBalances = {};

  for (final transaction in transactions) {
    if (transaction.fundId != null) {
      final currentBalance = fundBalances[transaction.fundId!] ?? 0;
      if (transaction.type == TransactionType.income) {
        fundBalances[transaction.fundId!] = currentBalance + transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        fundBalances[transaction.fundId!] = currentBalance - transaction.amount;
      }
    }
  }

  // Create new fund objects with calculated balances
  final fundsWithBalances = funds.map((fund) {
    final calculatedBalance = fundBalances[fund.id] ?? 0;
    return fund.copyWith(balance: calculatedBalance);
  }).toList();

  return AsyncValue.data(fundsWithBalances);
});

class FundNotifier extends StateNotifier<AsyncValue<List<Fund>>> {
  final FundRepository _repository;

  FundNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFunds();
  }

  Future<void> loadFunds() async {
    state = const AsyncValue.loading();
    try {
      final funds = await _repository.getFunds();
      state = AsyncValue.data(funds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> addFund({
    required String name,
    required FundType type,
    double balance = 0,
    String? icon,
  }) async {
    try {
      await _repository.addFund(
        name: name,
        type: type,
        balance: balance,
        icon: icon,
      );
      await loadFunds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteFund(String id) async {
    try {
      await _repository.deleteFund(id);
      await loadFunds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateFund({
    required String id,
    required String name,
    required FundType type,
    String? icon,
  }) async {
    try {
      await _repository.updateFund(
        id: id,
        name: name,
        type: type,
        icon: icon,
      );
      await loadFunds();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<({bool success, String? error})> transferBetweenFunds({
    required String fromFundId,
    required String toFundId,
    required double amount,
  }) async {
    try {
      await _repository.transferBetweenFunds(
        fromFundId: fromFundId,
        toFundId: toFundId,
        amount: amount,
      );
      await loadFunds();
      return (success: true, error: null);
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }
}

final fundNotifierProvider =
    StateNotifierProvider<FundNotifier, AsyncValue<List<Fund>>>((ref) {
  final repository = ref.watch(fundRepositoryProvider);
  return FundNotifier(repository);
});
