import 'cart_item.dart';

class Order {
  final int id;
  final String orderNumber;
  final String status;
  final String deliveryAddress;
  final double subtotal;
  final double deliveryCharge;
  final double totalAmount;
  final bool isPaid;
  final String paymentMethod;
  final String deliverySlot;
  final String createdAt;
  final String? deliveryLatitude;
  final String? deliveryLongitude;
  final List<CartItem> items;

  Order({
    required this.id,
    required this.orderNumber,
    this.status = 'PENDING',
    this.deliveryAddress = '',
    this.subtotal = 0.0,
    this.deliveryCharge = 0.0,
    this.totalAmount = 0.0,
    this.isPaid = false,
    this.paymentMethod = 'COD',
    this.deliverySlot = '',
    this.createdAt = '',
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.items = const [],
  });

  String get statusDisplay {
    switch (status) {
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      status: json['status'] ?? 'PENDING',
      deliveryAddress: json['delivery_address'] ?? '',
      subtotal: _toDouble(json['subtotal']),
      deliveryCharge: _toDouble(json['delivery_charge']),
      totalAmount: _toDouble(json['total_amount']),
      isPaid: json['is_paid'] ?? false,
      paymentMethod: json['payment_method'] ?? 'COD',
      deliverySlot: json['delivery_slot'] ?? '',
      createdAt: json['created_at'] ?? '',
      deliveryLatitude: json['delivery_latitude']?.toString(),
      deliveryLongitude: json['delivery_longitude']?.toString(),
      items: (json['items'] as List?)
              ?.map((i) => CartItem.fromJson(i))
              .toList() ??
          [],
    );
  }
}
