import '../../domain/models/mess_session.dart';

abstract class MessRepository {
  Future<List<MessSession>> getSessionsForDate(DateTime date);
  Future<List<MessSession>> getSessionsBetweenDates(DateTime start, DateTime end);
  Future<MessSession> addSession(MessSession session);
  Future<int> updateSession(MessSession session);
  Future<int> deleteSession(int id);
}
