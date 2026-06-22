class CartItem {
  final int? id;
  final int productId;
  final String name;
  final double price;
  final String? image;
  final String? unit;
  int quantity;

  CartItem({
    this.id,
    required this.productId,
    required this.name,
    required this.price,
    this.image,
    this.unit,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 1;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 1;
    return 1;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map ? json['product'] as Map : null;
    return CartItem(
      id: json['id'],
      productId: product != null
          ? product['id'] ?? json['product_id']
          : (json['product'] ?? json['product_id']),
      name: product?['name'] ?? json['name'] ?? json['product_name'] ?? '',
      price: _toDouble(product?['price'] ?? json['price'] ?? json['unit_price']),
      image: product?['image'] ?? json['image'] ?? json['image_url'],
      unit: product?['unit'] ?? json['unit'] ?? json['unit_name'],
      quantity: _toInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name': name,
    'price': price,
    'image': image,
    'unit': unit,
    'quantity': quantity,
  };
}
