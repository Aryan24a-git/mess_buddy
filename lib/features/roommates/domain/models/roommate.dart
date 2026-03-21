class Roommate {
  final int? id;
  final String name;
  final String phone;
  final DateTime createdAt;

  Roommate({
    this.id,
    required this.name,
    this.phone = '',
    required this.createdAt,
  });

  Roommate copyWith({
    int? id,
    String? name,
    String? phone,
    DateTime? createdAt,
  }) {
    return Roommate(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Roommate.fromMap(Map<String, dynamic> map) {
    return Roommate(
      id: map['id'],
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
