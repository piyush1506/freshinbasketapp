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

  const ProductCard(
      {super.key, required this.product, this.isHorizontal = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _loading = false;

  String _formatQty(double qty) {
    if (qty == qty.truncateToDouble()) return qty.toInt().toString();
    return qty
        .toStringAsFixed(3)
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

  Future<void> _handleIncrement(
      CartProvider cart, double currentQty, double step) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final newQty = double.parse((currentQty + step).toStringAsFixed(3));
      await cart.updateQuantity(widget.product.id, newQty);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleDecrement(
      CartProvider cart, double currentQty, double step, double minQty) async {
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

  Widget _buildSkeleton() {
    return Container(
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 14, width: 80, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4))),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product.imageUrl == null) {
      return _buildContent(context, null);
    }
    return CachedNetworkImage(
      imageUrl: widget.product.imageUrl!.startsWith('http')
          ? widget.product.imageUrl!
          : '${ApiService.baseUrl}${widget.product.imageUrl}',
      imageBuilder: (context, imageProvider) => _buildContent(context, imageProvider),
      placeholder: (context, url) => _buildSkeleton(),
      errorWidget: (context, url, error) => _buildContent(context, null),
    );
  }

  Widget _buildContent(BuildContext context, ImageProvider? imageProvider) {
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final cartItem =
        cart.items.where((i) => i.productId == widget.product.id).firstOrNull;
    final isWishlisted = wishlist.isWishlisted(widget.product.id);
    final isOutOfStock = widget.product.stock <= 0;

    final orderStep = cartItem?.orderStep ?? widget.product.orderStep;
    final minOrderQty = cartItem?.minOrderQty ?? widget.product.minOrderQty;
    final unit = cartItem?.unit ?? widget.product.unit;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/product/${widget.product.id}'),
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: imageProvider != null
                        ? Image(image: imageProvider, fit: BoxFit.cover, width: double.infinity)
                        : Container(
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.image,
                                size: 36, color: Colors.grey),
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
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.clearSnackBars();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to manage your wishlist.'),
                            duration: Duration(seconds: 3),
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
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: isWishlisted
                            ? const Color(0xFFE53935)
                            : const Color(0xFF888888),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF216140),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.product.sectionProductLabel
                              .toLowerCase()
                              .contains('organic'))
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
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // ── Price + MRP + discount ──
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹${widget.product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w800),
                          ),
                          if (widget.product.mrp > widget.product.price &&
                              widget.product.mrp > 0 &&
                              widget.product.price < 1000) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${widget.product.mrp.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                          if (widget.product.mrp > widget.product.price &&
                              widget.product.mrp > 0) ...[
                            const SizedBox(width: 4),
                            Builder(builder: (context) {
                              final disc = widget.product.discountPercentage > 0
                                  ? widget.product.discountPercentage.round()
                                  : (((widget.product.mrp - widget.product.price) /
                                              widget.product.mrp) *
                                          100)
                                      .round();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0c831f),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$disc% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),

                    // Unit label (only show when not in cart, as it's inside the qty box otherwise)
                    if (cartItem == null && unit != null && unit.isNotEmpty)
                      Text(
                        unit,
                        style: const TextStyle(
                            color: Color(0xFF164431),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),

                    const Spacer(),

                    // ── Bottom action ──
                    if (isOutOfStock)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Center(
                          child: Text('Out of stock',
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold)),
                        ),
                      )
                    else if (cartItem != null)
                      // In cart: full-width [- qty +]
                      _QtyControl(
                        quantity: cartItem.quantity,
                        unit: unit ?? '',
                        loading: _loading,
                        formatQty: _formatQty,
                        onAdd: () =>
                            _handleIncrement(cart, cartItem.quantity, orderStep),
                        onRemove: () => _handleDecrement(
                            cart, cartItem.quantity, orderStep, minOrderQty),
                        fullWidth: true,
                      )
                    else
                      // Not in cart: full-width ADD button
                      GestureDetector(
                        onTap: _loading ? null : () => _handleAdd(cart),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFF164431), width: 1.5),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                            child: Text('ADD',
                                    style: TextStyle(
                                      color: _loading ? Colors.grey : const Color(0xFF164431),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    )),
                          ),
                        ),
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
  final String unit;

  final bool fullWidth;

  const _QtyControl({
    required this.quantity,
    required this.loading,
    required this.formatQty,
    required this.onAdd,
    required this.onRemove,
    this.unit = '',
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // Consume tap to prevent opening detail page
      child: Container(
        decoration: BoxDecoration(
        color: const Color(0xFF164431),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: fullWidth
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: loading ? null : onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.remove, size: 18, color: loading ? Colors.white54 : Colors.white),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${formatQty(quantity)}${unit.isNotEmpty ? ' $unit' : ''}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: loading ? null : onAdd,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add, size: 18, color: loading ? Colors.white54 : Colors.white),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
