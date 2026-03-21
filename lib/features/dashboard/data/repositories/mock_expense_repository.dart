import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [
    Expense(
      id: 1,
      title: 'Groceries (Milk, Eggs)',
      amount: 450.0,
      payerId: 1,
      category: 'Food',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: 2,
      title: 'Hostel Rent Split',
      amount: 4000.0,
      payerId: 2, // Someone else paid
      category: 'Rent',
      date: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Expense(
      id: 3,
      title: 'Dinner at Mess (Guest)',
      amount: 160.0,
      payerId: 1,
      category: 'Mess',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Expense(
      id: 4,
      title: 'Stationery',
      amount: 120.0,
      payerId: 1,
      category: 'Other',
      date: DateTime.now().subtract(const Duration(days: 6)),
    ),
  ];
  int _nextId = 5;

  @override
  Future<Expense> addExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newExpense = expense.copyWith(id: _nextId++);
    _expenses.add(newExpense);
    return newExpense;
  }

  @override
  Future<int> deleteExpense(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _expenses.removeWhere((e) => e.id == id);
    return 1;
  }

  @override
  Future<List<Expense>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_expenses.reversed); // standard reverse chronological return
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense;
      return 1;
    }
    return 0;
  }
}
