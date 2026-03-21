class MessSession {
  final int? id;
  final DateTime sessionDate;
  final String sessionType;
  final String status;
  final double sessionCost;

  MessSession({
    this.id,
    required this.sessionDate,
    required this.sessionType,
    required this.status,
    required this.sessionCost,
  });

  MessSession copyWith({
    int? id,
    DateTime? sessionDate,
    String? sessionType,
    String? status,
    double? sessionCost,
  }) {
    return MessSession(
      id: id ?? this.id,
      sessionDate: sessionDate ?? this.sessionDate,
      sessionType: sessionType ?? this.sessionType,
      status: status ?? this.status,
      sessionCost: sessionCost ?? this.sessionCost,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_date': sessionDate.toIso8601String(),
      'session_type': sessionType,
      'status': status,
      'session_cost': sessionCost,
    };
  }

  factory MessSession.fromMap(Map<String, dynamic> map) {
    return MessSession(
      id: map['id'],
      sessionDate: DateTime.parse(map['session_date']),
      sessionType: map['session_type'] ?? '',
      status: map['status'] ?? '',
      sessionCost: map['session_cost']?.toDouble() ?? 0.0,
    );
  }
}
