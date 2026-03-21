import '../../../../core/database/database_helper.dart';
import '../../domain/models/mess_session.dart';
import '../../domain/repositories/mess_repository.dart';

class SqliteMessRepository implements MessRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<MessSession> addSession(MessSession session) async {
    final map = session.toMap();
    map.remove('id');
    final id = await _dbHelper.insert(DatabaseHelper.tableMessSessions, map);
    return session.copyWith(id: id);
  }

  @override
  Future<int> deleteSession(int id) async {
    return await _dbHelper.delete(DatabaseHelper.tableMessSessions, id);
  }

  @override
  Future<List<MessSession>> getSessionsForDate(DateTime date) async {
    final db = await _dbHelper.database;
    // Simple filter in SQL (SQLite datetime functions might be needed for robust date matching)
    // Here we fetch all and filter in Dart for simplicity, usually you'd format the date via query
    final String dateString = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final rows = await db.query(
      DatabaseHelper.tableMessSessions,
      where: "session_date LIKE ?",
      whereArgs: ["$dateString%"], 
    );
    return rows.map((row) => MessSession.fromMap(row)).toList();
  }

  @override
  Future<int> updateSession(MessSession session) async {
    return await _dbHelper.update(DatabaseHelper.tableMessSessions, session.toMap());
  }
}
