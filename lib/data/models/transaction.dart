import 'package:equatable/equatable.dart';

enum TransactionType {
  income,
  expense,
  transfer;

  String get value {
    switch (this) {
      case TransactionType.income:
        return 'income';
      case TransactionType.expense:
        return 'expense';
      case TransactionType.transfer:
        return 'transfer';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionType.expense,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.income:
        return 'Ingreso';
      case TransactionType.expense:
        return 'Gasto';
      case TransactionType.transfer:
        return 'Transferencia';
    }
  }
}

enum TransactionMethod {
  cash,
  card,
  transfer;

  String get value {
    switch (this) {
      case TransactionMethod.cash:
        return 'cash';
      case TransactionMethod.card:
        return 'card';
      case TransactionMethod.transfer:
        return 'transfer';
    }
  }

  static TransactionMethod fromString(String? value) {
    if (value == null) return TransactionMethod.cash;
    return TransactionMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransactionMethod.cash,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionMethod.cash:
        return 'Efectivo';
      case TransactionMethod.card:
        return 'Tarjeta';
      case TransactionMethod.transfer:
        return 'Transferencia';
    }
  }
}

class Transaction extends Equatable {
  final String id;
  final String userId;
  final String? categoryId;
  final String? fundId;
  final double amount;
  final TransactionType type;
  final TransactionMethod transactionMethod;
  final DateTime transactionDate;
  final String? note;
  final String? receiptImage;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    this.categoryId,
    this.fundId,
    required this.amount,
    required this.type,
    this.transactionMethod = TransactionMethod.cash,
    required this.transactionDate,
    this.note,
    this.receiptImage,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String?,
      fundId: json['fund_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.fromString(json['type'] as String),
      transactionMethod: TransactionMethod.fromString(json['transaction_method'] as String?),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      note: json['note'] as String?,
      receiptImage: json['receipt_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'fund_id': fundId,
      'amount': amount,
      'type': type.value,
      'transaction_method': transactionMethod.value,
      'transaction_date': transactionDate.toIso8601String().split('T')[0],
      'note': note,
      'receipt_image': receiptImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? fundId,
    double? amount,
    TransactionType? type,
    TransactionMethod? transactionMethod,
    DateTime? transactionDate,
    String? note,
    String? receiptImage,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      fundId: fundId ?? this.fundId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      transactionMethod: transactionMethod ?? this.transactionMethod,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      receiptImage: receiptImage ?? this.receiptImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        categoryId,
        fundId,
        amount,
        type,
        transactionMethod,
        transactionDate,
        note,
        receiptImage,
        createdAt,
      ];
}
