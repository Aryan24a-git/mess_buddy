import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../providers/expenses_provider.dart';

class AllTransactionsPage extends ConsumerWidget {
  const AllTransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'All Transactions',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: expensesState.when(
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
              return const Center(
                child: Text(
                  'No transactions found.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.pNormal),
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final tx = expenses[index];
                final cat = tx.category.toLowerCase();
                IconData icon = Icons.receipt_long_outlined;
                if (cat.contains('mess')) {
                  icon = Icons.restaurant;
                } else if (cat.contains('food')) {
                  icon = Icons.storefront_outlined;
                } else if (cat.contains('travel') ||
                    cat.contains('transport')) {
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

                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.s2),
                  padding: const EdgeInsets.all(AppDimensions.pNormal),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.r3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
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
                                    tx.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (tx.isSplit)
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
                              tx.category,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '- ₹${tx.amount.toInt()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (tx.id != null) {
                            ref
                                .read(expensesProvider.notifier)
                                .deleteExpense(tx.id!);
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
              },
            );
          },
        ),
      ),
    );
  }
}
