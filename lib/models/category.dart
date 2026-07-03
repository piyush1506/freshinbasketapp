import 'product.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String? imageUrl;
  final List<Product> products;
  final String? sectionName;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.imageUrl,
    this.products = const [],
    this.sectionName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      imageUrl: json['image_url'],
      products: (json['products'] as List?)
              ?.map((p) => Product.fromJson(p))
              .toList() ??
          [],
      sectionName: json['section_name'],
    );
  }
}
