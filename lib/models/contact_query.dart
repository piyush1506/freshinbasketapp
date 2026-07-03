class ContactQuery {
  final int id;
  final String name;
  final String email;
  final String message;
  final String? response;
  final String? respondedAt;
  final String createdAt;

  ContactQuery({
    required this.id,
    required this.name,
    required this.email,
    required this.message,
    this.response,
    this.respondedAt,
    required this.createdAt,
  });

  factory ContactQuery.fromJson(Map<String, dynamic> json) {
    return ContactQuery(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      message: json['message'] ?? '',
      response: json['response'],
      respondedAt: json['responded_at'],
      createdAt: json['created_at'] ?? '',
    );
  }
}
