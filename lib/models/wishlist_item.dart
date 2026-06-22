import 'product.dart';

class WishlistItem {
  final int id;
  final int productId;
  final Product? productDetail;

  WishlistItem({
    required this.id,
    required this.productId,
    this.productDetail,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] ?? 0,
      productId: json['product'] is Map
          ? json['product']['id'] ?? 0
          : (json['product'] ?? 0),
      productDetail: json['product_detail'] != null
          ? Product.fromJson(json['product_detail'])
          : (json['product'] is Map ? Product.fromJson(json['product']) : null),
    );
  }
}
