/// Modelo de alerta
class AlertModel {
  final String id;
  final String userId;
  final String alertType;
  final String message;
  final DateTime alertDate;

  const AlertModel({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.message,
    required this.alertDate,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertType: json['alert_type'] as String,
      message: json['message'] as String,
      alertDate: DateTime.parse(json['alert_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alert_type': alertType,
      'message': message,
      'alert_date': alertDate.toIso8601String(),
    };
  }

  AlertModel copyWith({
    String? id,
    String? userId,
    String? alertType,
    String? message,
    DateTime? alertDate,
  }) {
    return AlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      alertDate: alertDate ?? this.alertDate,
    );
  }
}
