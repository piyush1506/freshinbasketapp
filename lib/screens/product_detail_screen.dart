import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Product> _productFuture;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productFuture = ApiService.fetchProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              final isWishlisted = wishlist.isWishlisted(widget.productId);
              return IconButton(
                icon: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? const Color(0xFFB14E3F) : null,
                ),
                onPressed: () => wishlist.toggle(widget.productId),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final product = snapshot.data!;
          final cart = context.watch<CartProvider>();
          final inCart = cart.items
              .where((i) => i.productId == product.id)
              .firstOrNull;

          return ListView(
            children: [
              Container(
                height: 280,
                color: Colors.green[50],
                child: Center(
                  child: product.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: product.imageUrl!.startsWith('http')
                              ? product.imageUrl!
                              : '${ApiService.baseUrl}${product.imageUrl}',
                          fit: BoxFit.contain,
                          placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (_, __, ___) => const Icon(
                              Icons.image, size: 80, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (product.unit != null)
                      Text('Per ${product.unit}',
                          style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('₹${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 22,
                                color: Color(0xFF164431),
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (product.stock > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('In Stock',
                                style: TextStyle(
                                    color: Color(0xFF164431),
                                    fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Sold Out',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(product.description,
                          style:
                              TextStyle(color: Colors.grey[700], height: 1.5)),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('Quantity:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        _quantityControl(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: product.stock > 0
                            ? () {
                                if (inCart != null) {
                                  cart.updateQuantity(
                                      product.id,
                                      inCart.quantity + _quantity);
                                } else {
                                  cart.addToBackend(product,
                                      quantity: _quantity);
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${product.name} added to cart'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: Text(
                            inCart != null ? 'Update Cart' : 'Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF164431),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quantityControl() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: _quantity > 1
                ? () => setState(() => _quantity--)
                : null,
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$_quantity',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }
}
