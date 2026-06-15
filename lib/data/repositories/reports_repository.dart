import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction.dart';
import '../models/report_models.dart';

class ReportsRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get summary data for a date range
  Future<ReportSummary> getReportSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? fundId,
    MovementType movementType = MovementType.both,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    var query = _client
        .from('transactions')
        .select('amount, type')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    // Filter by movement type
    if (movementType == MovementType.income) {
      query = query.eq('type', 'income');
    } else if (movementType == MovementType.expense) {
      query = query.eq('type', 'expense');
    }

    final response = await query;

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
    String? fundId,
    MovementType movementType = MovementType.expense,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Get transactions with category
    var query = _client
        .from('transactions')
        .select('amount, category_id, type')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    // Filter by movement type
    if (movementType == MovementType.income) {
      query = query.eq('type', 'income');
    } else if (movementType == MovementType.expense) {
      query = query.eq('type', 'expense');
    }

    final transactionsResponse = await query;

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
  Future<List<MonthlyTrend>> getMonthlyTrends({int months = 6, String? fundId}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month - months + 1, 1);

    var query = _client
        .from('transactions')
        .select('amount, type, transaction_date')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0]);

    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    final response = await query.order('transaction_date');

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

  // ============================================================
  // MÉTODOS AVANZADOS PARA REPORTES
  // ============================================================

  /// Obtiene montos diarios para un rango de fechas (para heatmap)
  Future<List<DailyAmount>> getDailyAmounts({
    required DateTime startDate,
    required DateTime endDate,
    String? fundId,
    MovementType movementType = MovementType.both,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    var query = _client
        .from('transactions')
        .select('amount, type, transaction_date')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    // Filter by movement type
    if (movementType == MovementType.income) {
      query = query.eq('type', 'income');
    } else if (movementType == MovementType.expense) {
      query = query.eq('type', 'expense');
    }

    final response = await query.order('transaction_date');

    // Inicializar mapa con todas las fechas en el rango
    final Map<String, DailyAmount> dailyMap = {};
    var current = startDate;
    while (!current.isAfter(endDate)) {
      final key = current.toIso8601String().split('T')[0];
      dailyMap[key] = DailyAmount(
        date: DateTime(current.year, current.month, current.day),
      );
      current = current.add(const Duration(days: 1));
    }

    // Agregar transacciones
    for (final row in response as List) {
      final dateStr = row['transaction_date'] as String;
      final amount = (row['amount'] as num).toDouble();
      final type = TransactionType.fromString(row['type'] as String);

      if (dailyMap.containsKey(dateStr)) {
        final existing = dailyMap[dateStr]!;
        if (type == TransactionType.income) {
          dailyMap[dateStr] = existing.copyWith(
            income: existing.income + amount,
            transactionCount: existing.transactionCount + 1,
          );
        } else if (type == TransactionType.expense) {
          dailyMap[dateStr] = existing.copyWith(
            expense: existing.expense + amount,
            transactionCount: existing.transactionCount + 1,
          );
        }
      }
    }

    return dailyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Obtiene flujo de caja acumulado
  Future<List<CashFlowPoint>> getCashFlow({
    required DateTime startDate,
    required DateTime endDate,
    double initialBalance = 0,
    String? fundId,
    MovementType movementType = MovementType.both,
  }) async {
    final dailyAmounts = await getDailyAmounts(
      startDate: startDate,
      endDate: endDate,
      fundId: fundId,
      movementType: movementType,
    );

    final List<CashFlowPoint> cashFlow = [];
    double cumulative = initialBalance;

    for (final daily in dailyAmounts) {
      final dailyChange = daily.income - daily.expense;
      cumulative += dailyChange;

      cashFlow.add(CashFlowPoint(
        date: daily.date,
        cumulativeBalance: cumulative,
        dailyChange: dailyChange,
        income: daily.income,
        expense: daily.expense,
      ));
    }

    return cashFlow;
  }

  /// Obtiene tendencias adaptadas al período seleccionado
  Future<List<TrendPoint>> getTrendsByPeriod({
    required ReportPeriod period,
    String? fundId,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final dateRange = period.getDateRange();
    final now = DateTime.now();

    switch (period) {
      case ReportPeriod.week:
        // Tendencia diaria de la semana
        final dailyAmounts = await getDailyAmounts(
          startDate: dateRange.start,
          endDate: dateRange.end,
          fundId: fundId,
        );
        return dailyAmounts.map((d) => TrendPoint(
          date: d.date,
          income: d.income,
          expense: d.expense,
          label: _getDayLabel(d.date),
        )).toList();

      case ReportPeriod.month:
        // Tendencia semanal del mes
        return await _getWeeklyTrendsForMonth(dateRange.start, dateRange.end, fundId: fundId);

      case ReportPeriod.year:
        // Tendencia mensual del año
        return await _getMonthlyTrendsForYear(now.year, fundId: fundId);
    }
  }

  Future<List<TrendPoint>> _getWeeklyTrendsForMonth(DateTime start, DateTime end, {String? fundId}) async {
    final dailyAmounts = await getDailyAmounts(startDate: start, endDate: end, fundId: fundId);

    // Agrupar por semana
    final Map<int, TrendPoint> weeklyMap = {};

    for (final daily in dailyAmounts) {
      final weekNumber = ((daily.date.day - 1) ~/ 7) + 1;
      final existing = weeklyMap[weekNumber];

      if (existing == null) {
        weeklyMap[weekNumber] = TrendPoint(
          date: daily.date,
          income: daily.income,
          expense: daily.expense,
          label: 'Sem $weekNumber',
        );
      } else {
        weeklyMap[weekNumber] = TrendPoint(
          date: existing.date,
          income: existing.income + daily.income,
          expense: existing.expense + daily.expense,
          label: 'Sem $weekNumber',
        );
      }
    }

    return weeklyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<List<TrendPoint>> _getMonthlyTrendsForYear(int year, {String? fundId}) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);

    var query = _client
        .from('transactions')
        .select('amount, type, transaction_date')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    final response = await query;

    // Inicializar todos los meses
    final Map<int, TrendPoint> monthlyMap = {};
    for (int m = 1; m <= 12; m++) {
      monthlyMap[m] = TrendPoint(
        date: DateTime(year, m, 1),
        income: 0,
        expense: 0,
        label: _getMonthLabel(m),
      );
    }

    // Agregar transacciones
    for (final row in response as List) {
      final date = DateTime.parse(row['transaction_date'] as String);
      final amount = (row['amount'] as num).toDouble();
      final type = TransactionType.fromString(row['type'] as String);
      final month = date.month;

      final existing = monthlyMap[month]!;
      if (type == TransactionType.income) {
        monthlyMap[month] = TrendPoint(
          date: existing.date,
          income: existing.income + amount,
          expense: existing.expense,
          label: existing.label,
        );
      } else if (type == TransactionType.expense) {
        monthlyMap[month] = TrendPoint(
          date: existing.date,
          income: existing.income,
          expense: existing.expense + amount,
          label: existing.label,
        );
      }
    }

    return monthlyMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Obtiene desglose de categorías extendido
  Future<List<CategoryBreakdownExtended>> getCategoryBreakdownExtended({
    required DateTime startDate,
    required DateTime endDate,
    MovementType movementType = MovementType.expense,
    String? fundId,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    // Construir query base
    var query = _client
        .from('transactions')
        .select('amount, category_id, type')
        .eq('user_id', _userId!)
        .gte('transaction_date', startDate.toIso8601String().split('T')[0])
        .lte('transaction_date', endDate.toIso8601String().split('T')[0]);

    // Filtrar por fondo si se especifica
    if (fundId != null) {
      query = query.eq('fund_id', fundId);
    }

    // Filtrar por tipo si no es "ambos"
    if (movementType == MovementType.expense) {
      query = query.eq('type', 'expense');
    } else if (movementType == MovementType.income) {
      query = query.eq('type', 'income');
    }

    final transactionsResponse = await query;

    // Agrupar por categoría con conteo
    final Map<String, _CategoryData> categoryData = {};

    for (final row in transactionsResponse as List) {
      final categoryId = row['category_id'] as String?;
      if (categoryId != null) {
        final amount = (row['amount'] as num).toDouble();

        if (categoryData.containsKey(categoryId)) {
          categoryData[categoryId]!.amount += amount;
          categoryData[categoryId]!.count += 1;
        } else {
          categoryData[categoryId] = _CategoryData(amount: amount, count: 1);
        }
      }
    }

    if (categoryData.isEmpty) return [];

    // Obtener detalles de categorías
    final categoriesResponse = await _client
        .from('categories')
        .select('id, name, icon, color')
        .inFilter('id', categoryData.keys.toList());

    final categories = {
      for (final cat in categoriesResponse as List)
        cat['id'] as String: cat
    };

    // Calcular total
    final total = categoryData.values.fold(0.0, (a, b) => a + b.amount);

    // Construir lista
    final breakdown = categoryData.entries.map((entry) {
      final cat = categories[entry.key];
      final data = entry.value;
      return CategoryBreakdownExtended(
        categoryId: entry.key,
        categoryName: cat?['name'] as String? ?? 'Sin categoria',
        categoryIcon: cat?['icon'] as String?,
        categoryColor: cat?['color'] as String?,
        amount: data.amount,
        percentage: total > 0 ? (data.amount / total) * 100 : 0,
        transactionCount: data.count,
        averageTransaction: data.count > 0 ? data.amount / data.count : 0,
      );
    }).toList();

    breakdown.sort((a, b) => b.amount.compareTo(a.amount));
    return breakdown;
  }

  /// Obtiene indicador de ahorro
  Future<SavingsIndicator> getSavingsIndicator({
    required DateTime startDate,
    required DateTime endDate,
    double targetSavingsRate = 20,
    String? fundId,
    MovementType movementType = MovementType.both,
  }) async {
    // Para el indicador de ahorro, siempre necesitamos ambos tipos
    // pero respetamos el filtro de fondo
    final summary = await getReportSummary(
      startDate: startDate,
      endDate: endDate,
      fundId: fundId,
      movementType: MovementType.both, // Always both for savings calculation
    );

    return SavingsIndicator(
      totalIncome: summary.totalIncome,
      totalExpense: summary.totalExpense,
      targetSavingsRate: targetSavingsRate,
    );
  }

  /// Obtiene datos completos de reportes avanzados
  Future<AdvancedReportData> getAdvancedReportData({
    required ReportPeriod period,
    MovementType movementType = MovementType.both,
    double targetSavingsRate = 20,
    String? fundId,
  }) async {
    final dateRange = period.getDateRange();

    // Ejecutar queries en paralelo para mejor rendimiento
    final results = await Future.wait([
      getSavingsIndicator(
        startDate: dateRange.start,
        endDate: dateRange.end,
        targetSavingsRate: targetSavingsRate,
        fundId: fundId,
      ),
      getTrendsByPeriod(period: period, fundId: fundId),
      getCashFlow(startDate: dateRange.start, endDate: dateRange.end, fundId: fundId),
      getDailyAmounts(startDate: dateRange.start, endDate: dateRange.end, fundId: fundId),
      getCategoryBreakdownExtended(
        startDate: dateRange.start,
        endDate: dateRange.end,
        movementType: movementType,
        fundId: fundId,
      ),
    ]);

    return AdvancedReportData(
      dateRange: dateRange,
      period: period,
      movementType: movementType,
      savingsIndicator: results[0] as SavingsIndicator,
      trends: results[1] as List<TrendPoint>,
      cashFlow: results[2] as List<CashFlowPoint>,
      dailyAmounts: results[3] as List<DailyAmount>,
      categoryBreakdown: results[4] as List<CategoryBreakdownExtended>,
    );
  }

  /// Get spending comparison between current period and previous period
  Future<SpendingComparison> getSpendingComparison({
    required ReportPeriod period,
    String? fundId,
    MovementType movementType = MovementType.expense,
  }) async {
    if (_userId == null) throw Exception('Usuario no autenticado');

    final currentRange = period.getDateRange();
    final duration = currentRange.end.difference(currentRange.start);
    final previousStart = currentRange.start.subtract(duration);
    final previousEnd = currentRange.start.subtract(const Duration(days: 1));

    // Get current period data
    final currentSummary = await getReportSummary(
      startDate: currentRange.start,
      endDate: currentRange.end,
      fundId: fundId,
      movementType: movementType,
    );

    // Get previous period data
    final previousSummary = await getReportSummary(
      startDate: previousStart,
      endDate: previousEnd,
      fundId: fundId,
      movementType: movementType,
    );

    // Get top spending category for current period
    final categoryBreakdown = await getCategoryBreakdown(
      startDate: currentRange.start,
      endDate: currentRange.end,
      fundId: fundId,
      movementType: movementType,
    );

    final topCategory = categoryBreakdown.isNotEmpty ? categoryBreakdown.first : null;

    return SpendingComparison(
      currentPeriodAmount: movementType == MovementType.income
          ? currentSummary.totalIncome
          : currentSummary.totalExpense,
      previousPeriodAmount: movementType == MovementType.income
          ? previousSummary.totalIncome
          : previousSummary.totalExpense,
      topCategory: topCategory,
      period: period,
      movementType: movementType,
    );
  }

  // Helpers para etiquetas
  String _getDayLabel(DateTime date) {
    const days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return days[date.weekday - 1];
  }

  String _getMonthLabel(int month) {
    const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return months[month - 1];
  }
}

/// Helper class para agrupar datos de categoría
class _CategoryData {
  double amount;
  int count;

  _CategoryData({required this.amount, required this.count});
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
