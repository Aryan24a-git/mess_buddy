import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/roommate.dart';
import '../../domain/repositories/roommate_repository.dart';
import '../../data/repositories/sqlite_roommate_repository.dart';

// 1. Provide the Repository implementation (SQLite for Mobile/Desktop)
final roommateRepositoryProvider = Provider<RoommateRepository>((ref) {
  return SqliteRoommateRepository();
});

// 2. Notifier to manage the State
class RoommatesNotifier extends StateNotifier<AsyncValue<List<Roommate>>> {
  final RoommateRepository _repository;

  RoommatesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRoommates();
  }

  Future<void> loadRoommates() async {
    try {
      state = const AsyncValue.loading();
      final roommates = await _repository.getRoommates();
      state = AsyncValue.data(roommates);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Roommate> addRoommate(String name, String phone) async {
    try {
      final newRoommate = Roommate(
        name: name,
        phone: phone,
        createdAt: DateTime.now(),
      );
      final addedItem = await _repository.addRoommate(newRoommate);
      await loadRoommates(); // Refresh list after adding
      return addedItem;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoommate(int id) async {
    try {
      await _repository.deleteRoommate(id);
      await loadRoommates(); // Refresh list after deleting
    } catch (e) {
      rethrow;
    }
  }
}

// 3. Provider for the StateNotifier
final roommatesProvider = StateNotifierProvider<RoommatesNotifier, AsyncValue<List<Roommate>>>((ref) {
  final repository = ref.watch(roommateRepositoryProvider);
  return RoommatesNotifier(repository);
});
