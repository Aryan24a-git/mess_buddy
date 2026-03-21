import '../models/goal.dart';

abstract class GoalRepository {
  Future<List<Goal>> getGoals();
  Future<Goal> addGoal(Goal goal);
  Future<int> updateGoal(Goal goal);
  Future<int> deleteGoal(int id);
}
