import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/mess_session.dart';
import '../../domain/repositories/mess_repository.dart';
import '../../data/repositories/mock_mess_repository.dart';
import '../../data/repositories/sqlite_mess_repository.dart';

// Provider for the repository
final messRepositoryProvider = Provider<MessRepository>((ref) {
  if (kIsWeb) {
    return MockMessRepository();
  }
  return SqliteMessRepository();
});

// StateNotifier for the specific date's mess sessions
class MessSessionsNotifier extends StateNotifier<AsyncValue<List<MessSession>>> {
  final MessRepository _repository;
  DateTime _currentDate = DateTime.now();

  MessSessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessionsForDate(_currentDate);
  }

  DateTime get currentDate => _currentDate;

  Future<void> loadSessionsForDate(DateTime date) async {
    _currentDate = date;
    try {
      state = const AsyncValue.loading();
      final sessions = await _repository.getSessionsForDate(date);
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSessionAttendance(String type, bool isAttending, double cost) async {
    final currentState = state.value;
    if (currentState == null) return;

    final existingIndex = currentState.indexWhere((s) => s.sessionType == type);
    MessSession session;

    if (existingIndex != -1) {
      session = currentState[existingIndex].copyWith(
        status: isAttending ? 'Attended' : 'Skipped',
        sessionCost: isAttending ? cost : 0,
      );
      try {
        await _repository.updateSession(session);
      } catch (e) {
        rethrow;
      }
    } else {
      session = MessSession(
        sessionDate: _currentDate,
        sessionType: type,
        status: isAttending ? 'Attended' : 'Skipped',
        sessionCost: isAttending ? cost : 0,
      );
      try {
        await _repository.addSession(session);
      } catch (e) {
        rethrow;
      }
    }
    // Reload state after DB mutate
    await loadSessionsForDate(_currentDate);
  }
}

// Provider for the MessSessionsNotifier
final messSessionsProvider = StateNotifierProvider<MessSessionsNotifier, AsyncValue<List<MessSession>>>((ref) {
  final repository = ref.watch(messRepositoryProvider);
  return MessSessionsNotifier(repository);
});
