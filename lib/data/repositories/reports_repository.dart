import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';

class ReportsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get summary data for a date range
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('transactions')
        .select('amount, type')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    double totalIncome = 0;
    double totalExpense = 0;

    for (final row in response as List) {
      final amount = (row['amount'] as num).toDouble();
      final type = TransactionType.fromString(row['type'] as String);

      if (type == TransactionType.income) {
        totalIncome += amount;
      } else if (type == TransactionType.expense) {
        totalExpense += amount;
      }
    }

    return ReportSummary(
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  /// Get expenses breakdown by category
  Future<List<CategoryBreakdown>> getCategoryBreakdown({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Get all expense transactions with category
    final transactionsResponse = await _client
        .from('transactions')
        .select('amount, category_id')
        .eq('user_id', _userId!)
        .eq('type', 'expense')
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    // Group by category
    final Map<String, double> categoryTotals = {};
    for (final row in transactionsResponse as List) {
      final categoryId = row['category_id'] as String?;
      if (categoryId != null) {
        final amount = (row['amount'] as num).toDouble();
        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + amount;
      }
    }

    if (categoryTotals.isEmpty) return [];

    // Get category details
    final categoriesResponse = await _client
        .from('categories')
        .select('id, name, icon, color')
        .inFilter('id', categoryTotals.keys.toList());

    final categories = {
      for (final cat in categoriesResponse as List)
        cat['id'] as String: cat
    };

    // Calculate total for percentages
    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);

    // Build breakdown list
    final breakdown = categoryTotals.entries.map((entry) {
      final cat = categories[entry.key];
      return CategoryBreakdown(
        categoryId: entry.key,
        categoryName: cat?['name'] as String? ?? 'Sin categoria',
        categoryIcon: cat?['icon'] as String?,
        categoryColor: cat?['color'] as String?,
        amount: entry.value,
        percentage: totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0,
      );
    }).toList();

    // Sort by amount descending
    breakdown.sort((a, b) => b.amount.compareTo(a.amount));

    return breakdown;
  }

  /// Get monthly trends for the last N months
  Future<List<MonthlyTrend>> getMonthlyTrends({int months = 6}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    final response = await _client
        .from('transactions')
        .select('amount, type, transaction_date')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .order('transaction_date');

    // Group by month
    final Map<String, MonthlyData> monthlyData = {};

    for (int i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthlyData[key] = MonthlyData(month: month, income: 0, expense: 0);
    }

    for (final row in response as List) {
      final date = DateTime.parse(row['transaction_date'] as String);
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final amount = (row['amount'] as num).toDouble();
      final type = TransactionType.fromString(row['type'] as String);

      if (monthlyData.containsKey(key)) {
        if (type == TransactionType.income) {
          monthlyData[key] = monthlyData[key]!.copyWith(
            income: monthlyData[key]!.income + amount,
          );
        } else if (type == TransactionType.expense) {
          monthlyData[key] = monthlyData[key]!.copyWith(
            expense: monthlyData[key]!.expense + amount,
          );
        }
      }
    }

    // Convert to list and sort by date
    final trends = monthlyData.values.map((data) => MonthlyTrend(
      month: data.month,
      income: data.income,
      expense: data.expense,
    )).toList();

    trends.sort((a, b) => a.month.compareTo(b.month));

    return trends;
  }
}

/// Summary data for a period
class ReportSummary {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;

  const ReportSummary({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
  });

  double get balance => totalIncome - totalExpense;
  double get savingsRate => totalIncome > 0 ? (balance / totalIncome) * 100 : 0;
}

/// Category spending breakdown
class CategoryBreakdown {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double amount;
  final double percentage;

  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    required this.percentage,
  });
}

/// Monthly trend data
class MonthlyTrend {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyTrend({
    required this.month,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

/// Helper class for building monthly data
class MonthlyData {
  final DateTime month;
  final double income;
  final double expense;

  const MonthlyData({
    required this.month,
    required this.income,
    required this.expense,
  });

  MonthlyData copyWith({double? income, double? expense}) {
    return MonthlyData(
      month: month,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }
}
