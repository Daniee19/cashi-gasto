import 'package:equatable/equatable.dart';

class BlockedDomain extends Equatable {
  final String id;
  final String userId;
  final String url;
  final DateTime createdAt;

  const BlockedDomain({
    required this.id,
    required this.userId,
    required this.url,
    required this.createdAt,
  });

  factory BlockedDomain.fromJson(Map<String, dynamic> json) {
    return BlockedDomain(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }

  BlockedDomain copyWith({
    String? id,
    String? userId,
    String? url,
    DateTime? createdAt,
  }) {
    return BlockedDomain(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, url, createdAt];
}
