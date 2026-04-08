class AppAlert {
  final int? id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'low_balance', 'overspending', 'inactivity', 'daily_limit_warning', 'daily_limit_exceeded'
  final bool isRead;

  AppAlert({
    this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AppAlert.fromMap(Map<String, dynamic> map) {
    return AppAlert(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
      type: map['type'],
      isRead: (map['is_read'] ?? 0) == 1,
    );
  }

  AppAlert copyWith({
    int? id,
    String? title,
    String? message,
    DateTime? createdAt,
    String? type,
    bool? isRead,
  }) {
    return AppAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}
