import 'package:equatable/equatable.dart';

class BlockedApp extends Equatable {
  final String id;
  final String userId;
  final String appName;
  final String packageName;
  final DateTime createdAt;

  const BlockedApp({
    required this.id,
    required this.userId,
    required this.appName,
    required this.packageName,
    required this.createdAt,
  });

  factory BlockedApp.fromJson(Map<String, dynamic> json) {
    return BlockedApp(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      appName: json['app_name'] as String,
      packageName: json['package_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'app_name': appName,
      'package_name': packageName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BlockedApp copyWith({
    String? id,
    String? userId,
    String? appName,
    String? packageName,
    DateTime? createdAt,
  }) {
    return BlockedApp(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, appName, packageName, createdAt];
}
