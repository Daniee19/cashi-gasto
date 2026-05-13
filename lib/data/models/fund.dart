import 'package:equatable/equatable.dart';

enum FundType {
  bank,
  cash,
  savings;

  static FundType fromString(String value) {
    return FundType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FundType.cash,
    );
  }

  String get displayName {
    switch (this) {
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
      'type': type.name,
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
