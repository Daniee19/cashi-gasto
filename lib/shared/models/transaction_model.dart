/// Método de registro de transacción
enum TransactionMethod { manual, ocr, sms }

/// Modelo de transacción
class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String fundId;
  final double amount;
  final TransactionMethod transactionMethod;
  final DateTime transactionDate;
  final String? note;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.fundId,
    required this.amount,
    required this.transactionMethod,
    required this.transactionDate,
    this.note,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      fundId: json['fund_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionMethod: _parseMethod(json['transaction_method'] as String),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static TransactionMethod _parseMethod(String method) {
    switch (method) {
      case 'ocr':
        return TransactionMethod.ocr;
      case 'sms':
        return TransactionMethod.sms;
      default:
        return TransactionMethod.manual;
    }
  }

  static String _methodToString(TransactionMethod method) {
    switch (method) {
      case TransactionMethod.ocr:
        return 'ocr';
      case TransactionMethod.sms:
        return 'sms';
      case TransactionMethod.manual:
        return 'manual';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'fund_id': fundId,
      'amount': amount,
      'transaction_method': _methodToString(transactionMethod),
      'transaction_date': transactionDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? fundId,
    double? amount,
    TransactionMethod? transactionMethod,
    DateTime? transactionDate,
    String? note,
    DateTime? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      fundId: fundId ?? this.fundId,
      amount: amount ?? this.amount,
      transactionMethod: transactionMethod ?? this.transactionMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
