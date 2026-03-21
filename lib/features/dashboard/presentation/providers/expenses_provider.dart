import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/mock_expense_repository.dart';
import '../../data/repositories/sqlite_expense_repository.dart';

// Provider for the repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  if (kIsWeb) {
    return MockExpenseRepository();
  }
  return SqliteExpenseRepository();
});

// StateNotifier for the expenses list
class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpensesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final expenses = await _repository.getExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      await loadExpenses(); 
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses(); 
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for the ExpensesNotifier
final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesNotifier(repository);
});
