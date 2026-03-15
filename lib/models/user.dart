class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: int.parse(json['id'].toString()),
        name: json['name'],
        email: json['email'],
        role: json['role'],
        phone: json['phone'],
        address: json['address'],
      );

  bool get isAdmin => role == 'admin';
}
