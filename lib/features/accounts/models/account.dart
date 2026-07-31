class Account {
  final int id;

  final String name;

  final String description;

  final double initialBalance;

  final double currentBalance;

  final String currency;

  final int accountTypeId;

  final String accountTypeName;

  final String icon;

  final String color;

  Account({
    required this.id,
    required this.name,
    required this.description,
    required this.initialBalance,
    required this.currentBalance,
    required this.currency,
    required this.accountTypeId,
    required this.accountTypeName,
    required this.icon,
    required this.color,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      initialBalance: (json['initialBalance'] as num).toDouble(),
      currentBalance: (json['currentBalance'] as num).toDouble(),
      currency: json['currency'],
      accountTypeId: json['accountTypeId'],
      accountTypeName: json['accountTypeName'],
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
