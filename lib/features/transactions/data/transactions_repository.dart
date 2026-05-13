import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/models.dart';

/// Repositorio de transacciones
class TransactionsRepository {
  final SupabaseClient _client;

  TransactionsRepository(this._client);

  /// Obtener transacciones del usuario
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  /// Obtener transacciones por rango de fecha
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .gte('transaction_date', startDate.toIso8601String())
        .lte('transaction_date', endDate.toIso8601String())
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => TransactionModel.fromJson(json))
        .toList();
  }

  /// Crear transacción
  Future<TransactionModel> createTransaction({
    required String userId,
    required String categoryId,
    required String fundId,
    required double amount,
    required TransactionMethod method,
    required DateTime transactionDate,
    String? note,
  }) async {
    final response = await _client
        .from('transactions')
        .insert({
          'user_id': userId,
          'category_id': categoryId,
          'fund_id': fundId,
          'amount': amount,
          'transaction_method': _methodToString(method),
          'transaction_date': transactionDate.toIso8601String(),
          'note': note,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Actualizar transacción
  Future<TransactionModel> updateTransaction({
    required String id,
    String? categoryId,
    String? fundId,
    double? amount,
    DateTime? transactionDate,
    String? note,
  }) async {
    final updates = <String, dynamic>{};

    if (categoryId != null) updates['category_id'] = categoryId;
    if (fundId != null) updates['fund_id'] = fundId;
    if (amount != null) updates['amount'] = amount;
    if (transactionDate != null) {
      updates['transaction_date'] = transactionDate.toIso8601String();
    }
    if (note != null) updates['note'] = note;

    final response = await _client
        .from('transactions')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return TransactionModel.fromJson(response);
  }

  /// Eliminar transacción
  Future<void> deleteTransaction(String id) async {
    await _client.from('transactions').delete().eq('id', id);
  }

  static String _methodToString(TransactionMethod method) {
    switch (method) {
      case TransactionMethod.ocr:
        return 'ocr';
      case TransactionMethod.sms:
        return 'sms';
      case TransactionMethod.manual:
        return 'manual';
    }
  }
}

/// Repositorio de categorías
class CategoriesRepository {
  final SupabaseClient _client;

  CategoriesRepository(this._client);

  /// Obtener categorías del usuario
  Future<List<CategoryModel>> getCategories(String userId) async {
    final response = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .order('name');

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  /// Obtener categorías por tipo
  Future<List<CategoryModel>> getCategoriesByType({
    required String userId,
    required TransactionCategory type,
  }) async {
    final typeString =
        type == TransactionCategory.income ? 'income' : 'expense';

    final response = await _client
        .from('categories')
        .select()
        .eq('user_id', userId)
        .eq('transaction_category', typeString)
        .order('name');

    return (response as List)
        .map((json) => CategoryModel.fromJson(json))
        .toList();
  }

  /// Crear categoría
  Future<CategoryModel> createCategory({
    required String userId,
    required String name,
    String? description,
    required TransactionCategory type,
  }) async {
    final response = await _client
        .from('categories')
        .insert({
          'user_id': userId,
          'name': name,
          'description': description,
          'transaction_category':
              type == TransactionCategory.income ? 'income' : 'expense',
        })
        .select()
        .single();

    return CategoryModel.fromJson(response);
  }

  /// Eliminar categoría
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}

/// Repositorio de fondos
class FundsRepository {
  final SupabaseClient _client;

  FundsRepository(this._client);

  /// Obtener fondo del usuario
  Future<FundModel?> getFund(String userId) async {
    final response = await _client
        .from('funds')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return FundModel.fromJson(response);
  }

  /// Actualizar fondo
  Future<FundModel> updateFund({
    required String id,
    double? bank,
    double? cash,
    double? saving,
  }) async {
    final updates = <String, dynamic>{};

    if (bank != null) updates['bank'] = bank;
    if (cash != null) updates['cash'] = cash;
    if (saving != null) updates['saving'] = saving;

    final response = await _client
        .from('funds')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return FundModel.fromJson(response);
  }
}
