class Account {

  final int id;

  final String name;

  final String description;

  final double currentBalance;

  final String currency;

  final String type;

  final String icon;

  final String color;

  Account({
    required this.id,
    required this.name,
    required this.description,
    required this.currentBalance,
    required this.currency,
    required this.type,
    required this.icon,
    required this.color,
  });

  factory Account.fromJson(Map<String, dynamic> json){

    return Account(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      currentBalance: (json['currentBalance'] as num).toDouble(),
      currency: json['currency'],
      type: json['type'],
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );

  }

}