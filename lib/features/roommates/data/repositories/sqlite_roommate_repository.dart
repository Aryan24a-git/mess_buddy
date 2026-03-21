import '../../../../core/database/database_helper.dart';
import '../../domain/models/roommate.dart';
import '../../domain/repositories/roommate_repository.dart';

class SqliteRoommateRepository implements RoommateRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  Future<Roommate> addRoommate(Roommate roommate) async {
    final map = roommate.toMap();
    map.remove('id'); // Remove ID so SQLite auto-increments
    final id = await _dbHelper.insert(DatabaseHelper.tableRoommates, map);
    return roommate.copyWith(id: id);
  }

  @override
  Future<int> deleteRoommate(int id) async {
    return await _dbHelper.delete(DatabaseHelper.tableRoommates, id);
  }

  @override
  Future<List<Roommate>> getRoommates() async {
    final rows = await _dbHelper.queryAllRows(DatabaseHelper.tableRoommates);
    return rows.map((row) => Roommate.fromMap(row)).toList();
  }

  @override
  Future<int> updateRoommate(Roommate roommate) async {
    return await _dbHelper.update(DatabaseHelper.tableRoommates, roommate.toMap());
  }
}
