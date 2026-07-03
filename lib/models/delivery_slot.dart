class DeliverySlot {
  final int id;
  final String name;
  final String displayLabel;
  final bool isActive;
  final int sortOrder;

  DeliverySlot({
    required this.id,
    required this.name,
    this.displayLabel = '',
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory DeliverySlot.fromJson(Map<String, dynamic> json) {
    return DeliverySlot(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      displayLabel: json['display_label'] ?? json['name'] ?? '',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
