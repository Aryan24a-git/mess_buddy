enum SavingRatePeriod { daily, weekly, monthly }

class Goal {
  final int? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final double savingRate;
  final SavingRatePeriod ratePeriod;
  final DateTime createdAt;

  Goal({
    this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.savingRate,
    required this.ratePeriod,
    required this.createdAt,
  });

  Goal copyWith({
    int? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    double? savingRate,
    SavingRatePeriod? ratePeriod,
    DateTime? createdAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      savingRate: savingRate ?? this.savingRate,
      ratePeriod: ratePeriod ?? this.ratePeriod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'saving_rate': savingRate,
      'rate_period': ratePeriod.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'],
      title: map['title'],
      targetAmount: map['target_amount']?.toDouble() ?? 0.0,
      currentAmount: map['current_amount']?.toDouble() ?? 0.0,
      savingRate: map['saving_rate']?.toDouble() ?? 0.0,
      ratePeriod: SavingRatePeriod.values.byName(map['rate_period'] ?? 'monthly'),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Calculation Logic
  double get progressPercentage => (currentAmount / targetAmount).clamp(0.0, 1.0);
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, targetAmount);

  String get estimatedTimeToReach {
    if (savingRate <= 0) return "Never";
    
    final remaining = remainingAmount;
    final units = remaining / savingRate;
    
    if (units <= 0) return "Completed!";
    
    int roundedUnits = units.ceil();
    String periodStr = "";
    switch (ratePeriod) {
      case SavingRatePeriod.daily:
        periodStr = roundedUnits == 1 ? "day" : "days";
        break;
      case SavingRatePeriod.weekly:
        periodStr = roundedUnits == 1 ? "week" : "weeks";
        break;
      case SavingRatePeriod.monthly:
        periodStr = roundedUnits == 1 ? "month" : "months";
        break;
    }
    
    return "$roundedUnits $periodStr";
  }
}
