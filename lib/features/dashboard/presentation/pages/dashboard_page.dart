import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/expenses_provider.dart';
import '../../../../features/monetization/presentation/providers/earnings_provider.dart';
import '../../../../features/alerts/presentation/providers/alerts_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import 'all_transactions_page.dart';

final selectedLimitsProvider = StateProvider<Set<String>>((ref) => {});
final budgetAlertThresholdProvider = StateProvider<double>((ref) => 0.3);

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Monthly budget alert ──────────────────────────────────────────────────
    ref.listen<double>(monthlySpendingProvider, (previous, totalExpenses) {
        final totalBudget = ref.read(totalBudgetProvider);
        if (totalBudget > 0) {
          final percent = (totalBudget - totalExpenses) / totalBudget;
          final threshold = ref.read(budgetAlertThresholdProvider);
          if (percent < threshold) {
             // Optional: also push a persistent alert for monthly
          }
        }
    });

    // ── Daily budget alerts ───────────────────────────────────────────────────
    ref.listen<double>(dailyExpensesProvider, (prevSpent, spent) {
      if (prevSpent == null) return; // Ignore initial load emission
      
      final dailyBudget = ref.read(dailyBudgetProvider);
      if (dailyBudget <= 0) return;

      final prevRatio = prevSpent / dailyBudget;
      final currRatio = spent / dailyBudget;

      // Only show warn at 80%
      if (currRatio >= 0.8 && prevRatio < 0.8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ 80% Daily Budget Used!'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Trigger persistent alert for the "Notification Icon"
      if (currRatio >= 0.8) {
        ref.read(alertsProvider.notifier).triggerDailyBudgetAlert(spent, dailyBudget);
      }
    });

    final expensesState = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, ref),
              const SizedBox(height: AppDimensions.s4),
              _buildWelcomeSection(ref),
              const SizedBox(height: AppDimensions.s4),
              const SizedBox(height: AppDimensions.s4),
              _buildBalanceCard(context, ref),
              const SizedBox(height: AppDimensions.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildFinanceHealthCard(ref)),
                  const SizedBox(width: AppDimensions.s3),
                  Expanded(
                    child: Column(
                      children: [
                        _buildSmallFeatureCard(
                          icon: Icons.timer_outlined,
                          title: 'Budget Info',
                          subtitle: "${ref.watch(daysRemainingProvider)} Days Left",
                          iconColor: Colors.orange,
                        ),
                        const SizedBox(height: AppDimensions.s3),
                        _buildSmallFeatureCard(
                          icon: Icons.local_fire_department_outlined,
                          title: 'Budget Streak',
                          subtitle: ref.watch(budgetStreakProvider) > 0 
                            ? "${ref.watch(budgetStreakProvider)} Day Streak"
                            : "No streak yet",
                          iconColor: Colors.deepPurpleAccent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.s4),
              _buildDailyBudgetCard(context, ref),
              const SizedBox(height: AppDimensions.s4),
              _buildBudgetLimitsSection(context, ref),
              const SizedBox(height: AppDimensions.s4),
              _buildTransactionsHeader(context),
              const SizedBox(height: AppDimensions.s2),
              _buildTransactionsList(context, ref, expensesState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final premiumStatus = ref.watch(premiumStatusProvider).valueOrNull;
    final isPremium = premiumStatus?.isPremium ?? false;


    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: AppDimensions.s2),
            const Text(
              'Mess Buddy',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPremium)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('PRO', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(WidgetRef ref) {
    final authData = ref.watch(authProvider).value;
    final user = authData?.profile;
    final name = user?.name ?? 'User';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hey $name ',
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Text('👋', style: TextStyle(fontSize: 28)),
          ],
        ),
        const SizedBox(height: AppDimensions.s1),
        const Text(
          'Ready to manage your hostel expenses?',
          style: TextStyle(fontSize: 16, color: AppColors.textMuted),
        ),
      ],
    );
  }


  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    final totalSpending = ref.watch(monthlySpendingProvider);
    final totalBudget = ref.watch(totalBudgetProvider);

    final currentBalance = totalBudget - totalSpending;
    final percentageLeft = totalBudget > 0
        ? (currentBalance / totalBudget).clamp(0.0, 1.0)
        : 0.0;

    final threshold = ref.watch(budgetAlertThresholdProvider);

    // Alert logic
    final isAlert = percentageLeft < threshold && totalBudget > 0;
    final progressColor = isAlert ? Colors.redAccent : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showEditTotalBudgetDialog(context, ref, totalBudget),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s2),
          Text(
            '₹${currentBalance.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: progressColor,
              ),
              const SizedBox(width: AppDimensions.s1),
              Text(
                'Total Budget: ₹${totalBudget.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isAlert ? 'Budget Remaining (ALERT!)' : 'Budget Remaining',
                    style: TextStyle(
                      fontSize: 12,
                      color: isAlert ? Colors.redAccent : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s1),
                  GestureDetector(
                    onTap: () =>
                        _showEditAlertThresholdDialog(context, ref, threshold),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                '${(percentageLeft * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isAlert ? Colors.redAccent : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r1),
            child: LinearProgressIndicator(
              value: percentageLeft,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceHealthCard(WidgetRef ref) {
    final dailyExpenses = ref.watch(dailyExpensesProvider);
    final dailyBudget = ref.watch(dailyBudgetProvider);

    double score = 100.0;
    if (dailyBudget > 0) {
      score = ((dailyBudget - dailyExpenses) / dailyBudget * 100).clamp(0, 100);
    }

    String status = 'EXCELLENT';
    Color scoreColor = Colors.cyanAccent;

    if (score < 20) {
      status = 'CRITICAL';
      scoreColor = Colors.redAccent;
    } else if (score < 40) {
      status = 'POOR';
      scoreColor = Colors.orangeAccent;
    } else if (score < 60) {
      status = 'AVERAGE';
      scoreColor = Colors.yellowAccent;
    } else if (score < 80) {
      status = 'GOOD';
      scoreColor = Colors.lightGreenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DAILY HEALTH',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 70,
                width: 70,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    '/100',
                    style: TextStyle(fontSize: 9, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s2),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: scoreColor,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBudgetCard(BuildContext context, WidgetRef ref) {
    final dailyExpenses = ref.watch(dailyExpensesProvider);
    final dailyBudget = ref.watch(dailyBudgetProvider);

    final remaining = dailyBudget - dailyExpenses;
    final percentageLeft = dailyBudget > 0
        ? (remaining / dailyBudget).clamp(0.0, 1.0)
        : 0.0;

    final progressColor = percentageLeft < 0.2
        ? Colors.redAccent
        : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY BUDGET LIMIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () =>
                    _showEditDailyBudgetDialog(context, ref, dailyBudget),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s2),
          Text(
            '₹${remaining.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.s1),
          Text(
            'Daily Limit: ₹${dailyBudget.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppDimensions.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Progress',
                style: TextStyle(
                  fontSize: 12,
                  color: percentageLeft < 0.2
                      ? Colors.redAccent
                      : AppColors.textMuted,
                ),
              ),
              Text(
                '${(percentageLeft * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: percentageLeft < 0.2
                      ? Colors.redAccent
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r1),
            child: LinearProgressIndicator(
              value: percentageLeft,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r2),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: AppDimensions.s1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllTransactionsPage()),
            );
          },
          child: const Text(
            'View All',
            style: TextStyle(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> expensesState,
  ) {
    return expensesState.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error loading expenses: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.pNormal),
            child: Text(
              'No recent transactions.',
              style: TextStyle(color: AppColors.textMuted),
            ),
          );
        }
        final recentExpenses = expenses.take(3).toList();
        return Column(
          children: recentExpenses.map((tx) {
            final cat = tx.category.toLowerCase();
            IconData icon = Icons.receipt_long_outlined;
            // Mess food (sessions added via Mess tab or category = 'mess')
            if (cat.contains('mess')) {
              icon = Icons.restaurant;
              // Outside food (category = 'food', snacks, coffee, etc.)
            } else if (cat.contains('food')) {
              icon = Icons.storefront_outlined;
            } else if (cat.contains('travel') || cat.contains('transport')) {
              icon = Icons.directions_bus_outlined;
            } else if (cat.contains('market') || cat.contains('shopping')) {
              icon = Icons.shopping_bag_outlined;
            } else if (cat.contains('rent')) {
              icon = Icons.home_outlined;
            } else if (cat.contains('stationar')) {
              icon = Icons.edit_outlined;
            } else if (cat.contains('entertain')) {
              icon = Icons.movie_outlined;
            }

            return _buildTransactionItem(
              context: context,
              ref: ref,
              expense: tx,
              icon: icon,
              title: tx.title,
              category: tx.category,
              amount: '- ₹${tx.amount.toInt()}',
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTransactionItem({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic expense,
    required IconData icon,
    required String title,
    required String category,
    required String amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.s2),
      padding: const EdgeInsets.all(AppDimensions.pNormal),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.r2),
            ),
            child: Icon(icon, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppDimensions.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (expense.isSplit)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'SPLIT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              if (expense.id != null) {
                ref.read(expensesProvider.notifier).deleteExpense(expense.id!);
              }
            },
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            padding: const EdgeInsets.only(left: 8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetLimitsSection(BuildContext context, WidgetRef ref) {
    final limits = ref.watch(budgetLimitsProvider);
    final expensesState = ref.watch(expensesProvider);
    final selectedLimits = ref.watch(selectedLimitsProvider);
    final inSelectionMode = selectedLimits.isNotEmpty;

    // Group expenses by category
    final Map<String, double> categorySpent = {};
    if (expensesState is AsyncData<List<dynamic>>) {
      for (final tx in expensesState.value!) {
        final cat = tx.category;
        categorySpent[cat] = (categorySpent[cat] ?? 0.0) + tx.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Budget Limits',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddLimitDialog(context, ref),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            if (inSelectionMode)
              IconButton(
                onPressed: () {
                  ref
                      .read(budgetLimitsProvider.notifier)
                      .deleteLimits(selectedLimits);
                  ref.read(selectedLimitsProvider.notifier).state = {};
                },
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.s3),
        if (limits.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              'No budget limits found. Add one to track spending!',
              style: TextStyle(color: AppColors.textMuted),
            ),
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            crossAxisSpacing: AppDimensions.s2,
            mainAxisSpacing: AppDimensions.s2,
            children: limits.entries.map((entry) {
              final category = entry.key;
              final limit = entry.value;
              final spent = categorySpent[category] ?? 0.0;
              final left = (limit - spent).clamp(0.0, limit);
              final progress = limit > 0
                  ? (spent / limit).clamp(0.0, 1.0)
                  : 1.0;
              final isSelected = selectedLimits.contains(category);

              Color progressColor = AppColors.primary;
              if (progress > 0.85) {
                progressColor = Colors.redAccent;
              } else if (progress > 0.65) {
                progressColor = Colors.orangeAccent;
              }

              // generate randomish badge color cleanly
              final colors = [
                Colors.orange,
                Colors.deepPurpleAccent,
                Colors.pinkAccent,
                Colors.amber,
                Colors.cyanAccent,
                Colors.greenAccent,
              ];
              final badgeColor = colors[category.hashCode % colors.length];

              return GestureDetector(
                onLongPress: () {
                  final current = ref.read(selectedLimitsProvider);
                  if (!current.contains(category)) {
                    ref.read(selectedLimitsProvider.notifier).state = {
                      ...current,
                      category,
                    };
                  }
                },
                onTap: () {
                  if (inSelectionMode) {
                    final current = ref.read(selectedLimitsProvider);
                    if (current.contains(category)) {
                      final updated = Set<String>.from(current)
                        ..remove(category);
                      ref.read(selectedLimitsProvider.notifier).state = updated;
                    } else {
                      ref.read(selectedLimitsProvider.notifier).state = {
                        ...current,
                        category,
                      };
                    }
                  } else {
                    _showEditLimitDialog(context, ref, category, limit);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.pNormal),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.r3),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.05),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _showRenameLimitDialog(context, ref, category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monthly Limit',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${limit.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Click to edit',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${left.toStringAsFixed(0)} left',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '₹${limit.toStringAsFixed(0)} limit',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.r1,
                            ),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.background,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progressColor,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _showEditLimitDialog(
    BuildContext context,
    WidgetRef ref,
    String category,
    double currentLimit,
  ) {
    if (ref.read(selectedLimitsProvider).isNotEmpty) {
      return; // Disable edit overlay if in selection mode to avoid ghost clicks
    }

    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Limit: $category',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'New Limit (₹)',
            labelStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final newLimit = double.tryParse(controller.text);
              if (newLimit != null && newLimit >= 0) {
                try {
                  ref
                      .read(budgetLimitsProvider.notifier)
                      .setLimit(category, newLimit);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Limit updated successfully!'), backgroundColor: AppColors.success),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddLimitDialog(BuildContext context, WidgetRef ref) {
    // Get existing categories from expenses and current limits
    final expenses = ref.read(expensesProvider).value ?? [];
    final currentLimits = ref.read(budgetLimitsProvider);
    final userCategories = ref.read(userCategoriesProvider);
    
    final allCategories = {
      ...expenses.map((e) => e.category),
      ...currentLimits.keys,
      ...userCategories,
      'Food', 'Mess', 'Rent', 'Transport', 'Entertainment', 'Shopping', 'Other'
    }.toList()
      ..sort()
      ..removeWhere((element) => element.isEmpty);

    final limitController = TextEditingController();
    String selectedCategory = '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.r3),
        ),
        title: const Text(
          'Add Budget Limit',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Category',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return allCategories;
                  }
                  return allCategories.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  selectedCategory = selection;
                },
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  controller.addListener(() {
                    selectedCategory = controller.text;
                  });
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onFieldSubmitted,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search or enter category...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r2),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r2),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.r2),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8.0,
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.r2),
                      child: Container(
                        width: 280, // Matches approximate width of dialog content
                        constraints: const BoxConstraints(maxHeight: 200),
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.r2),
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return ListTile(
                              visualDensity: VisualDensity.compact,
                              title: Text(
                                option,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => onSelected(option),
                              hoverColor: AppColors.primary.withValues(
                                alpha: 0.1,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Monthly Limit Amount',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                  ),
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.r2),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.r2),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.r2),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final cat = selectedCategory.trim();
              final lim = double.tryParse(limitController.text);
              if (cat.isNotEmpty && lim != null && lim >= 0) {
                try {
                  await ref.read(budgetLimitsProvider.notifier).addLimit(cat, lim);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Budget limit added successfully!'), backgroundColor: AppColors.success),
                    );
                    Navigator.pop(ctx);
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.r2),
              ),
            ),
            child: const Text('Add Limit'),
          ),
        ],
      ),
    );
  }

  void _showRenameLimitDialog(
    BuildContext context,
    WidgetRef ref,
    String oldCategory,
  ) {
    final controller = TextEditingController(text: oldCategory);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Rename Category',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'New Name',
            labelStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldCategory) {
                ref
                    .read(budgetLimitsProvider.notifier)
                    .renameLimit(oldCategory, newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Rename',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTotalBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    double currentBudget,
  ) {
    final curController = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Set Total Budget',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: curController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Monthly Budget Amount (₹)',
            labelStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(curController.text);
              if (amt != null && amt >= 0) {
                ref.read(totalBudgetProvider.notifier).setBudget(amt);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAlertThresholdDialog(
    BuildContext context,
    WidgetRef ref,
    double currentThreshold,
  ) {
    final curController = TextEditingController(
      text: (currentThreshold * 100).toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Set Budget Alert %',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: curController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Alert Threshold (e.g. 30)',
            suffixText: '%',
            suffixStyle: TextStyle(color: AppColors.textPrimary),
            labelStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(curController.text);
              if (amt != null && amt > 0 && amt <= 100) {
                ref.read(budgetAlertThresholdProvider.notifier).state =
                    amt / 100.0;
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDailyBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    double currentBudget,
  ) {
    final curController = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Set Daily Budget',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: curController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Daily Budget Amount (₹)',
            labelStyle: TextStyle(color: AppColors.textMuted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textMuted),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              final amt = double.tryParse(curController.text);
              if (amt != null && amt >= 0) {
                ref.read(dailyBudgetProvider.notifier).setBudget(amt);
              }
              Navigator.pop(ctx);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
