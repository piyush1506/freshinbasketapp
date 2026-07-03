import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'main_shell.dart';

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
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(order.createdAt));
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
        showDialog(
          context: context,
          builder: (ctx) => OrderDetailDialog(
            order: order,
            onRefresh: onRefresh,
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
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${item.name} x$qtyStr',
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
                      showDialog(
                        context: context,
                        builder: (ctx) => OrderDetailDialog(
                          order: order,
                          onRefresh: onRefresh,
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

class OrderDetailDialog extends StatefulWidget {
  final Order order;
  final VoidCallback onRefresh;

  const OrderDetailDialog({
    super.key,
    required this.order,
    required this.onRefresh,
  });

  @override
  State<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends State<OrderDetailDialog> {
  late Order _currentOrder;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _editAddress() async {
    final addressCtrl = TextEditingController(text: _currentOrder.deliveryAddress);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Delivery Address'),
        content: TextField(
          controller: addressCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter new delivery address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF164431)),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && addressCtrl.text.trim().isNotEmpty) {
      setState(() => _updating = true);
      try {
        await ApiService.updateOrderAddress(
          orderId: _currentOrder.id,
          deliveryAddress: addressCtrl.text.trim(),
        );
        setState(() {
          _currentOrder = Order(
            id: _currentOrder.id,
            orderNumber: _currentOrder.orderNumber,
            status: _currentOrder.status,
            deliveryAddress: addressCtrl.text.trim(),
            subtotal: _currentOrder.subtotal,
            deliveryCharge: _currentOrder.deliveryCharge,
            totalAmount: _currentOrder.totalAmount,
            isPaid: _currentOrder.isPaid,
            paymentMethod: _currentOrder.paymentMethod,
            deliverySlot: _currentOrder.deliverySlot,
            createdAt: _currentOrder.createdAt,
            deliveryLatitude: _currentOrder.deliveryLatitude,
            deliveryLongitude: _currentOrder.deliveryLongitude,
            items: _currentOrder.items,
          );
          _updating = false;
        });
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address updated successfully!'), backgroundColor: Color(0xFF164431), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        setState(() => _updating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update address: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${_currentOrder.orderNumber}?'),
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

    if (confirmed == true) {
      setState(() => _updating = true);
      try {
        await ApiService.cancelOrder(_currentOrder.id);
        setState(() {
          _currentOrder = Order(
            id: _currentOrder.id,
            orderNumber: _currentOrder.orderNumber,
            status: 'CANCELLED',
            deliveryAddress: _currentOrder.deliveryAddress,
            subtotal: _currentOrder.subtotal,
            deliveryCharge: _currentOrder.deliveryCharge,
            totalAmount: _currentOrder.totalAmount,
            isPaid: _currentOrder.isPaid,
            paymentMethod: _currentOrder.paymentMethod,
            deliverySlot: _currentOrder.deliverySlot,
            createdAt: _currentOrder.createdAt,
            deliveryLatitude: _currentOrder.deliveryLatitude,
            deliveryLongitude: _currentOrder.deliveryLongitude,
            items: _currentOrder.items,
          );
          _updating = false;
        });
        widget.onRefresh();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully!'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        setState(() => _updating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusLabel = _currentOrder.status;
    Color statusBg = Colors.grey[200]!;
    Color statusText = Colors.grey[700]!;
    switch (_currentOrder.status) {
      case 'PENDING':
        statusLabel = 'Pending';
        statusBg = const Color(0xFFF3F4F6);
        statusText = const Color(0xFF4B5563);
        break;
      case 'CONFIRMED':
        statusLabel = 'Confirmed';
        statusBg = const Color(0xFFEFF6FF);
        statusText = const Color(0xFF1D4ED8);
        break;
      case 'OUT_FOR_DELIVERY':
        statusLabel = 'Out for Delivery';
        statusBg = const Color(0xFFFEF3C7);
        statusText = const Color(0xFFB45309);
        break;
      case 'DELIVERED':
        statusLabel = 'Delivered';
        statusBg = const Color(0xFFD1FAE5);
        statusText = const Color(0xFF047857);
        break;
      case 'CANCELLED':
        statusLabel = 'Cancelled';
        statusBg = const Color(0xFFFEE2E2);
        statusText = const Color(0xFFB91C1C);
        break;
    }

    String paymentLabel = 'Unpaid';
    Color paymentBg = const Color(0xFFFEF3C7);
    Color paymentText = const Color(0xFFB45309);
    if (_currentOrder.isPaid) {
      paymentLabel = 'Paid';
      paymentBg = const Color(0xFFD1FAE5);
      paymentText = const Color(0xFF047857);
    } else if (_currentOrder.paymentMethod == 'COD') {
      paymentLabel = 'Cash on Delivery';
      paymentBg = const Color(0xFFF3F4F6);
      paymentText = const Color(0xFF4B5563);
    }

    double totalTax = 0.0;
    for (final item in _currentOrder.items) {
      totalTax += (item.price * item.quantity) * (item.taxPercentage / 100);
    }

    final formattedDate = _formattedDateString(_currentOrder.createdAt);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _currentOrder.orderNumber.isNotEmpty
                            ? 'Order #${_currentOrder.orderNumber}'
                            : 'Order #${_currentOrder.id}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(statusLabel, style: TextStyle(color: statusText, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: paymentBg, borderRadius: BorderRadius.circular(12)),
                      child: Text(paymentLabel, style: TextStyle(color: paymentText, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF444444))),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: _currentOrder.items.map((item) {
                      final qtyStr = item.quantity.truncateToDouble() == item.quantity
                          ? item.quantity.toInt().toString()
                          : item.quantity.toString();
                      return ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text('$qtyStr * ${item.unit ?? "kg"}'),
                        trailing: Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF444444))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _row('Subtotal', '₹${_currentOrder.subtotal.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      _row(
                        'Delivery Charge',
                        _currentOrder.deliveryCharge == 0.0 ? 'FREE' : '₹${_currentOrder.deliveryCharge.toStringAsFixed(2)}',
                        isDelivery: true,
                      ),
                      if (totalTax > 0) ...[
                        const SizedBox(height: 6),
                        _row('Tax', '₹${totalTax.toStringAsFixed(2)}'),
                      ],
                      const Divider(height: 16),
                      _row('Total', '₹${_currentOrder.totalAmount.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF444444))),
                    if (_currentOrder.status == 'PENDING' || _currentOrder.status == 'CONFIRMED')
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF164431)),
                        onPressed: _editAddress,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    _currentOrder.deliveryAddress,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('Placed: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() => _updating = true);
                          try {
                            final cart = context.read<CartProvider>();
                            for (final item in _currentOrder.items) {
                              await cart.addToBackend(item, quantity: item.quantity);
                            }
                            if (mounted) {
                              Navigator.pop(context); // Dismiss dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order items added to cart!'), behavior: SnackBarBehavior.floating),
                              );
                              MainShell.switchTab(context, 2);
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _updating = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to reorder: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF164431),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Reorder'),
                      ),
                    ),
                    if (_currentOrder.status == 'PENDING' || _currentOrder.status == 'CONFIRMED') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelOrder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel Order'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (_updating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator(color: Color(0xFF164431))),
              ),
            ),
        ],
      ),
    );
  }

  String _formattedDateString(String dateStr) {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  Widget _row(String label, String value, {bool isBold = false, bool isDelivery = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey[600], fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(
          value,
          style: TextStyle(
            color: isDelivery && value == 'FREE' ? Colors.green : Colors.black,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 15 : 13,
          ),
        ),
      ],
    );
  }
}
