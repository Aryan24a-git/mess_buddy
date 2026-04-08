import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/dashboard/presentation/providers/expenses_provider.dart';
import '../../../../features/mess/presentation/providers/mess_sessions_provider.dart';
import '../../../../features/roommates/presentation/providers/roommate_balances_provider.dart';

class AnalyticsData {
  final double monthlySpending;
  final Map<String, double> categoryBreakdown;
  final double burnRate;
  final String mostSpentCategory;
  final String mostExpensiveWeek;
  final List<double> last7DaysSpending;
  final List<double> weeklySpendingTrends;
  final double messSpending;
  final double outsideSpending;
  final double youOweTotal;
  final double othersOweTotal;
  final List<int> spendingFrequency;
  final List<String> highestExpenseByDay;
  final List<String> highestExpenseByWeek;
  final double dailyGrowth; 
  final double todayDifference; // Difference between budget and today's spending
  final List<double> dailyCumulativeSpending;

  AnalyticsData({
    required this.monthlySpending,
    required this.categoryBreakdown,
    required this.burnRate,
    required this.mostSpentCategory,
    required this.mostExpensiveWeek,
    required this.last7DaysSpending,
    required this.weeklySpendingTrends,
    required this.messSpending,
    required this.outsideSpending,
    required this.youOweTotal,
    required this.othersOweTotal,
    required this.spendingFrequency,
    required this.highestExpenseByDay,
    required this.highestExpenseByWeek,
    required this.dailyGrowth,
    required this.todayDifference,
    required this.dailyCumulativeSpending,
  });

  factory AnalyticsData.empty() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return AnalyticsData(
      monthlySpending: 0,
      categoryBreakdown: {'Food': 0, 'Rent': 0, 'Mess': 0, 'Other': 0},
      burnRate: 0,
      mostSpentCategory: 'None',
      mostExpensiveWeek: 'Week 1',
      last7DaysSpending: List.generate(7, (_) => 0.0),
      weeklySpendingTrends: List.generate(5, (_) => 0.0),
      messSpending: 0,
      outsideSpending: 0,
      youOweTotal: 0,
      othersOweTotal: 0,
      spendingFrequency: List.generate(28, (_) => 0),
      highestExpenseByDay: List.generate(7, (_) => 'No spending'),
      highestExpenseByWeek: List.generate(5, (_) => 'No spending'),
      dailyGrowth: 0,
      todayDifference: 0,
      dailyCumulativeSpending: List.generate(daysInMonth, (_) => 0.0),
    );
  }
}

final analyticsProvider = Provider<AsyncValue<AnalyticsData>>((ref) {
  final expensesState = ref.watch(expensesProvider);
  final messSessionsState = ref.watch(allMessSessionsProvider);
  final youOwe = ref.watch(totalYouOweProvider);
  final othersOwe = ref.watch(totalOthersOweYouProvider);
  final totalBudget = ref.watch(totalBudgetProvider);
  final budgetLimits = ref.watch(budgetLimitsProvider);
  final dailyBudget = ref.watch(dailyBudgetProvider);
  final todaySpending = ref.watch(dailyExpensesProvider);

  // If either data source is loading, show loading
  if (expensesState is AsyncLoading || messSessionsState is AsyncLoading) {
    return const AsyncValue.loading();
  }

  // If either has error
  if (expensesState is AsyncError) {
    final error = expensesState as AsyncError;
    return AsyncValue.error(error.error, error.stackTrace);
  }
  if (messSessionsState is AsyncError) {
    final error = messSessionsState as AsyncError;
    return AsyncValue.error(error.error, error.stackTrace);
  }

  final expenses = expensesState.value ?? [];
  final sessions = messSessionsState.value ?? [];

  if (expenses.isEmpty && sessions.isEmpty) return AsyncValue.data(AnalyticsData.empty());

  final now = DateTime.now();
  
  double totalSpending = 0;
  double allTimeSpending = 0;
  double messSpending = 0;
  double outsideSpending = 0;
  
  Map<String, double> allTimeCategoryTotals = {};
  
  List<double> monthlyWeeklySpend = [0, 0, 0, 0, 0];
  List<double> last7Days = List.generate(7, (_) => 0.0);
  List<double> maxDayAmt = List.generate(7, (_) => 0.0);
  List<String> maxDayTitle = List.generate(7, (_) => 'No spending');
  List<String> maxWeekTitle = List.generate(5, (_) => 'No spending');
  List<double> maxWeekAmt = List.generate(5, (_) => 0.0);

  int earliestDayInMonth = now.day;
  bool hasAnyMonthlySpend = false;
  List<int> frequency = List.generate(28, (_) => 0);

  // Helper to process any transaction (Expense or MessSession)
  void processItem(DateTime date, double amount, String category, String title) {
    final diff = now.difference(date).inDays;
    
    // All-time Category accumulation
    allTimeSpending += amount;
    allTimeCategoryTotals[category] = (allTimeCategoryTotals[category] ?? 0) + amount;

    // Last 7 days (Daily)
    if (diff >= 0 && diff < 7) {
      int idx = 6 - diff;
      last7Days[idx] += amount;
      if (amount > maxDayAmt[idx]) {
        maxDayAmt[idx] = amount;
        maxDayTitle[idx] = '$title: ₹${amount.toStringAsFixed(0)}';
      }
    }

    // Frequency (last 28 days)
    if (diff >= 0 && diff < 28) {
      int fIdx = 27 - diff;
      if (fIdx >= 0 && fIdx < 28) {
        frequency[fIdx]++;
      }
    }

    // Current Month Stats
    if (date.year == now.year && date.month == now.month) {
      totalSpending += amount;
      hasAnyMonthlySpend = true;
      if (date.day < earliestDayInMonth) earliestDayInMonth = date.day;
      
      final catName = category.toLowerCase();
      if (catName.contains('mess')) {
        messSpending += amount;
      } else if (catName.contains('food') || catName.contains('outside')) {
        outsideSpending += amount;
      }

      int monthWeekIdx = ((date.day - 1) / 7).floor();
      if (monthWeekIdx > 4) monthWeekIdx = 4;
      monthlyWeeklySpend[monthWeekIdx] += amount;
      
      if (amount > maxWeekAmt[monthWeekIdx]) {
        maxWeekAmt[monthWeekIdx] = amount;
        maxWeekTitle[monthWeekIdx] = '$title: ₹${amount.toStringAsFixed(0)}';
      }
    }
  }


  // 1. Process regular expenses
  for (var expense in expenses) {
    processItem(expense.date, expense.amount, expense.category, expense.title);
  }

  // 2. Process mess sessions (Attended only)
  for (var session in sessions) {
    if (session.status == 'Attended') {
      processItem(session.sessionDate, session.sessionCost, 'Mess', session.sessionType);
    }
  }

  // Cumulative Weekly sums for growth chart
  List<double> cumulativeWeekly = [0, 0, 0, 0, 0];
  double runningSum = 0;
  for (int i = 0; i < monthlyWeeklySpend.length; i++) {
      runningSum += monthlyWeeklySpend[i];
      cumulativeWeekly[i] = runningSum;
  }

  Map<String, double> categoryBreakdown = {};
  if (allTimeSpending > 0) {
    allTimeCategoryTotals.forEach((key, value) {
      categoryBreakdown[key] = (value / allTimeSpending) * 100;
    });
  }

  // Burn rate calculation:
  // If no monthly spending yet, it's 0.
  // Otherwise, divide by the number of days from the first monthly transaction until today.
  // This helps when a user joins or starts using the app midway through a month.
  int daysActiveThisMonth = (now.day - earliestDayInMonth + 1).clamp(1, 31);
  final double burnRate = hasAnyMonthlySpend ? (totalSpending / daysActiveThisMonth) : 0.0;

  String mostSpentCategory = 'None';
  double maxCatSpend = 0;
  allTimeCategoryTotals.forEach((cat, val) {
    if (val > maxCatSpend) {
      maxCatSpend = val;
      mostSpentCategory = cat;
    }
  });

  String mostExpensiveWeekStr = 'Week 1';
  double maxMWeekSpend = 0;
  for (int i = 0; i < monthlyWeeklySpend.length; i++) {
      if (monthlyWeeklySpend[i] > maxMWeekSpend) {
        maxMWeekSpend = monthlyWeeklySpend[i];
        mostExpensiveWeekStr = 'Week ${i + 1}';
      }
  }

  final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

  // --- Daily Growth Calculation (Spending Growth) ---
  // The user wants:
  // Overspent -> Red + Trending Up
  // Lower spending -> Green + Trending Down
  double dailyRef = dailyBudget > 0 ? dailyBudget : (totalBudget / daysInMonth);
  if (dailyRef <= 0) {
    double totalLimits = budgetLimits.values.fold(0, (sum, val) => sum + val);
    dailyRef = totalLimits / daysInMonth;
  }
  if (dailyRef <= 0) dailyRef = 200.0; // Baseline daily budget

  double growth = 0;
  double diffVal = 0;
  if (todaySpending > 0) {
    growth = ((todaySpending - dailyRef) / dailyRef) * 100;
    diffVal = dailyRef - todaySpending; 
  }
  // --- End Daily Growth Calculation ---

  // Calculate daily cumulative spending for the month
  List<double> dayByDaySpending = List.generate(daysInMonth, (_) => 0.0);
  for (var expense in expenses) {
    if (expense.date.year == now.year && expense.date.month == now.month) {
      dayByDaySpending[expense.date.day - 1] += expense.amount;
    }
  }
  for (var session in sessions) {
    if (session.status == 'Attended' && 
        session.sessionDate.year == now.year && 
        session.sessionDate.month == now.month) {
      dayByDaySpending[session.sessionDate.day - 1] += session.sessionCost;
    }
  }

  List<double> dailyCumulative = List.generate(daysInMonth, (_) => 0.0);
  double currentCumulative = 0;
  for (int i = 0; i < daysInMonth; i++) {
    currentCumulative += dayByDaySpending[i];
    // Fill every day but only up to current cumulative to show the "line"
    dailyCumulative[i] = currentCumulative;
  }
  // --- End Growth & Trend Calculation ---

  return AsyncValue.data(AnalyticsData(
    monthlySpending: totalSpending,
    categoryBreakdown: categoryBreakdown,
    burnRate: burnRate,
    mostSpentCategory: mostSpentCategory,
    mostExpensiveWeek: mostExpensiveWeekStr,
    last7DaysSpending: last7Days,
    weeklySpendingTrends: cumulativeWeekly,
    messSpending: messSpending,
    outsideSpending: outsideSpending,
    youOweTotal: youOwe,
    othersOweTotal: othersOwe,
    spendingFrequency: frequency,
    highestExpenseByDay: maxDayTitle,
    highestExpenseByWeek: maxWeekTitle,
    dailyGrowth: growth,
    todayDifference: diffVal,
    dailyCumulativeSpending: dailyCumulative,
  ));
});
