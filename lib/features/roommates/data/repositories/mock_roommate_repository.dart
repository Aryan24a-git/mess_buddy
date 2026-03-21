import '../../domain/models/roommate.dart';
import '../../domain/repositories/roommate_repository.dart';

class MockRoommateRepository implements RoommateRepository {
  final List<Roommate> _roommates = [
    Roommate(id: 1, name: 'Aryan Sharma', phone: '+91 9876543210', createdAt: DateTime.now().subtract(const Duration(days: 30))),
    Roommate(id: 2, name: 'Rahul Verma', phone: '+91 8765432109', createdAt: DateTime.now().subtract(const Duration(days: 20))),
    Roommate(id: 3, name: 'Karan Singh', phone: '+91 7654321098', createdAt: DateTime.now().subtract(const Duration(days: 10))),
  ];
  int _nextId = 4;

  @override
  Future<Roommate> addRoommate(Roommate roommate) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newRoommate = roommate.copyWith(id: _nextId++);
    _roommates.add(newRoommate);
    return newRoommate;
  }

  @override
  Future<int> deleteRoommate(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _roommates.removeWhere((r) => r.id == id);
    return 1;
  }

  @override
  Future<List<Roommate>> getRoommates() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_roommates);
  }

  @override
  Future<int> updateRoommate(Roommate roommate) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _roommates.indexWhere((r) => r.id == roommate.id);
    if (index != -1) {
      _roommates[index] = roommate;
      return 1;
    }
    return 0;
  }
}
