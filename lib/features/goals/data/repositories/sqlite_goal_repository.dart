import '../../../../core/database/database_helper.dart';
import '../../domain/models/goal.dart';
import '../../domain/repositories/goal_repository.dart';

class SqliteGoalRepository implements GoalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<Goal> addGoal(Goal goal) async {
    final map = goal.toMap();
    map.remove('id');
    final id = await _dbHelper.insert(DatabaseHelper.tableGoals, map);
    return goal.copyWith(id: id);
  }

  @override
  Future<int> deleteGoal(int id) async {
    return await _dbHelper.delete(DatabaseHelper.tableGoals, id);
  }

  @override
  Future<List<Goal>> getGoals() async {
    final db = await _dbHelper.database;
    final rows = await db.query(DatabaseHelper.tableGoals, orderBy: 'created_at DESC');
    return rows.map((row) => Goal.fromMap(row)).toList();
  }

  @override
  Future<int> updateGoal(Goal goal) async {
    return await _dbHelper.update(DatabaseHelper.tableGoals, goal.toMap());
  }
}
