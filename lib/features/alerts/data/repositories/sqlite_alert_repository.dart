import '../../../../core/database/database_helper.dart';
import '../../domain/models/alert.dart';
import '../../domain/repositories/alert_repository.dart';

class SqliteAlertRepository implements AlertRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<List<AppAlert>> getRecentAlerts() async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      DatabaseHelper.tableAlerts,
      orderBy: 'created_at DESC',
      limit: 20,
    );
    return rows.map((r) => AppAlert.fromMap(r)).toList();
  }

  @override
  Future<AppAlert> insertAlert(AppAlert alert) async {
    final map = alert.toMap();
    map.remove('id');
    final id = await _dbHelper.insert(DatabaseHelper.tableAlerts, map);
    
    return alert.copyWith(id: id);
  }

  @override
  Future<bool> hasAlertBeenSentToday(String type) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final String dateString = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final rows = await db.query(
      DatabaseHelper.tableAlerts,
      where: 'type = ? AND created_at >= ? AND created_at <= ?',
      whereArgs: [type, "${dateString}T00:00:00.000", "${dateString}T23:59:59.999"],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> markAllAsRead() async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseHelper.tableAlerts,
      {'is_read': 1},
      where: 'is_read = 0',
    );
  }
}
