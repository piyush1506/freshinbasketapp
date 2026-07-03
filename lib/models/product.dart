import 'sub_product.dart';

class Product {
  final int id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final double mrp;
  final int stock;
  final String? unit;
  final String? imageUrl;
  final List<int> categories;
  final List<String> categoryNames;
  final double taxPercentage;
  final double discountPercentage;
  final double orderStep;
  final double minOrderQty;
  final List<SubProduct> subproducts;
  final String sectionSlug;
  final String sectionProductLabel;

  Product({
    required this.id,
    required this.name,
    this.slug = '',
    this.description = '',
    required this.price,
    this.mrp = 0.0,
    this.stock = 0,
    this.unit,
    this.imageUrl,
    this.categories = const [],
    this.categoryNames = const [],
    this.taxPercentage = 0.0,
    this.discountPercentage = 0.0,
    this.orderStep = 1.0,
    this.minOrderQty = 0.0,
    this.subproducts = const [],
    this.sectionSlug = '',
    this.sectionProductLabel = '',
  });

  bool get hasSubproducts => subproducts.isNotEmpty;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      price: _parseDouble(json['price']),
      mrp: _parseDouble(json['mrp']),
      stock: json['stock'] ?? 0,
      unit: json['unit'] is Map
          ? json['unit']['name']
          : (json['unit_name'] ?? json['unit']),
      imageUrl: json['image_url'],
      categories: (json['categories'] as List?)?.cast<int>() ?? [],
      categoryNames: (json['category_names'] as List?)?.cast<String>() ?? [],
      taxPercentage: _parseDouble(json['tax_percentage']),
      discountPercentage: _parseDouble(json['discount_percentage']),
      orderStep: _parseDouble(json['order_step'], fallback: 1.0),
      minOrderQty: _parseDouble(json['min_order_qty']),
      subproducts: (json['subproducts'] as List?)
              ?.map((s) => SubProduct.fromJson(s))
              .toList() ??
          [],
      sectionSlug: json['section_slug'] ?? '',
      sectionProductLabel: json['section_product_label'] ?? '',
    );
  }
}

double _parseDouble(dynamic value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}