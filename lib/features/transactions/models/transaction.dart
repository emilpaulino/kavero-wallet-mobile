class TransactionModel {
  final int id;

  final double amount;

  final String description;

  final String type;

  final String categoryName;

  final String accountName;

  final int? accountId;

  final DateTime date;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
    required this.categoryName,
    required this.accountName,
    this.accountId,
    required this.date,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final rawDate = json['date'] ??
        json['createdAt'] ??
        json['created_at'] ??
        json['timestamp'] ??
        json['transactionDate'];
    if (rawDate != null) {
      if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      } else if (rawDate is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
      }
    }

    return TransactionModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      type: json['type'],
      categoryName: json['categoryName'] ?? '',
      accountName: json['accountName'] ?? '',
      accountId: json['accountId'],
      date: parsedDate,
    );
  }
}
