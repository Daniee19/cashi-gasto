import 'package:equatable/equatable.dart';

enum BudgetPeriod {
  weekly,
  monthly,
  yearly;

  String get value {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'weekly';
      case BudgetPeriod.monthly:
        return 'monthly';
      case BudgetPeriod.yearly:
        return 'yearly';
    }
  }

  static BudgetPeriod fromString(String value) {
    return BudgetPeriod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BudgetPeriod.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Semanal';
      case BudgetPeriod.monthly:
        return 'Mensual';
      case BudgetPeriod.yearly:
        return 'Anual';
    }
  }
}

class Budget extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final BudgetPeriod period;
  final double amountBudgeted;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.period,
    required this.amountBudgeted,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      period: BudgetPeriod.fromString(json['period'] as String),
      amountBudgeted: (json['amount_budgeted'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'period': period.value,
      'amount_budgeted': amountBudgeted,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Budget copyWith({
    String? id,
    String? userId,
    String? categoryId,
    BudgetPeriod? period,
    double? amountBudgeted,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      period: period ?? this.period,
      amountBudgeted: amountBudgeted ?? this.amountBudgeted,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, categoryId, period, amountBudgeted, startDate, endDate, createdAt];
}
