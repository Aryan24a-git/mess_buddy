class Expense {
  final int? id;
  final String title;
  final double amount;
  final int payerId;
  final String category;
  final DateTime date;

  final bool isSplit;
  final String? splitWith;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.payerId,
    required this.category,
    required this.date,
    this.isSplit = false,
    this.splitWith,
  });

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    int? payerId,
    String? category,
    DateTime? date,
    bool? isSplit,
    String? splitWith,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      payerId: payerId ?? this.payerId,
      category: category ?? this.category,
      date: date ?? this.date,
      isSplit: isSplit ?? this.isSplit,
      splitWith: splitWith ?? this.splitWith,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'payer_id': payerId,
      'category': category,
      'date': date.toIso8601String(),
      'is_split': isSplit ? 1 : 0,
      'split_with': splitWith,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'] ?? '',
      amount: map['amount']?.toDouble() ?? 0.0,
      payerId: map['payer_id'] ?? 0,
      category: map['category'] ?? '',
      date: DateTime.parse(map['date']),
      isSplit: (map['is_split'] ?? 0) == 1,
      splitWith: map['split_with'],
    );
  }
}

class ExpenseSplit {
  final int? id;
  final int expenseId;
  final int roommateId;
  final double amountOwed;
  final bool isSettled;

  ExpenseSplit({
    this.id,
    required this.expenseId,
    required this.roommateId,
    required this.amountOwed,
    this.isSettled = false,
  });

  ExpenseSplit copyWith({
    int? id,
    int? expenseId,
    int? roommateId,
    double? amountOwed,
    bool? isSettled,
  }) {
    return ExpenseSplit(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      roommateId: roommateId ?? this.roommateId,
      amountOwed: amountOwed ?? this.amountOwed,
      isSettled: isSettled ?? this.isSettled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_id': expenseId,
      'roommate_id': roommateId,
      'amount_owed': amountOwed,
      'is_settled': isSettled ? 1 : 0,
    };
  }

  factory ExpenseSplit.fromMap(Map<String, dynamic> map) {
    return ExpenseSplit(
      id: map['id'],
      expenseId: map['expense_id'] ?? 0,
      roommateId: map['roommate_id'] ?? 0,
      amountOwed: map['amount_owed']?.toDouble() ?? 0.0,
      isSettled: (map['is_settled'] ?? 0) == 1,
    );
  }
}
