/// Modelo de métricas mensuales
class MetricsModel {
  final String id;
  final String userId;
  final DateTime periodDate;
  final double totalIncome;
  final double totalExpense;
  final double savings;
  final int transactionsCount;
  final DateTime updatedAt;

  const MetricsModel({
    required this.id,
    required this.userId,
    required this.periodDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.savings,
    required this.transactionsCount,
    required this.updatedAt,
  });

  double get balance => totalIncome - totalExpense;

  factory MetricsModel.fromJson(Map<String, dynamic> json) {
    return MetricsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      periodDate: DateTime.parse(json['period_date'] as String),
      totalIncome: (json['total_income'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      savings: (json['savings'] as num).toDouble(),
      transactionsCount: json['transactions_count'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'period_date': periodDate.toIso8601String(),
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'savings': savings,
      'transactions_count': transactionsCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MetricsModel copyWith({
    String? id,
    String? userId,
    DateTime? periodDate,
    double? totalIncome,
    double? totalExpense,
    double? savings,
    int? transactionsCount,
    DateTime? updatedAt,
  }) {
    return MetricsModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      periodDate: periodDate ?? this.periodDate,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      savings: savings ?? this.savings,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
