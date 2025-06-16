class BadgeModel {
  final String code;
  final String title;
  final String description;
  final String iconUrl;
  final String color;
  final DateTime? earnedAt;

  BadgeModel({
    required this.code,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.color,
    this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      code: json['code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      color: json['color'] ?? '',
      earnedAt: json['earnedAt'] != null ? DateTime.tryParse(json['earnedAt']) : null,
    );
  }
} 