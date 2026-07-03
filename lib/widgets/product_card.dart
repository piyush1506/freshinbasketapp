import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isHorizontal;

  const ProductCard({super.key, required this.product, this.isHorizontal = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _loading = false;

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(3)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  Future<void> _handleAdd(CartProvider cart) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final initialQty = widget.product.minOrderQty > 0
          ? widget.product.minOrderQty
          : widget.product.orderStep;
      await cart.addToBackend(widget.product, quantity: initialQty);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleIncrement(CartProvider cart, double currentQty, double step) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final newQty = double.parse((currentQty + step).toStringAsFixed(3));
      await cart.updateQuantity(widget.product.id, newQty);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDecrement(CartProvider cart, double currentQty, double step, double minQty) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final newQty = double.parse((currentQty - step).toStringAsFixed(3));
      // Remove item if going to 0 or below min_order_qty
      if (newQty <= 0 || (minQty > 0 && newQty < minQty)) {
        await cart.removeFromBackend(widget.product.id);
      } else {
        await cart.updateQuantity(widget.product.id, newQty);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cartItem = cart.items.where((i) => i.productId == widget.product.id).firstOrNull;
    final isWishlisted = wishlist.isWishlisted(widget.product.id);
    final isOutOfStock = widget.product.stock <= 0;

    final orderStep = cartItem?.orderStep ?? widget.product.orderStep;
    final minOrderQty = cartItem?.minOrderQty ?? widget.product.minOrderQty;
    final unit = cartItem?.unit ?? widget.product.unit;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/product/${widget.product.id}'),
      child: Container(
        width: widget.isHorizontal ? 160 : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image + badges ──
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: widget.product.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.product.imageUrl!.startsWith('http')
                                ? widget.product.imageUrl!
                                : '${ApiService.baseUrl}${widget.product.imageUrl}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.image, size: 36, color: Colors.grey),
                          ),
                  ),
                ),



                // Wishlist heart — top right
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      final auth = context.read<AuthProvider>();
                      if (!auth.isLoggedIn) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please log in to manage your wishlist.'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Log In',
                              onPressed: () => Navigator.pushNamed(context, '/auth'),
                            ),
                          ),
                        );
                        return;
                      }
                      wishlist.toggle(widget.product.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isWishlisted ? const Color(0xFFE53935) : const Color(0xFF888888),
                      ),
                    ),
                  ),
                ),

                // Section Label Badge — bottom left
                if (widget.product.sectionProductLabel.isNotEmpty)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF216140),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.product.sectionProductLabel.toLowerCase().contains('organic'))
                            const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Text('🌿', style: TextStyle(fontSize: 8)),
                            ),
                          Text(
                            widget.product.sectionProductLabel.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

              ],

            ),

            // ── Product details ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.product.name,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // ── Price row (below name) ──
                    Row(
                      children: [
                        Text('₹${widget.product.price.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis),
                        if (widget.product.mrp > widget.product.price && widget.product.mrp > 0) ...[
                          const SizedBox(width: 4),
                          Text('₹${widget.product.mrp.toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFF999999), fontSize: 11, decoration: TextDecoration.lineThrough),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(width: 6),
                          Builder(builder: (context) {
                            final disc = widget.product.discountPercentage > 0
                                ? widget.product.discountPercentage.round()
                                : (((widget.product.mrp - widget.product.price) / widget.product.mrp) * 100).round();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2470F1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$disc% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }),
                        ],
                      ],
                    ),

                    const Spacer(),

                    // ── Bottom action row ──
                    if (isOutOfStock)
                      // Out of stock
                      Row(
                        children: [
                          if (unit != null && unit.isNotEmpty)
                            Text(unit,
                                style: const TextStyle(color: Color(0xFF164431), fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: Text('Unavailable',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    else if (cartItem != null)
                      // In cart: [- qty +] unit on right
                      Row(
                        children: [
                          const Spacer(),
                          _QtyControl(
                            quantity: cartItem.quantity,
                            loading: _loading,
                            formatQty: _formatQty,
                            onAdd: () => _handleIncrement(cart, cartItem.quantity, orderStep),
                            onRemove: () => _handleDecrement(cart, cartItem.quantity, orderStep, minOrderQty),
                          ),
                          if (unit != null && unit.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF164431),
                              ),
                            ),
                          ],
                        ],
                      )
                    else
                      // Not in cart: unit on left, ADD button on right
                      Row(
                        children: [
                          if (unit != null && unit.isNotEmpty)
                            Text(unit,
                                style: const TextStyle(color: Color(0xFF164431), fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _loading ? null : () => _handleAdd(cart),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFF164431), width: 1.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _loading
                                  ? const SizedBox(width: 14, height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF164431)))
                                  : const Text('ADD',
                                      style: TextStyle(
                                        color: Color(0xFF164431),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      )),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final double quantity;
  final bool loading;
  final String Function(double) formatQty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _QtyControl({
    required this.quantity,
    required this.loading,
    required this.formatQty,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF164431),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: loading ? null : onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: loading
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.remove, size: 18, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              formatQty(quantity),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: loading ? null : onAdd,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
