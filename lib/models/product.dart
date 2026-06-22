class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final int stock;
  final String? unit;
  final String? imageUrl;
  final List<int> categories;
  final List<String> categoryNames;

  Product({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    required this.price,
    this.stock = 0,
    this.unit,
    this.imageUrl,
    this.categories = const [],
    this.categoryNames = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price'] ?? 0.0),
      stock: json['stock'] ?? 0,
      unit: json['unit'] is Map ? json['unit']['name'] : (json['unit_name'] ?? json['unit']),
      imageUrl: json['image_url'],
      categories: (json['categories'] as List?)?.cast<int>() ?? [],
      categoryNames: (json['category_names'] as List?)?.cast<String>() ?? [],
    );
  }
}

double _parseDouble(dynamic value){
  if(value == null) return 0.0;
  if(value is num) return value.toDouble();
  if(value is String) return  double.tryParse(value) ?? 0.0;
  return 0.0;
}