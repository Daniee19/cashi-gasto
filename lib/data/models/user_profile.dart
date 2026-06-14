import 'package:equatable/equatable.dart';

enum HelpMode {
  general,
  youth,
  business,
  support;

  String get value {
    switch (this) {
      case HelpMode.general:
        return 'general';
      case HelpMode.youth:
        return 'youth';
      case HelpMode.business:
        return 'business';
      case HelpMode.support:
        return 'support';
    }
  }

  static HelpMode fromString(String value) {
    return HelpMode.values.firstWhere(
      (e) => e.value == value,
      orElse: () => HelpMode.general,
    );
  }
}

class UserProfile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final HelpMode helpMode;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.helpMode = HelpMode.general,
    this.profilePhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      helpMode: HelpMode.fromString(json['help_mode'] as String? ?? 'general'),
      profilePhoto: json['profile_photo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'help_mode': helpMode.value,
      'profile_photo': profilePhoto,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    HelpMode? helpMode,
    String? profilePhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      helpMode: helpMode ?? this.helpMode,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, helpMode, profilePhoto, createdAt, updatedAt];
}
