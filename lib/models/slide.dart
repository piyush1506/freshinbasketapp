class Slide {
  final int id;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String? link;
  final int order;
  final bool isActive;

  Slide({
    required this.id,
    this.imageUrl,
    this.title = '',
    this.subtitle = '',
    this.link,
    this.order = 0,
    this.isActive = true,
  });

  factory Slide.fromJson(Map<String, dynamic> json) {
    return Slide(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      link: json['link'],
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}
