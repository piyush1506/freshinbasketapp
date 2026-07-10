import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class FloatingCartButton extends StatelessWidget {
  const FloatingCartButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    if (cartProvider.isCartEmpty) {
      return const SizedBox.shrink();
    }

    final items = cartProvider.items;
    final displayItems = items.take(3).toList();
    final itemCount = cartProvider.itemCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32), // Blinkit style vibrant green
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Push cart screen directly instead of navigating bottom nav
            // because this button might be on screens outside MainShell.
            Navigator.pushNamed(context, '/cart');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Overlapping images
                SizedBox(
                  width: 36.0 + ((displayItems.length - 1) * 20.0),
                  height: 36,
                  child: Stack(
                    children: List.generate(displayItems.length, (index) {
                      final item = displayItems[index];
                      final imageUrl = item.image?.startsWith('http') == true
                          ? item.image!
                          : '${ApiService.baseUrl}${item.image}';

                      return Positioned(
                        left: index * 20.0,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                            color: Colors.white,
                          ),
                          child: ClipOval(
                            child: item.image != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.image, size: 20),
                                  )
                                : const Icon(Icons.image, size: 20),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'View cart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$itemCount item${itemCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),

                // Arrow
                const Icon(
                  Icons.play_arrow, // similar to filled triangle/chevron in blinkit
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
