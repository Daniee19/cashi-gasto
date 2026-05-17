import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fund.dart';
import '../../data/repositories/fund_repository.dart';

final fundRepositoryProvider = Provider<FundRepository>((ref) {
  return FundRepository();
});

final fundsProvider = FutureProvider<List<Fund>>((ref) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getFunds();
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
}

final fundNotifierProvider =
    StateNotifierProvider<FundNotifier, AsyncValue<List<Fund>>>((ref) {
  final repository = ref.watch(fundRepositoryProvider);
  return FundNotifier(repository);
});
