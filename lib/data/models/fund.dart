import 'package:equatable/equatable.dart';

enum FundType {
  general,
  bank,
  cash,
  savings;

  /// Retorna el valor string del enum para almacenar en la base de datos
  String get value {
    switch (this) {
      case FundType.general:
        return 'general';
      case FundType.bank:
        return 'bank';
      case FundType.cash:
        return 'cash';
      case FundType.savings:
        return 'savings';
    }
  }

  static FundType fromString(String value) {
    return FundType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FundType.general,
    );
  }

  String get displayName {
    switch (this) {
      case FundType.general:
        return 'General';
      case FundType.bank:
        return 'Banco';
      case FundType.cash:
        return 'Efectivo';
      case FundType.savings:
        return 'Ahorros';
    }
  }
}

class Fund extends Equatable {
  final String id;
  final String userId;
  final String name;
  final FundType type;
  final double balance;
  final String? icon;
  final DateTime createdAt;

  const Fund({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    this.icon,
    required this.createdAt,
  });

  factory Fund.fromJson(Map<String, dynamic> json) {
    return Fund(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: FundType.fromString(json['type'] as String),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.value,
      'balance': balance,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Fund copyWith({
    String? id,
    String? userId,
    String? name,
    FundType? type,
    double? balance,
    String? icon,
    DateTime? createdAt,
  }) {
    return Fund(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, type, balance, icon, createdAt];
}
