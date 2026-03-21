class AppAlert {
  final int? id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String type; // 'low_balance', 'overspending', 'inactivity'

  AppAlert({
    this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'type': type,
    };
  }

  factory AppAlert.fromMap(Map<String, dynamic> map) {
    return AppAlert(
      id: map['id'],
      title: map['title'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
      type: map['type'],
    );
  }
}
