class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? address;
  final String? avatar;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role = 'CUSTOMER',
    required this.phoneNumber,
    this.address,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'CUSTOMER',
      phoneNumber: json['phone_number'],
      address: json['address'],
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'phone_number': phoneNumber,
    'address': address,
  };
}
