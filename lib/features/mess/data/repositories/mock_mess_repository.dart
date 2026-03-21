import '../../domain/models/mess_session.dart';
import '../../domain/repositories/mess_repository.dart';

class MockMessRepository implements MessRepository {
  final List<MessSession> _sessions = [
    MessSession(
      id: 1,
      sessionDate: DateTime.now(),
      sessionType: 'Breakfast',
      status: 'Attended',
      sessionCost: 40.0,
    ),
    MessSession(
      id: 2,
      sessionDate: DateTime.now(),
      sessionType: 'Lunch',
      status: 'Attended',
      sessionCost: 60.0,
    ),
    MessSession(
      id: 3,
      sessionDate: DateTime.now(),
      sessionType: 'Dinner',
      status: 'Skipped',
      sessionCost: 0.0,
    ),
  ];
  int _nextId = 4;

  @override
  Future<MessSession> addSession(MessSession session) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newSession = session.copyWith(id: _nextId++);
    _sessions.add(newSession);
    return newSession;
  }

  @override
  Future<int> deleteSession(int id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _sessions.removeWhere((s) => s.id == id);
    return 1;
  }

  @override
  Future<List<MessSession>> getSessionsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _sessions.where((s) => 
      s.sessionDate.year == date.year && 
      s.sessionDate.month == date.month && 
      s.sessionDate.day == date.day
    ).toList();
  }

  @override
  Future<int> updateSession(MessSession session) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
      return 1;
    }
    return 0;
  }
}
