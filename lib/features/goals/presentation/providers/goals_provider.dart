import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/goal.dart';
import '../../domain/repositories/goal_repository.dart';
import '../../data/repositories/mock_goal_repository.dart';
import '../../data/repositories/sqlite_goal_repository.dart';

// Provider for the GoalRepository
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  if (kIsWeb) {
    return MockGoalRepository();
  }
  return SqliteGoalRepository();
});

// StateNotifier for managing the list of goals
class GoalsNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final GoalRepository repository;

  GoalsNotifier(this.repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      state = const AsyncValue.loading();
      final goals = await repository.getGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await repository.addGoal(goal);
      await loadGoals();
    } catch (e) {
      // Re-throw or handle error
      rethrow;
    }
  }

  Future<void> addFundsToGoal(int id, double amountAdded) async {
    final currentState = state.value;
    if (currentState == null) return;

    final goal = currentState.firstWhere((g) => g.id == id);
    final updatedGoal = goal.copyWith(
      currentAmount: goal.currentAmount + amountAdded,
    );
    
    try {
      await repository.updateGoal(updatedGoal);
      await loadGoals();
    } catch (e) {
      rethrow;
    }
  }
}

// Global provider for Goals array
final goalsProvider = StateNotifierProvider<GoalsNotifier, AsyncValue<List<Goal>>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalsNotifier(repository);
});
