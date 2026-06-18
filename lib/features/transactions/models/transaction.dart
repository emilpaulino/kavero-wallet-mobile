class TransactionModel {
  final int id;

  final double amount;

  final String description;

  final String type;

  final String categoryName;

  final String accountName;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.categoryName,
    required this.accountName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      type: json['type'],
      categoryName: json['categoryName'],
      accountName: json['accountName'],
    );
  }
}
