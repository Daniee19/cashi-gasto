/// Tipo de categoría de transacción
enum TransactionCategory { income, expense }

/// Modelo de categoría
class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final TransactionCategory transactionCategory;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.transactionCategory,
  });

  bool get isIncome => transactionCategory == TransactionCategory.income;
  bool get isExpense => transactionCategory == TransactionCategory.expense;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      transactionCategory: json['transaction_category'] == 'income'
          ? TransactionCategory.income
          : TransactionCategory.expense,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'transaction_category':
          transactionCategory == TransactionCategory.income
              ? 'income'
              : 'expense',
    };
  }

  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    TransactionCategory? transactionCategory,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      transactionCategory: transactionCategory ?? this.transactionCategory,
    );
  }
}
