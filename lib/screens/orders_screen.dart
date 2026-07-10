import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'main_shell.dart';
import 'order_detail_screen.dart';

void _showReviewDialog(BuildContext context, Order order, VoidCallback onSubmitted) {
  int rating = 5;
  final commentCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Write a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order: ${order.orderNumber}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
            const SizedBox(height: 16),
            const Text('Rating', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    star <= rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFC107),
                    size: 36,
                  ),
                  onPressed: () => setDialogState(() => rating = star),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.createReview(
                  orderId: order.id,
                  rating: rating,
                  comment: commentCtrl.text.isNotEmpty ? commentCtrl.text : null,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  onSubmitted();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Review submitted!'), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF164431)),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All Orders', 'Active', 'Delivered', 'Cancelled'];
  late Future<List<Order>> _ordersFuture;
  User? _lastUser;

  @override
  void initState() {
    super.initState();
    _ordersFuture = Future.value(<Order>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().user;
    if (user != _lastUser) {
      _lastUser = user;
      if (user != null) {
        _ordersFuture = ApiService.fetchOrders();
      }
    }
  }

  void _refreshOrders() {
    setState(() {
      _ordersFuture = ApiService.fetchOrders();
    });
  }

  Future<void> _handleReorder(Order order) async {
    final cart = context.read<CartProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF164431))),
    );
    try {
      for (final item in order.items) {
        await cart.addToBackend(item, quantity: item.quantity);
      }
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order items added to cart!'), behavior: SnackBarBehavior.floating),
        );
        MainShell.switchTab(context, 2);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reorder: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _handleCancel(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${order.orderNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.cancelOrder(order.id);
      _refreshOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222))),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
        centerTitle: false,
      ),
      body: user == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Please log in to view your orders', style: TextStyle(fontSize: 16, color: Color(0xFF444444), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/auth'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF164431),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Log In'),
                  ),
                ],
              ),
            )
          : FutureBuilder<List<Order>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 56, color: Color(0xFF999999)),
                    const SizedBox(height: 16),
                    const Text('Could not load orders', style: TextStyle(fontSize: 16, color: Color(0xFF444444), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _refreshOrders,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF164431), foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          }

          final allOrders = snapshot.data ?? [];

          final filteredOrders = allOrders.where((o) {
            if (_selectedFilterIndex == 0) return true;
            if (_selectedFilterIndex == 1) return o.status == 'PENDING' || o.status == 'CONFIRMED' || o.status == 'OUT_FOR_DELIVERY';
            if (_selectedFilterIndex == 2) return o.status == 'DELIVERED';
            if (_selectedFilterIndex == 3) return o.status == 'CANCELLED';
            return true;
          }).toList();

          return Column(
            children: [
              _buildFilters(),
              const SizedBox(height: 16),
              Expanded(
                child: filteredOrders.isEmpty
                    ? const Center(child: Text('No orders found', style: TextStyle(color: Colors.grey)))
                    : RefreshIndicator(
                        onRefresh: () async => _refreshOrders(),
                        color: const Color(0xFF164431),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredOrders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _OrderCard(
                              order: filteredOrders[index],
                              onReorder: () => _handleReorder(filteredOrders[index]),
                              onCancel: () => _handleCancel(filteredOrders[index]),
                              onReview: () => _showReviewDialog(context, filteredOrders[index], _refreshOrders),
                              onRefresh: _refreshOrders,
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilterIndex = index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF164431) : const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                _filters[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF444444),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onReorder;
  final VoidCallback onCancel;
  final VoidCallback onReview;
  final VoidCallback onRefresh;

  const _OrderCard({
    required this.order,
    required this.onReorder,
    required this.onCancel,
    required this.onReview,
    required this.onRefresh,
  });

  String get _formattedDate {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(order.createdAt).toLocal());
    } catch (_) {
      return order.createdAt;
    }
  }

  String get _statusText {
    switch (order.status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return order.status;
    }
  }

  Color get _statusBgColor {
    switch (order.status) {
      case 'PENDING': return const Color(0xFFF3F4F6);
      case 'CONFIRMED': return const Color(0xFFEFF6FF);
      case 'OUT_FOR_DELIVERY': return const Color(0xFFFEF3C7);
      case 'DELIVERED': return const Color(0xFFD1FAE5);
      case 'CANCELLED': return const Color(0xFFFEE2E2);
      default: return const Color(0xFFF3F4F6);
    }
  }

  Color get _statusTextColor {
    switch (order.status) {
      case 'PENDING': return const Color(0xFF4B5563);
      case 'CONFIRMED': return const Color(0xFF1D4ED8);
      case 'OUT_FOR_DELIVERY': return const Color(0xFFB45309);
      case 'DELIVERED': return const Color(0xFF047857);
      case 'CANCELLED': return const Color(0xFFB91C1C);
      default: return const Color(0xFF4B5563);
    }
  }

  bool get _canCancel => order.status == 'PENDING' || order.status == 'CONFIRMED';
  bool get _canReview => order.status == 'DELIVERED';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailScreen(
              order: order,
              onRefresh: onRefresh,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                    ),
                    const SizedBox(height: 4),
                    Text(_formattedDate,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (order.status == 'DELIVERED') ...[
                        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF047857)),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _statusText,
                        style: TextStyle(color: _statusTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (order.deliveryAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF888888)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(order.deliveryAddress,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (order.items.isNotEmpty) ...[
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: order.items.length > 3 ? 3 : order.items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    final qtyStr = item.quantity.truncateToDouble() == item.quantity
                        ? item.quantity.toInt().toString()
                        : item.quantity.toString();
                    final unitStr = item.unit != null && item.unit!.isNotEmpty ? ' ${item.unit}' : '';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${item.name} x$qtyStr$unitStr',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF444444))),
                    );
                  },
                ),
              ),
              if (order.items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('+${order.items.length - 3} more items',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                    Text('₹${order.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(color: Color(0xFF164431), fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(
                            order: order,
                            onRefresh: onRefresh,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Order Details', style: TextStyle(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF164431),
                      side: const BorderSide(color: Color(0xFF164431)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (_canReview) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: order.review == null
                        ? ElevatedButton.icon(
                            onPressed: onReview,
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text('Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[50],
                              foregroundColor: Colors.amber[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber[100]!),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 18, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${order.review!.rating}.0',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.amber[700]),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
                if (!_canReview) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReorder,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reorder', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF164431),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
