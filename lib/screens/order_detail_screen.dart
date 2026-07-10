import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'main_shell.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final VoidCallback onRefresh;

  const OrderDetailScreen({
    super.key,
    required this.order,
    required this.onRefresh,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
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

  String _formattedDateString(String dateStr) {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return dateStr;
    }
  }

  Widget _row(String label, String value, {bool isBold = false, bool isDelivery = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.black : Colors.grey[600], fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              color: isDelivery && value == 'FREE' ? Colors.green : Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8F5),
      appBar: AppBar(
        title: Text(
          _currentOrder.orderNumber.isNotEmpty
              ? 'Order #${_currentOrder.orderNumber}'
              : 'Order #${_currentOrder.id}',
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF222222)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF222222)),
        actions: [
          if (_currentOrder.status == 'PENDING' || _currentOrder.status == 'CONFIRMED')
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'cancel') {
                  _cancelOrder();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'cancel',
                  child: Text('Cancel Order', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(16)),
                      child: Text(statusLabel, style: TextStyle(color: statusText, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: paymentBg, borderRadius: BorderRadius.circular(16)),
                      child: Text(paymentLabel, style: TextStyle(color: paymentText, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF444444))),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: _currentOrder.items.map((item) {
                      final qtyStr = item.quantity.truncateToDouble() == item.quantity
                          ? item.quantity.toInt().toString()
                          : item.quantity.toString();
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: item.image != null
                                ? CachedNetworkImage(
                                    imageUrl: item.image!.startsWith('http')
                                        ? item.image!
                                        : '${ApiService.baseUrl}${item.image}',
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.image, color: Colors.grey, size: 28),
                          ),
                        ),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('$qtyStr ${item.unit ?? "kg"}'),
                        trailing: Text(
                          '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF444444))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      _row('Subtotal', '₹${_currentOrder.subtotal.toStringAsFixed(2)}'),
                      _row(
                        'Delivery Charge',
                        _currentOrder.deliveryCharge == 0.0 ? 'FREE' : '₹${_currentOrder.deliveryCharge.toStringAsFixed(2)}',
                        isDelivery: true,
                      ),
                      if (totalTax > 0)
                        _row('Tax', '₹${totalTax.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _row('Total', '₹${_currentOrder.totalAmount.toStringAsFixed(2)}', isBold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF444444))),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    _currentOrder.deliveryAddress,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('Placed: $formattedDate', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 100), // padding for bottom buttons
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
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
                        Navigator.pop(context); // Go back
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reorder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
