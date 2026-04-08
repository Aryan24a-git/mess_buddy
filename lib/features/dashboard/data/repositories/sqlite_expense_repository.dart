import '../../../../core/database/database_helper.dart';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class SqliteExpenseRepository implements ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<Expense> addExpense(Expense expense) async {
    final map = expense.toMap();
    map.remove('id');
    final id = await _dbHelper.insert(DatabaseHelper.tableExpenses, map);
    return expense.copyWith(id: id);
  }

  @override
  Future<int> deleteExpense(int id) async {
    return await _dbHelper.delete(DatabaseHelper.tableExpenses, id);
  }

  @override
  Future<List<Expense>> getExpenses() async {
    final rows = await _dbHelper.queryAllRows(DatabaseHelper.tableExpenses);
    return rows.map((row) => Expense.fromMap(row)).toList();
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    return await _dbHelper.update(
      DatabaseHelper.tableExpenses,
      expense.toMap(),
    );
  }
}
