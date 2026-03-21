import '../models/roommate.dart';

abstract class RoommateRepository {
  Future<List<Roommate>> getRoommates();
  Future<Roommate> addRoommate(Roommate roommate);
  Future<int> updateRoommate(Roommate roommate);
  Future<int> deleteRoommate(int id);
}
