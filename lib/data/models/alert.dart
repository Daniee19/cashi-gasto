import 'package:equatable/equatable.dart';

enum AlertType {
  budgetWarning,
  goalReminder,
  loanDue,
  streakMilestone,
  general;

  static AlertType fromString(String value) {
    switch (value) {
      case 'budget_warning':
        return AlertType.budgetWarning;
      case 'goal_reminder':
        return AlertType.goalReminder;
      case 'loan_due':
        return AlertType.loanDue;
      case 'streak_milestone':
        return AlertType.streakMilestone;
      default:
        return AlertType.general;
    }
  }

  String toJsonString() {
    switch (this) {
      case AlertType.budgetWarning:
        return 'budget_warning';
      case AlertType.goalReminder:
        return 'goal_reminder';
      case AlertType.loanDue:
        return 'loan_due';
      case AlertType.streakMilestone:
        return 'streak_milestone';
      case AlertType.general:
        return 'general';
    }
  }

  String get displayName {
    switch (this) {
      case AlertType.budgetWarning:
        return 'Alerta de presupuesto';
      case AlertType.goalReminder:
        return 'Recordatorio de meta';
      case AlertType.loanDue:
        return 'Prestamo por vencer';
      case AlertType.streakMilestone:
        return 'Logro de racha';
      case AlertType.general:
        return 'General';
    }
  }
}

class Alert extends Equatable {
  final String id;
  final String userId;
  final AlertType alertType;
  final String title;
  final String message;
  final DateTime alertDate;
  final bool isRead;
  final DateTime createdAt;

  const Alert({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.title,
    required this.message,
    required this.alertDate,
    this.isRead = false,
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertType: AlertType.fromString(json['alert_type'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      alertDate: DateTime.parse(json['alert_date'] as String),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alert_type': alertType.toJsonString(),
      'title': title,
      'message': message,
      'alert_date': alertDate.toIso8601String(),
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Alert copyWith({
    String? id,
    String? userId,
    AlertType? alertType,
    String? title,
    String? message,
    DateTime? alertDate,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return Alert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertType: alertType ?? this.alertType,
      title: title ?? this.title,
      message: message ?? this.message,
      alertDate: alertDate ?? this.alertDate,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, alertType, title, message, alertDate, isRead, createdAt];
}
