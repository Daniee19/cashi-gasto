import 'package:equatable/equatable.dart';

/// Enum para filtrar tipo de movimiento en reportes
enum MovementType {
  income,
  expense,
  both;

  String get value {
    switch (this) {
      case MovementType.income:
        return 'income';
      case MovementType.expense:
        return 'expense';
      case MovementType.both:
        return 'both';
    }
  }

  String get displayName {
    switch (this) {
      case MovementType.income:
        return 'Ingresos';
      case MovementType.expense:
        return 'Gastos';
      case MovementType.both:
        return 'Ambos';
    }
  }
}

/// Enum para períodos de reporte
enum ReportPeriod {
  week,
  month,
  year;

  String get value {
    switch (this) {
      case ReportPeriod.week:
        return 'week';
      case ReportPeriod.month:
        return 'month';
      case ReportPeriod.year:
        return 'year';
    }
  }

  String get displayName {
    switch (this) {
      case ReportPeriod.week:
        return 'Semanal';
      case ReportPeriod.month:
        return 'Mensual';
      case ReportPeriod.year:
        return 'Anual';
    }
  }

  /// Obtiene el rango de fechas para este período
  DateRange getDateRange() {
    final now = DateTime.now();
    switch (this) {
      case ReportPeriod.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          start: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case ReportPeriod.month:
        return DateRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case ReportPeriod.year:
        return DateRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
    }
  }

  /// Obtiene el número de puntos de datos para gráficos de tendencia
  int get dataPoints {
    switch (this) {
      case ReportPeriod.week:
        return 7; // 7 días
      case ReportPeriod.month:
        return DateTime.now().day; // días del mes actual
      case ReportPeriod.year:
        return 12; // 12 meses
    }
  }
}

/// Helper para rangos de fecha
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// Duración del rango en días
  int get durationInDays => end.difference(start).inDays + 1;

  /// Genera lista de fechas en el rango
  List<DateTime> get dates {
    final List<DateTime> result = [];
    var current = start;
    while (!current.isAfter(end)) {
      result.add(DateTime(current.year, current.month, current.day));
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  List<Object?> get props => [start, end];
}

/// Datos de gasto/ingreso diario para heatmap
class DailyAmount extends Equatable {
  final DateTime date;
  final double income;
  final double expense;
  final int transactionCount;

  const DailyAmount({
    required this.date,
    this.income = 0,
    this.expense = 0,
    this.transactionCount = 0,
  });

  double get total => income + expense;
  double get balance => income - expense;

  /// Intensidad normalizada (0-1) basada en el gasto
  double intensityFor(double maxAmount) {
    if (maxAmount <= 0) return 0;
    return (expense / maxAmount).clamp(0, 1);
  }

  /// Intensidad normalizada (0-1) basada en el tipo de movimiento
  double intensityForType(double maxAmount, MovementType movementType) {
    if (maxAmount <= 0) return 0;
    switch (movementType) {
      case MovementType.income:
        return (income / maxAmount).clamp(0, 1);
      case MovementType.expense:
        return (expense / maxAmount).clamp(0, 1);
      case MovementType.both:
        return (total / maxAmount).clamp(0, 1);
    }
  }

  /// Obtiene el monto según el tipo de movimiento
  double amountForType(MovementType movementType) {
    switch (movementType) {
      case MovementType.income:
        return income;
      case MovementType.expense:
        return expense;
      case MovementType.both:
        return total;
    }
  }

  DailyAmount copyWith({
    DateTime? date,
    double? income,
    double? expense,
    int? transactionCount,
  }) {
    return DailyAmount(
      date: date ?? this.date,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  @override
  List<Object?> get props => [date, income, expense, transactionCount];
}

/// Punto de flujo de caja acumulado
class CashFlowPoint extends Equatable {
  final DateTime date;
  final double cumulativeBalance;
  final double dailyChange;
  final double income;
  final double expense;

  const CashFlowPoint({
    required this.date,
    required this.cumulativeBalance,
    this.dailyChange = 0,
    this.income = 0,
    this.expense = 0,
  });

  bool get isPositive => cumulativeBalance >= 0;

  @override
  List<Object?> get props => [date, cumulativeBalance, dailyChange, income, expense];
}

/// Indicador de ahorro
class SavingsIndicator extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double targetSavingsRate; // Porcentaje objetivo de ahorro

  const SavingsIndicator({
    required this.totalIncome,
    required this.totalExpense,
    this.targetSavingsRate = 20, // 20% por defecto
  });

  /// Monto ahorrado
  double get amountSaved => totalIncome - totalExpense;

  /// Porcentaje ahorrado (puede ser negativo)
  double get savingsPercentage {
    if (totalIncome <= 0) return 0;
    return (amountSaved / totalIncome) * 100;
  }

  /// Porcentaje gastado
  double get expensePercentage {
    if (totalIncome <= 0) return 0;
    return (totalExpense / totalIncome) * 100;
  }

  /// Progreso hacia la meta de ahorro (0-100+)
  double get goalProgress {
    if (targetSavingsRate <= 0) return 100;
    return (savingsPercentage / targetSavingsRate) * 100;
  }

  /// Si se está cumpliendo la meta
  bool get isOnTarget => savingsPercentage >= targetSavingsRate;

  /// Estado de salud financiera
  FinancialHealth get healthStatus {
    if (savingsPercentage >= 30) return FinancialHealth.excellent;
    if (savingsPercentage >= 20) return FinancialHealth.good;
    if (savingsPercentage >= 10) return FinancialHealth.fair;
    if (savingsPercentage >= 0) return FinancialHealth.needsAttention;
    return FinancialHealth.critical;
  }

  @override
  List<Object?> get props => [totalIncome, totalExpense, targetSavingsRate];
}

/// Estado de salud financiera
enum FinancialHealth {
  excellent,
  good,
  fair,
  needsAttention,
  critical;

  String get displayName {
    switch (this) {
      case FinancialHealth.excellent:
        return 'Excelente';
      case FinancialHealth.good:
        return 'Bueno';
      case FinancialHealth.fair:
        return 'Regular';
      case FinancialHealth.needsAttention:
        return 'Necesita atencion';
      case FinancialHealth.critical:
        return 'Critico';
    }
  }

  String get emoji {
    switch (this) {
      case FinancialHealth.excellent:
        return '🌟';
      case FinancialHealth.good:
        return '😊';
      case FinancialHealth.fair:
        return '😐';
      case FinancialHealth.needsAttention:
        return '😟';
      case FinancialHealth.critical:
        return '🚨';
    }
  }
}

/// Datos de tendencia para un punto en el tiempo
class TrendPoint extends Equatable {
  final DateTime date;
  final double income;
  final double expense;
  final String label; // Etiqueta para el eje X

  const TrendPoint({
    required this.date,
    required this.income,
    required this.expense,
    required this.label,
  });

  double get balance => income - expense;

  @override
  List<Object?> get props => [date, income, expense, label];
}

/// Datos completos de reportes avanzados
class AdvancedReportData extends Equatable {
  final DateRange dateRange;
  final ReportPeriod period;
  final MovementType movementType;
  final SavingsIndicator savingsIndicator;
  final List<TrendPoint> trends;
  final List<CashFlowPoint> cashFlow;
  final List<DailyAmount> dailyAmounts;
  final List<CategoryBreakdownExtended> categoryBreakdown;

  const AdvancedReportData({
    required this.dateRange,
    required this.period,
    required this.movementType,
    required this.savingsIndicator,
    required this.trends,
    required this.cashFlow,
    required this.dailyAmounts,
    required this.categoryBreakdown,
  });

  bool get isEmpty => trends.isEmpty && dailyAmounts.isEmpty;

  @override
  List<Object?> get props => [
        dateRange,
        period,
        movementType,
        savingsIndicator,
        trends,
        cashFlow,
        dailyAmounts,
        categoryBreakdown,
      ];
}

/// Desglose de categoría extendido con más datos
class CategoryBreakdownExtended extends Equatable {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final double amount;
  final double percentage;
  final int transactionCount;
  final double averageTransaction;

  const CategoryBreakdownExtended({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    required this.percentage,
    this.transactionCount = 0,
    this.averageTransaction = 0,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryIcon,
        categoryColor,
        amount,
        percentage,
        transactionCount,
        averageTransaction,
      ];
}

/// Category spending breakdown (duplicated here from repository for model consistency)
class CategoryBreakdown extends Equatable {
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

  @override
  List<Object?> get props => [categoryId, categoryName, categoryIcon, categoryColor, amount, percentage];
}

/// Comparacion de gastos entre periodos
class SpendingComparison extends Equatable {
  final double currentPeriodAmount;
  final double previousPeriodAmount;
  final CategoryBreakdown? topCategory;
  final ReportPeriod period;
  final MovementType movementType;

  const SpendingComparison({
    required this.currentPeriodAmount,
    required this.previousPeriodAmount,
    this.topCategory,
    required this.period,
    required this.movementType,
  });

  /// Diferencia absoluta entre periodos
  double get difference => currentPeriodAmount - previousPeriodAmount;

  /// Porcentaje de cambio (puede ser positivo o negativo)
  double get percentageChange {
    if (previousPeriodAmount <= 0) {
      return currentPeriodAmount > 0 ? 100 : 0;
    }
    return ((currentPeriodAmount - previousPeriodAmount) / previousPeriodAmount) * 100;
  }

  /// Si el cambio es un aumento
  bool get isIncrease => difference > 0;

  /// Si el cambio es significativo (mas del 5%)
  bool get isSignificant => percentageChange.abs() > 5;

  /// Etiqueta del periodo anterior segun el tipo de periodo
  String get previousPeriodLabel {
    switch (period) {
      case ReportPeriod.week:
        return 'semana anterior';
      case ReportPeriod.month:
        return 'mes anterior';
      case ReportPeriod.year:
        return 'ano anterior';
    }
  }

  @override
  List<Object?> get props => [
        currentPeriodAmount,
        previousPeriodAmount,
        topCategory,
        period,
        movementType,
      ];
}
