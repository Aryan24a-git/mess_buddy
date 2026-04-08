import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/expense.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/sqlite_expense_repository.dart';
import '../../../mess/presentation/providers/mess_sessions_provider.dart';
import '../../../../features/monetization/presentation/providers/monetization_provider.dart';

// Provider for the repository
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return SqliteExpenseRepository();
});

// StateNotifier for the expenses list
class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpensesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      state = const AsyncValue.loading();
      final expenses = await _repository.getExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _repository.addExpense(expense);
      await loadExpenses();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
    } catch (e) {
      rethrow;
    }
  }
}

// Provider for the ExpensesNotifier
final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
      final repository = ref.watch(expenseRepositoryProvider);
      return ExpensesNotifier(repository);
    });

class BudgetLimitsNotifier extends StateNotifier<Map<String, double>> {
  final Ref _ref;
  BudgetLimitsNotifier(this._ref)
    : super({}) {
    _loadLimits();
  }
  
  bool get _isPro => _ref.read(monetizationProvider).isPro;

  Future<void> _loadLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? limitsString = prefs.getString('budget_limits');
    if (limitsString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(limitsString);
        state = decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      } catch (e) {
        // Fallback gracefully on parsing errors
      }
    }
  }

  Future<void> setLimit(String category, double limit) async {
    final newState = {...state};
    newState[category] = limit;
    state = newState;
    await _saveLimits();
  }

  Future<void> addLimit(String category, double limit) async {
    // Normal user: Max 2 limits. Pro: Unlimited.
     if (!_isPro && state.length >= 2) {
        throw Exception('You reached the limit, Pro mode is coming soon!');
     }
    
    final newState = {...state};
    if (newState.containsKey(category)) return;
    newState[category] = limit;
    state = newState;
    await _saveLimits();
  }

  Future<void> deleteLimits(Set<String> categories) async {
    final newState = {...state};
    for (final cat in categories) {
      newState.remove(cat);
    }
    state = newState;
    await _saveLimits();
  }

  Future<void> renameLimit(String oldName, String newName) async {
    if (oldName == newName ||
        !state.containsKey(oldName) ||
        state.containsKey(newName)) {
      return;
    }
    final value = state[oldName]!;
    final newState = {...state};
    newState.remove(oldName);
    newState[newName] = value;
    state = newState;
    await _saveLimits();
  }

  Future<void> _saveLimits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budget_limits', jsonEncode(state));
  }
}

final budgetLimitsProvider =
    StateNotifierProvider<BudgetLimitsNotifier, Map<String, double>>((ref) {
      return BudgetLimitsNotifier(ref);
    });

class UserCategoriesNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  UserCategoriesNotifier(this._ref) : super([]) {
    _load();
  }

  bool get _isPro => _ref.read(monetizationProvider).isPro;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('user_categories_v1');
    if (data != null) {
      state = data;
    }
  }

  Future<void> addCategory(String category) async {
    // Normal user: Max 3 custom categories. Pro: Unlimited.
    if (!_isPro && state.length >= 3) {
      throw Exception('You reached the limit, Pro mode is coming soon!');
    }
    
    if (state.contains(category)) return;
    state = [...state, category];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_categories_v1', state);
  }

  Future<void> removeCategory(String category) async {
    state = state.where((c) => c != category).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('user_categories_v1', state);
  }
}

final userCategoriesProvider =
    StateNotifierProvider<UserCategoriesNotifier, List<String>>((ref) {
      return UserCategoriesNotifier(ref);
    });

class QuickAddNotifier
    extends StateNotifier<Map<String, Map<String, dynamic>>> {
  QuickAddNotifier()
    : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('quick_add_items_v2');
    if (data != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(data);
        state = decoded.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
        );
      } catch (e) {
        // Fallback
      }
    }
  }

  Future<void> addItem(String name, double amount, String category) async {
    state = {
      ...state,
      name: {'amount': amount, 'category': category},
    };
    _save();
  }

  Future<void> removeItem(String name) async {
    final newState = {...state};
    newState.remove(name);
    state = newState;
    _save();
  }

  Future<void> editAmount(String name, double amount) async {
    if (state.containsKey(name)) {
      final current = state[name]!;
      state = {
        ...state,
        name: {'amount': amount, 'category': current['category']},
      };
      _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_add_items_v2', jsonEncode(state));
  }
}

final quickAddProvider =
    StateNotifierProvider<QuickAddNotifier, Map<String, Map<String, dynamic>>>((
      ref,
    ) {
      return QuickAddNotifier();
    });

class TotalBudgetNotifier extends StateNotifier<double> {
  TotalBudgetNotifier() : super(0.0) {
    _load();
  }

  bool _isInitialized = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Align with AuthRepository key for unified state
    final data = prefs.getDouble('monthlyBudget');
    if (data != null && !_isInitialized) {
      state = data;
      _isInitialized = true;
    }
  }

  Future<void> setBudget(double amount) async {
    _isInitialized = true;
    state = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', amount);
  }
}

final totalBudgetProvider = StateNotifierProvider<TotalBudgetNotifier, double>((
  ref,
) {
  return TotalBudgetNotifier();
});

class DailyBudgetNotifier extends StateNotifier<double> {
  DailyBudgetNotifier() : super(0.0) {
    _load();
  }

  bool _isInitialized = false;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getDouble('daily_budget_v1');
    if (data != null && !_isInitialized) {
      state = data;
      _isInitialized = true;
    }
  }

  Future<void> setBudget(double amount) async {
    _isInitialized = true;
    state = amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_budget_v1', amount);
  }
}

final dailyBudgetProvider = StateNotifierProvider<DailyBudgetNotifier, double>((
  ref,
) {
  return DailyBudgetNotifier();
});

/// Computes total spending for TODAY only.
/// Includes:
///   1. All manually-added expenses whose date is today.
///   2. All mess session costs for today where status == 'Attended'.
final dailyExpensesProvider = Provider<double>((ref) {
  final expensesState = ref.watch(expensesProvider);
  final messState = ref.watch(messSessionsProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  // 1. Regular expenses logged today
  double regularTotal = expensesState.maybeWhen(
    data: (expenses) => expenses
        .where((e) => !e.date.isBefore(today) && e.date.isBefore(tomorrow))
        .fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );

  // 2. Mess session costs for today (Attended sessions only)
  double messTotal = messState.maybeWhen(
    data: (sessions) {
      return sessions
          .where((s) {
            final d = s.sessionDate;
            final sessionDay = DateTime(d.year, d.month, d.day);
            return sessionDay.isAtSameMomentAs(today) && s.status == 'Attended';
          })
          .fold(0.0, (sum, s) => sum + s.sessionCost);
    },
    orElse: () => 0.0,
  );

  return regularTotal + messTotal;
});

/// Tracks only spending with category 'food' (considered OUTSIDE food)
final outsideFoodSpendingProvider = Provider<double>((ref) {
  final expensesState = ref.watch(expensesProvider);
  return expensesState.maybeWhen(
    data: (expenses) => expenses
        .where((e) => e.category.toLowerCase().trim() == 'food')
        .fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );
});

/// Tracks all mess-related spending:
/// 1. Manual expenses with category 'mess'
/// 2. Automated mess attendance sessions
final messFoodSpendingProvider = Provider<double>((ref) {
  final expensesState = ref.watch(expensesProvider);
  final messState = ref.watch(messSessionsProvider);

  // Manual 'mess' category expenses
  double manualMess = expensesState.maybeWhen(
    data: (expenses) => expenses
        .where((e) => e.category.toLowerCase().trim() == 'mess')
        .fold(0.0, (sum, e) => sum + e.amount),
    orElse: () => 0.0,
  );

  // Automated attendance (all-time)
  double attendanceMess = messState.maybeWhen(
    data: (sessions) => sessions
        .where((s) => s.status == 'Attended')
        .fold(0.0, (sum, s) => sum + s.sessionCost),
    orElse: () => 0.0,
  );

  return manualMess + attendanceMess;
});

/// Tracks all spending for the current calendar month across both:
/// 1. Regular manually-added expenses
/// 2. Automated mess attendance sessions
final monthlySpendingProvider = Provider<double>((ref) {
  final expensesState = ref.watch(expensesProvider);
  final messSessionsState = ref.watch(allMessSessionsProvider);

  final now = DateTime.now();
  
  double total = 0;

  // 1. Regular expenses
  expensesState.whenData((expenses) {
    for (var e in expenses) {
      if (e.date.year == now.year && e.date.month == now.month) {
        total += e.amount;
      }
    }
  });

  // 2. Mess sessions
  messSessionsState.whenData((sessions) {
    for (var s in sessions) {
      if (s.status == 'Attended') {
        if (s.sessionDate.year == now.year && s.sessionDate.month == now.month) {
          total += s.sessionCost;
        }
      }
    }
  });

  return total;
});

/// Provider for the number of days remaining in the current month.
final daysRemainingProvider = Provider<int>((ref) {
  final now = DateTime.now();
  final lastDay = DateTime(now.year, now.month + 1, 0);
  final today = DateTime(now.year, now.month, now.day);
  return lastDay.difference(today).inDays;
});

/// Provider for calculating the user's budget streak (consecutive days with expenses).
final budgetStreakProvider = Provider<int>((ref) {
  final expensesState = ref.watch(expensesProvider);
  return expensesState.maybeWhen(
    data: (expenses) {
      if (expenses.isEmpty) return 0;
      
      final expenseDates = expenses
          .map((e) => DateTime(e.date.year, e.date.month, e.date.day))
          .toSet();
      
      int streak = 0;
      DateTime checkDate = DateTime.now();
      checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
      
      // If no expense today, check if streak continued until yesterday
      if (!expenseDates.contains(checkDate)) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      while (expenseDates.contains(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
      return streak;
    },
    orElse: () => 0,
  );
});
