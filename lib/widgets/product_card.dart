import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool isHorizontal;

  const ProductCard({super.key, required this.product, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cartItem = cart.items.where((i) => i.productId == product.id).firstOrNull;
    final isWishlisted = wishlist.isWishlisted(product.id);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product/${product.id}'),
      child: Container(
        width: isHorizontal ? 160 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl!.startsWith('http')
                                ? product.imageUrl!
                                : '${ApiService.baseUrl}${product.imageUrl}',
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: const Color(0xFFF0F0F0),
                            child: const Icon(Icons.image, size: 32, color: Colors.grey),
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => wishlist.toggle(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isWishlisted
                            ? const Color(0xFFB14E3F)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (product.unit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        product.unit!.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '₹${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF164431),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (cartItem != null)
                        _QuantityControl(
                          quantity: cartItem.quantity,
                          onAdd: () => cart.addToBackend(product),
                          onRemove: () => cart.updateQuantity(product.id, cartItem.quantity - 1),
                        )
                      else
                        GestureDetector(
                          onTap: () => cart.addToBackend(product),
                          child: Container(
                              padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF164431),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, size: 18, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF164431),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.remove, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onAdd,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.add, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
