class User {
  final int id;
  final String name;
  final String email;
  final String contactNumber;
  final String token;
  final int roleId;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.token,
    this.roleId = 1,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      contactNumber: json['contact_number']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      roleId: json['roleId'] is int ? json['roleId'] : int.tryParse(json['roleId']?.toString() ?? '1') ?? 1,
    );
  }

  String get roleName {
    switch (roleId) {
      case 2:
        return 'Property Seller';
      case 3:
        return 'Contractor';
      case 4:
        return 'Admin';
      default:
        return 'Buyer / Normal User';
    }
  }
}
