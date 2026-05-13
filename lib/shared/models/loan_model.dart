/// Tipo de préstamo
enum LoanType { given, received }

/// Modelo de préstamo
class LoanModel {
  final String id;
  final String userId;
  final DateTime limitDate;
  final double amount;
  final String receiver;
  final String? description;
  final LoanType loanType;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.limitDate,
    required this.amount,
    required this.receiver,
    this.description,
    required this.loanType,
  });

  bool get isGiven => loanType == LoanType.given;
  bool get isReceived => loanType == LoanType.received;

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      limitDate: DateTime.parse(json['limit_date'] as String),
      amount: (json['amount'] as num).toDouble(),
      receiver: json['receiver'] as String,
      description: json['description'] as String?,
      loanType:
          json['loan_type'] == 'given' ? LoanType.given : LoanType.received,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'limit_date': limitDate.toIso8601String(),
      'amount': amount,
      'receiver': receiver,
      'description': description,
      'loan_type': loanType == LoanType.given ? 'given' : 'received',
    };
  }

  LoanModel copyWith({
    String? id,
    String? userId,
    DateTime? limitDate,
    double? amount,
    String? receiver,
    String? description,
    LoanType? loanType,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      limitDate: limitDate ?? this.limitDate,
      amount: amount ?? this.amount,
      receiver: receiver ?? this.receiver,
      description: description ?? this.description,
      loanType: loanType ?? this.loanType,
    );
  }
}
