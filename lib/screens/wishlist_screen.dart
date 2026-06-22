import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/wishlist_provider.dart';
import '../services/api_service.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistProvider>().fetchWishlist();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text('My Wishlist',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222))),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
      ),
      body: wishlist.loading
          ? const Center(child: CircularProgressIndicator())
          : wishlist.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Your wishlist is empty',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/main', arguments: 1),
                        child: const Text('Start Shopping'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => wishlist.fetchWishlist(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishlist.items.length,
                    itemBuilder: (context, index) {
                      final item = wishlist.items[index];
                      final product = item.productDetail;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: product?.imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: product!.imageUrl!.startsWith('http')
                                          ? product.imageUrl!
                                          : '${ApiService.baseUrl}${product.imageUrl}',
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorWidget: (_, __, ___) =>
                                          const Icon(Icons.image, color: Colors.grey),
                                    )
                                  : const Icon(Icons.image, color: Colors.grey, size: 32),
                            ),
                          ),
                          title: Text(
                            product?.name ?? 'Product #${item.productId}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '₹${(product?.price ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFF164431),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFB14E3F)),
                            onPressed: () => wishlist.remove(item.productId),
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/product/${item.productId}',
                          ),
                        ),
                      );
                    },
                  ),
                ),

    );
  }
}
