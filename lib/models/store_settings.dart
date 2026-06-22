class StoreSettings {
  final double freeDeliveryThreshold;
  final double deliveryCharge;

  StoreSettings({
    this.freeDeliveryThreshold = 100.0,
    this.deliveryCharge = 50.0,
  });

  static double _toDouble(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      freeDeliveryThreshold:
          _toDouble(json['free_delivery_threshold'], 100.0),
      deliveryCharge:
          _toDouble(json['delivery_charge'], 50.0),
    );
  }
}
