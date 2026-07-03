class SubProduct {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double mrp;
  final int stock;
  final String? unit;
  final String? imageUrl;
  final double discountPercentage;

  SubProduct({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.mrp = 0.0,
    this.stock = 0,
    this.unit,
    this.imageUrl,
    this.discountPercentage = 0.0,
  });

  factory SubProduct.fromJson(Map<String, dynamic> json) {
    return SubProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      stock: json['stock'] ?? 0,
      unit: json['unit'] is Map ? json['unit']['name'] : (json['unit_name'] ?? json['unit']),
      imageUrl: json['image_url'],
      discountPercentage: _parseDouble(json['discount_percentage']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
