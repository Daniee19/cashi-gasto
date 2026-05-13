/// Modelo de presupuesto
class BudgetModel {
  final String id;
  final String userId;
  final String period;
  final DateTime date;
  final double amountBudgeted;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.period,
    required this.date,
    required this.amountBudgeted,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      period: json['period'] as String,
      date: DateTime.parse(json['date'] as String),
      amountBudgeted: (json['amount_budgeted'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'period': period,
      'date': date.toIso8601String(),
      'amount_budgeted': amountBudgeted,
    };
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? period,
    DateTime? date,
    double? amountBudgeted,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      period: period ?? this.period,
      date: date ?? this.date,
      amountBudgeted: amountBudgeted ?? this.amountBudgeted,
    );
  }
}
