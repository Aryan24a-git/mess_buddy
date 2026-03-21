import '../../domain/models/goal.dart';
import '../../domain/repositories/goal_repository.dart';

class MockGoalRepository implements GoalRepository {
  final List<Goal> _goals = [
    Goal(
      id: 1,
      title: 'New Laptop',
      targetAmount: 50000.0,
      currentAmount: 20000.0,
      deadline: DateTime.now().add(const Duration(days: 90)),
    ),
    Goal(
      id: 2,
      title: 'Goa Trip',
      targetAmount: 15000.0,
      currentAmount: 12000.0,
      deadline: DateTime.now().add(const Duration(days: 14)),
    ),
  ];
  int _nextId = 3;

  @override
  Future<Goal> addGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newGoal = goal.copyWith(id: _nextId++);
    _goals.add(newGoal);
    return newGoal; // Ensure we return the model with ID inserted
  }

  @override
  Future<int> deleteGoal(int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final initialLength = _goals.length;
    _goals.removeWhere((g) => g.id == id);
    return initialLength > _goals.length ? 1 : 0;
  }

  @override
  Future<List<Goal>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_goals);
  }

  @override
  Future<int> updateGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
      return 1;
    }
    return 0;
  }
}
