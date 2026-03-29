class CustomNotification {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final bool isActive;
  final String type;

  CustomNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.isActive,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'isActive': isActive,
        'type': type,
      };

  factory CustomNotification.fromJson(Map<String, dynamic> json) {
    return CustomNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      isActive: json['isActive'],
      type: json['type'],
    );
  }
}
