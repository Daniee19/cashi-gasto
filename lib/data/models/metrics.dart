import 'package:equatable/equatable.dart';

class Metrics extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final double totalIncome;
  final double totalExpense;
  final double savings;
  final int transactionsCount;
  final DateTime updatedAt;

  const Metrics({
    required this.id,
    required this.userId,
    required this.date,
    this.totalIncome = 0,
    this.totalExpense = 0,
    this.savings = 0,
    this.transactionsCount = 0,
    required this.updatedAt,
  });

  factory Metrics.fromJson(Map<String, dynamic> json) {
    return Metrics(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0,
      transactionsCount: json['transactions_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'total_income': totalIncome,
      'total_expense': totalExpense,
      'savings': savings,
      'transactions_count': transactionsCount,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  double get balance => totalIncome - totalExpense;

  double get savingsRate {
    if (totalIncome <= 0) return 0;
    return (savings / totalIncome * 100).clamp(0, 100);
  }

  Metrics copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? totalIncome,
    double? totalExpense,
    double? savings,
    int? transactionsCount,
    DateTime? updatedAt,
  }) {
    return Metrics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      savings: savings ?? this.savings,
      transactionsCount: transactionsCount ?? this.transactionsCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        totalIncome,
        totalExpense,
        savings,
        transactionsCount,
        updatedAt,
      ];
}
