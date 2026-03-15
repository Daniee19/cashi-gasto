import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/transactions_repository.dart';

/// Provider del repositorio de transacciones
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TransactionsRepository(client);
});

/// Provider del repositorio de categorías
final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CategoriesRepository(client);
});

/// Provider del repositorio de fondos
final fundsRepositoryProvider = Provider<FundsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FundsRepository(client);
});

/// Provider de transacciones recientes
final recentTransactionsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final repository = ref.watch(transactionsRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return [];

  return repository.getTransactions(userId: userId, limit: 10);
});

/// Provider de todas las categorías
final categoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return [];

  return repository.getCategories(userId);
});

/// Provider de categorías de ingreso
final incomeCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return [];

  return repository.getCategoriesByType(
    userId: userId,
    type: TransactionCategory.income,
  );
});

/// Provider de categorías de gasto
final expenseCategoriesProvider =
    FutureProvider.autoDispose<List<CategoryModel>>((ref) async {
  final repository = ref.watch(categoriesRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return [];

  return repository.getCategoriesByType(
    userId: userId,
    type: TransactionCategory.expense,
  );
});

/// Provider del fondo del usuario
final userFundProvider = FutureProvider.autoDispose<FundModel?>((ref) async {
  final repository = ref.watch(fundsRepositoryProvider);
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) return null;

  return repository.getFund(userId);
});

/// Provider del balance total
final totalBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  final fund = await ref.watch(userFundProvider.future);
  return fund?.total ?? 0;
});
