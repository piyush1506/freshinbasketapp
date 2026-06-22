import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _paymentMethod = 'COD';
  bool _processing = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _processing = true);
    try {
      if (_paymentMethod == 'COD') {
        await ApiService.createCODOrder(
          deliveryAddress: _addressCtrl.text.trim(),
        );
      } else {
        final orderData = await ApiService.createRazorpayOrder();
        if (mounted) {
          _initRazorpay(orderData);
          return;
        }
      }
      if (mounted) {
        context.read<CartProvider>().clearBackendCart();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'),
              backgroundColor: Color(0xFF164431),
              behavior: SnackBarBehavior.floating),
        );
        Navigator.pushReplacementNamed(context, '/main', arguments: 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
    if (mounted) setState(() => _processing = false);
  }

  void _initRazorpay(Map<String, dynamic> orderData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Razorpay integration - implement in production'),
          behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().user;
    if (_addressCtrl.text.isEmpty && user?.address != null) {
      _addressCtrl.text = user!.address!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Delivery Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter your delivery address',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _paymentOption('COD', 'Cash on Delivery',
              Icons.money, 'Pay when you receive'),
          _paymentOption('ONLINE', 'Online Payment',
              Icons.credit_card, 'Pay via Card/UPI/Net Banking'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Subtotal',
                      '₹${cart.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _row('Delivery Charge',
                      cart.deliveryCharge == 0
                          ? 'FREE'
                          : '₹${cart.deliveryCharge.toStringAsFixed(2)}'),
                  const Divider(height: 24),
                  _row('Total', '₹${cart.grandTotal.toStringAsFixed(2)}',
                      bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF164431),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _processing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _paymentMethod == 'COD'
                          ? 'Place Order (COD)'
                          : 'Pay ₹${cart.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(
      String value, String title, IconData icon, String subtitle) {
    final selected = _paymentMethod == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _paymentMethod = value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v!),
              activeColor: const Color(0xFF164431),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
            trailing: Icon(icon,
                color: selected
                    ? const Color(0xFF164431)
                    : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14)),
        Text(value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 14,
                color: bold ? const Color(0xFF164431) : null)),
      ],
    );
  }
}
