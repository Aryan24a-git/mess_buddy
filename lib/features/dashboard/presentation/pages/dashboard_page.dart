import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/expenses_provider.dart';
import '../../../../features/monetization/presentation/widgets/banner_ad_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesState = ref.watch(expensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.s4),
              const Center(child: BannerAdWidget()),
              const SizedBox(height: AppDimensions.s4),
              _buildWelcomeSection(),
              const SizedBox(height: AppDimensions.s4),
              _buildBalanceCard(),
              const SizedBox(height: AppDimensions.s3),
              _buildFinanceHealthCard(),
              const SizedBox(height: AppDimensions.s3),
              Row(
                children: [
                  Expanded(child: _buildSmallFeatureCard(
                    icon: Icons.timer_outlined,
                    title: '12 Days left',
                    subtitle: 'Burn rate: ₹620/day',
                    iconColor: Colors.orange,
                  )),
                ],
              ),
              const SizedBox(height: AppDimensions.s3),
               _buildSmallFeatureCard(
                    icon: Icons.local_fire_department_outlined,
                    title: '14-day streak',
                    subtitle: 'You\'re staying within budget!',
                    iconColor: Colors.deepPurpleAccent,
                  ),
              const SizedBox(height: AppDimensions.s4),
              _buildTransactionsHeader(),
              const SizedBox(height: AppDimensions.s2),
              _buildTransactionsList(expensesState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: AppColors.primary),
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
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hey Aryan ',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '👋',
              style: TextStyle(fontSize: 28),
            ),
          ],
        ),
        SizedBox(height: AppDimensions.s1),
        Text(
          'Ready to manage your hostel expenses?',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard() {
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
          const Text(
            'CURRENT BALANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          const Text(
            '₹7,450',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: AppDimensions.s1),
              Text(
                'Money lasts 12 days',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget Progress',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                '65%',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.r1),
            child: const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceHealthCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Text(
            'FINANCE HEALTH',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: AppDimensions.s3),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: 0.84,
                  strokeWidth: 10,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '84',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: AppDimensions.s3),
          Text(
            'EXCELLENT STANDING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.cyanAccent,
              letterSpacing: 1,
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
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.r2),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: AppDimensions.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsHeader() {
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
          onPressed: () {},
          child: const Text('View All', style: TextStyle(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _buildTransactionsList(AsyncValue<List<dynamic>> expensesState) {
    return expensesState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error loading expenses: $e', style: const TextStyle(color: Colors.red))),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppDimensions.pNormal),
            child: Text('No recent transactions.', style: TextStyle(color: AppColors.textMuted)),
          );
        }
        return Column(
          children: expenses.map((tx) {
            IconData icon = Icons.receipt;
            if (tx.category.toLowerCase().contains('food') || tx.category.toLowerCase().contains('mess')) icon = Icons.restaurant;
            if (tx.category.toLowerCase().contains('rent')) icon = Icons.home;
            
            return _buildTransactionItem(
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  category,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
        ],
      ),
    );
  }
}
