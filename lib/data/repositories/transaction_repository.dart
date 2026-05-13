import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class TransactionRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Transaction>> getTransactions() async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId!)
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }

  Future<Transaction> addTransaction({
    required double amount,
    required TransactionType type,
    required DateTime transactionDate,
    String? categoryId,
    String? fundId,
    TransactionMethod? transactionMethod,
    String? note,
    String? receiptImage,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final data = {
      'user_id': _userId,
      'amount': amount,
      'type': type.name,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'category_id': categoryId,
      'fund_id': fundId,
      'transaction_method': transactionMethod?.name ?? 'cash',
      'note': note,
      'receipt_image': receiptImage,
    };

    final response = await _client
        .from('transactions')
        .insert(data)
        .select()
        .single();

    return Transaction.fromJson(response);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('transactions')
        .update(transaction.toJson())
        .eq('id', transaction.id)
        .eq('user_id', _userId!);
  }

  Future<void> deleteTransaction(String id) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId!);
  }

  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0])
        .order('transaction_date', ascending: false);

    return (response as List)
        .map((json) => Transaction.fromJson(json))
        .toList();
  }
}
