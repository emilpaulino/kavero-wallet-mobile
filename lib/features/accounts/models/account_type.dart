class AccountType {
  final int id;
  final String name;
  final String icon;
  final String color;
  final bool system;

  AccountType({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.system,
  });

  factory AccountType.fromJson(Map<String, dynamic> json) {
    return AccountType(
      id: json['id'],
      name: json['name'],
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
      system: json['system'],
    );
  }
}
