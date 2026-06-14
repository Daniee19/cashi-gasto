import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum CategoryType {
  income,
  expense;

  String get value {
    switch (this) {
      case CategoryType.income:
        return 'income';
      case CategoryType.expense:
        return 'expense';
    }
  }

  static CategoryType fromString(String value) {
    return CategoryType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CategoryType.expense,
    );
  }
}

class Category extends Equatable {
  final String id;
  final String? userId;
  final String name;
  final String? description;
  final CategoryType type;
  final String? icon;
  final String? color;
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    this.userId,
    required this.name,
    this.description,
    required this.type,
    this.icon,
    this.color,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] != null
          ? CategoryType.fromString(json['type'] as String)
          : CategoryType.expense,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'type': type.value,
      'icon': icon,
      'color': color,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Color get colorValue {
    if (color == null) return Colors.grey;
    return Color(int.parse(color!.replaceFirst('#', '0xFF')));
  }

  Category copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    CategoryType? type,
    String? icon,
    String? color,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, name, description, type, icon, color, isDefault, createdAt];
}
