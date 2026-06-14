import 'package:equatable/equatable.dart';

enum GoalStatus {
  active,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case GoalStatus.active:
        return 'active';
      case GoalStatus.completed:
        return 'completed';
      case GoalStatus.cancelled:
        return 'cancelled';
    }
  }

  static GoalStatus fromString(String value) {
    return GoalStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case GoalStatus.active:
        return 'Activa';
      case GoalStatus.completed:
        return 'Completada';
      case GoalStatus.cancelled:
        return 'Cancelada';
    }
  }
}

class FinancialGoal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalStatus status;
  final DateTime createdAt;

  const FinancialGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.status = GoalStatus.active,
    required this.createdAt,
  });

  factory FinancialGoal.fromJson(Map<String, dynamic> json) {
    return FinancialGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline'] as String) : null,
      status: GoalStatus.fromString(json['status'] as String? ?? 'active'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String().split('T')[0],
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (deadline == null) return null;
    return deadline!.difference(DateTime.now()).inDays;
  }

  FinancialGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    GoalStatus? status,
    DateTime? createdAt,
  }) {
    return FinancialGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetAmount,
        currentAmount,
        deadline,
        status,
        createdAt,
      ];
}
