class Review {
  final int id;
  final int order;
  final int rating;
  final String? comment;
  final String createdAt;
  final String? userName;

  Review({
    required this.id,
    required this.order,
    required this.rating,
    this.comment,
    this.createdAt = '',
    this.userName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      order: json['order'] is Map ? json['order']['id'] ?? 0 : (json['order'] ?? 0),
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'],
    );
  }
}
