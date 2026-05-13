import 'package:equatable/equatable.dart';

class AbstinenceTracker extends Equatable {
  final String id;
  final String userId;
  final DateTime startDate;
  final int currentStreakDays;
  final int longestStreak;
  final DateTime? lastReset;
  final double estimatedSavedAmount;
  final double dailyBetAverage;
  final DateTime updatedAt;

  const AbstinenceTracker({
    required this.id,
    required this.userId,
    required this.startDate,
    this.currentStreakDays = 0,
    this.longestStreak = 0,
    this.lastReset,
    this.estimatedSavedAmount = 0,
    this.dailyBetAverage = 0,
    required this.updatedAt,
  });

  factory AbstinenceTracker.fromJson(Map<String, dynamic> json) {
    return AbstinenceTracker(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      currentStreakDays: json['current_streak_days'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastReset: json['last_reset'] != null ? DateTime.parse(json['last_reset'] as String) : null,
      estimatedSavedAmount: (json['estimated_saved_amount'] as num?)?.toDouble() ?? 0,
      dailyBetAverage: (json['daily_bet_average'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'current_streak_days': currentStreakDays,
      'longest_streak': longestStreak,
      'last_reset': lastReset?.toIso8601String(),
      'estimated_saved_amount': estimatedSavedAmount,
      'daily_bet_average': dailyBetAverage,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get calculatedCurrentStreak {
    return DateTime.now().difference(startDate).inDays;
  }

  double get calculatedSavedAmount {
    return calculatedCurrentStreak * dailyBetAverage;
  }

  String get streakMessage {
    if (currentStreakDays == 0) {
      return 'Comienza tu racha hoy!';
    } else if (currentStreakDays == 1) {
      return 'Primer dia! Sigue asi!';
    } else if (currentStreakDays < 7) {
      return 'Vas muy bien! $currentStreakDays dias!';
    } else if (currentStreakDays < 30) {
      return 'Increible! $currentStreakDays dias!';
    } else if (currentStreakDays < 90) {
      return 'Eres un campeon! $currentStreakDays dias!';
    } else {
      return 'Leyenda! $currentStreakDays dias!';
    }
  }

  bool get isNewRecord => currentStreakDays > longestStreak;

  AbstinenceTracker copyWith({
    String? id,
    String? userId,
    DateTime? startDate,
    int? currentStreakDays,
    int? longestStreak,
    DateTime? lastReset,
    double? estimatedSavedAmount,
    double? dailyBetAverage,
    DateTime? updatedAt,
  }) {
    return AbstinenceTracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startDate: startDate ?? this.startDate,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      lastReset: lastReset ?? this.lastReset,
      estimatedSavedAmount: estimatedSavedAmount ?? this.estimatedSavedAmount,
      dailyBetAverage: dailyBetAverage ?? this.dailyBetAverage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        startDate,
        currentStreakDays,
        longestStreak,
        lastReset,
        estimatedSavedAmount,
        dailyBetAverage,
        updatedAt,
      ];
}
