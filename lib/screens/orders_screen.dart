import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/order.dart';

void _showReviewDialog(BuildContext context, Order order) {
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
  final List<String> _filters = ['All Orders', 'In Transit', 'Delivered', 'Cancelled'];
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ApiService.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222))),
        backgroundColor: const Color(0xFFF7F8F5),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF222222)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error.toString();
            if (error.contains('credentials') || error.contains('log in') || error.contains('session')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              });
              return const Center(child: CircularProgressIndicator());
            }
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          
          final allOrders = snapshot.data ?? [];
          
          final filteredOrders = allOrders.where((o) {
            if (_selectedFilterIndex == 0) return true;
            if (_selectedFilterIndex == 1) return o.status == 'OUT_FOR_DELIVERY' || o.status == 'CONFIRMED' || o.status == 'PENDING';
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
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _OrderCard(order: filteredOrders[index]);
                        },
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
            onTap: () {
              setState(() => _selectedFilterIndex = index);
            },
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

  const _OrderCard({required this.order});

  String get _formattedDate {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(order.createdAt));
    } catch (_) {
      return order.createdAt;
    }
  }

  // Determine status display and colors
  String get _statusText {
    if (order.status == 'DELIVERED') return 'Delivered';
    if (order.status == 'CANCELLED') return 'Cancelled';
    return 'In Transit';
  }

  Color get _statusBgColor {
    if (order.status == 'DELIVERED') return const Color(0xFFEBEBEB);
    if (order.status == 'CANCELLED') return const Color(0xFFFFCDD2);
    return const Color(0xFFFF7A6A);
  }

  Color get _statusTextColor {
    if (order.status == 'DELIVERED') return const Color(0xFF222222);
    if (order.status == 'CANCELLED') return const Color(0xFFD32F2F);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                    ),
                  ),
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
                    if (_statusText == 'Delivered') ...[
                      const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF222222)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildItemIcon(Icons.eco_outlined),
                  const SizedBox(width: 8),
                  _buildItemIcon(Icons.apple_outlined),
                  const SizedBox(width: 8),
                  if (order.items.length > 2) ...[
                    _buildItemIcon(Icons.water_drop_outlined),
                    const SizedBox(width: 12),
                    Text(
                      '+${order.items.length - 2} more',
                      style: const TextStyle(color: Color(0xFF444444), fontSize: 13),
                    ),
                  ] else ...[
                    const SizedBox(width: 12),
                    Text(
                      '${order.items.length} items',
                      style: const TextStyle(color: Color(0xFF444444), fontSize: 13),
                    ),
                  ],
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  Text(
                    '₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF164431),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {},
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
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  child: Text(
                    _statusText == 'Delivered' ? 'Details' : 'Track',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF222222), fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
          if (order.status == 'DELIVERED') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showReviewDialog(context, order),
                icon: const Icon(Icons.star_outline, size: 18),
                label: const Text('Write a Review', style: TextStyle(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFFFC107)),
                  foregroundColor: const Color(0xFF222222),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F8F5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF164431)),
    );
  }
}
