class UserProfile {
  final int id;
  final String name;
  final String lastName;
  final String email;
  final String? profilePhoto;
  final String preferredCurrency;

  const UserProfile({
    required this.id,
    required this.name,
    required this.lastName,
    required this.email,
    required this.profilePhoto,
    required this.preferredCurrency,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      profilePhoto: json['profilePhoto'],
      preferredCurrency: json['preferredCurrency'],
    );
  }
}