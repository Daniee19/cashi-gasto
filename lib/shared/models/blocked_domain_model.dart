/// Modelo de dominio bloqueado (para ayuda con ludopatía)
class BlockedDomainModel {
  final String id;
  final String userId;
  final String url;

  const BlockedDomainModel({
    required this.id,
    required this.userId,
    required this.url,
  });

  factory BlockedDomainModel.fromJson(Map<String, dynamic> json) {
    return BlockedDomainModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'url': url,
    };
  }

  BlockedDomainModel copyWith({
    String? id,
    String? userId,
    String? url,
  }) {
    return BlockedDomainModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      url: url ?? this.url,
    );
  }
}
