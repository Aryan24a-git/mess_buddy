import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/dashboard/presentation/providers/expenses_provider.dart';

class AnalyticsData {
  final double monthlySpending;
  final Map<String, double> categoryBreakdown;
  final double burnRate;
  final String mostSpentCategory;
  final String mostExpensiveWeek;

  AnalyticsData({
    required this.monthlySpending,
    required this.categoryBreakdown,
    required this.burnRate,
    required this.mostSpentCategory,
    required this.mostExpensiveWeek,
  });

  factory AnalyticsData.empty() {
    return AnalyticsData(
      monthlySpending: 0,
      categoryBreakdown: {'Food': 0, 'Rent': 0, 'Mess': 0, 'Other': 0},
      burnRate: 0,
      mostSpentCategory: 'None',
      mostExpensiveWeek: 'Week 1',
    );
  }
}

final analyticsProvider = Provider<AsyncValue<AnalyticsData>>((ref) {
  final expensesState = ref.watch(expensesProvider);

  return expensesState.whenData((expenses) {
    if (expenses.isEmpty) return AnalyticsData.empty();

    final now = DateTime.now();
    final currentMonthExpenses = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();

    double totalSpending = 0;
    Map<String, double> categoryTotals = {};
    
    // For weekly calculation
    List<double> weeklySpend = [0, 0, 0, 0, 0]; 

    for (var expense in currentMonthExpenses) {
      totalSpending += expense.amount;
      
      // Category sum
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
      
      // Weekly sum (rough approximation for 1-7, 8-14, 15-21, 22-28, 29+)
      int weekIndex = ((expense.date.day - 1) / 7).floor();
      if (weekIndex > 4) weekIndex = 4;
      weeklySpend[weekIndex] += expense.amount;
    }

    // Category Breakdown Percentages
    Map<String, double> categoryBreakdown = {};
    if (totalSpending > 0) {
      categoryTotals.forEach((key, value) {
        categoryBreakdown[key] = (value / totalSpending) * 100;
      });
    }

    // Burn Rate (Average daily expense so far this month)
    int daysPassed = now.day;
    double burnRate = totalSpending / (daysPassed > 0 ? daysPassed : 1);

    // AI Insights: Most spent category
    String mostSpentCategory = 'None';
    double maxCatSpend = 0;
    categoryTotals.forEach((cat, val) {
      if (val > maxCatSpend) {
        maxCatSpend = val;
        mostSpentCategory = cat;
      }
    });

    // AI Insights: Most expensive week
    String mostExpensiveWeek = 'Week 1';
    double maxWeekSpend = 0;
    for (int i = 0; i < weeklySpend.length; i++) {
      if (weeklySpend[i] > maxWeekSpend) {
        maxWeekSpend = weeklySpend[i];
        mostExpensiveWeek = 'Week ${i + 1}';
      }
    }

    return AnalyticsData(
      monthlySpending: totalSpending,
      categoryBreakdown: categoryBreakdown,
      burnRate: burnRate,
      mostSpentCategory: mostSpentCategory.isNotEmpty ? mostSpentCategory : 'None',
      mostExpensiveWeek: mostExpensiveWeek,
    );
  });
});
