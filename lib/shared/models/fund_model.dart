/// Modelo de fondo (cajones de dinero)
class FundModel {
  final String id;
  final String userId;
  final double bank;
  final double cash;
  final double saving;

  const FundModel({
    required this.id,
    required this.userId,
    required this.bank,
    required this.cash,
    required this.saving,
  });

  double get total => bank + cash + saving;

  factory FundModel.fromJson(Map<String, dynamic> json) {
    return FundModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bank: (json['bank'] as num).toDouble(),
      cash: (json['cash'] as num).toDouble(),
      saving: (json['saving'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank': bank,
      'cash': cash,
      'saving': saving,
    };
  }

  FundModel copyWith({
    String? id,
    String? userId,
    double? bank,
    double? cash,
    double? saving,
  }) {
    return FundModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bank: bank ?? this.bank,
      cash: cash ?? this.cash,
      saving: saving ?? this.saving,
    );
  }
}
