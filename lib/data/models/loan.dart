import 'package:equatable/equatable.dart';

enum LoanType {
  lent,
  borrowed;

  static LoanType fromString(String value) {
    return LoanType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LoanType.lent,
    );
  }

  String get displayName {
    switch (this) {
      case LoanType.lent:
        return 'Prestado';
      case LoanType.borrowed:
        return 'Pedido prestado';
    }
  }
}

enum LoanStatus {
  pending,
  paid,
  overdue;

  static LoanStatus fromString(String value) {
    return LoanStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LoanStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case LoanStatus.pending:
        return 'Pendiente';
      case LoanStatus.paid:
        return 'Pagado';
      case LoanStatus.overdue:
        return 'Vencido';
    }
  }
}

class Loan extends Equatable {
  final String id;
  final String userId;
  final String contactName;
  final double amount;
  final LoanType loanType;
  final DateTime? limitDate;
  final String? description;
  final LoanStatus status;
  final DateTime createdAt;

  const Loan({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.amount,
    required this.loanType,
    this.limitDate,
    this.description,
    this.status = LoanStatus.pending,
    required this.createdAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      contactName: json['contact_name'] as String,
      amount: (json['amount'] as num).toDouble(),
      loanType: LoanType.fromString(json['loan_type'] as String),
      limitDate: json['limit_date'] != null ? DateTime.parse(json['limit_date'] as String) : null,
      description: json['description'] as String?,
      status: LoanStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_name': contactName,
      'amount': amount,
      'loan_type': loanType.name,
      'limit_date': limitDate?.toIso8601String().split('T')[0],
      'description': description,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isOverdue {
    if (limitDate == null || status == LoanStatus.paid) return false;
    return DateTime.now().isAfter(limitDate!);
  }

  int? get daysUntilDue {
    if (limitDate == null) return null;
    return limitDate!.difference(DateTime.now()).inDays;
  }

  Loan copyWith({
    String? id,
    String? userId,
    String? contactName,
    double? amount,
    LoanType? loanType,
    DateTime? limitDate,
    String? description,
    LoanStatus? status,
    DateTime? createdAt,
  }) {
    return Loan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactName: contactName ?? this.contactName,
      amount: amount ?? this.amount,
      loanType: loanType ?? this.loanType,
      limitDate: limitDate ?? this.limitDate,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        contactName,
        amount,
        loanType,
        limitDate,
        description,
        status,
        createdAt,
      ];
}
