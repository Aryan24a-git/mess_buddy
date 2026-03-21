import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/mess_sessions_provider.dart';
import '../../domain/models/mess_session.dart';

class MessPage extends ConsumerWidget {
  const MessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messState = ref.watch(messSessionsProvider);
    
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
              _buildAttendanceSection(messState, ref),
              const SizedBox(height: AppDimensions.s3),
              _buildCurrentSessionCard(),
              const SizedBox(height: AppDimensions.s3),
              _buildMonthlyOverviewCard(),
              const SizedBox(height: AppDimensions.s3),
              _buildComparisonCard(),
              const SizedBox(height: AppDimensions.s4), // Extra padding at bottom
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

  Widget _buildAttendanceSection(AsyncValue<List<MessSession>> messState, WidgetRef ref) {
    return messState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (sessions) {
        // Find Dinner session or default
        final matches = sessions.where((s) => s.sessionType == 'Dinner');
        final dinnerSession = matches.isNotEmpty ? matches.first : null;
        
        final isAttending = dinnerSession != null && dinnerSession.status == 'Attended';
        final isSkipped = dinnerSession != null && dinnerSession.status == 'Skipped';

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'LIVE STATUS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s2),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.r3),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(messSessionsProvider.notifier).toggleSessionAttendance('Dinner', true, 80.0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                        decoration: BoxDecoration(
                          color: isAttending ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                          border: Border.all(color: isAttending ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: isAttending ? AppColors.primary : AppColors.textMuted, size: 20),
                            const SizedBox(width: AppDimensions.s1),
                            Text(
                              'Present',
                              style: TextStyle(
                                color: isAttending ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isAttending ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ref.read(messSessionsProvider.notifier).toggleSessionAttendance('Dinner', false, 80.0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                        decoration: BoxDecoration(
                          color: isSkipped ? Colors.redAccent.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                          border: Border.all(color: isSkipped ? Colors.redAccent.withValues(alpha: 0.3) : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel, color: isSkipped ? Colors.redAccent : AppColors.textMuted, size: 20),
                            const SizedBox(width: AppDimensions.s1),
                            Text(
                              'Absent',
                              style: TextStyle(
                                color: isSkipped ? Colors.redAccent : AppColors.textPrimary,
                                fontWeight: isSkipped ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentSessionCard() {
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Session',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Dinner',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹80',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Standard Rate',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          const Text(
            'ADD-ONS (EXTRAS)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          Row(
            children: [
              Expanded(
                child: _buildAddonItem(
                  icon: Icons.egg_outlined,
                  name: 'Egg',
                  price: '₹10',
                  iconColor: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.s1),
              Expanded(
                child: _buildAddonItem(
                  icon: Icons.restaurant,
                  name: 'Chicken',
                  price: '₹60',
                  iconColor: Colors.deepOrangeAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.s1),
              Expanded(
                child: _buildAddonItem(
                  icon: Icons.water_drop_outlined,
                  name: 'Milk',
                  price: '₹20',
                  iconColor: Colors.lightBlueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddonItem({
    required IconData icon,
    required String name,
    required String price,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.pNormal),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: AppDimensions.s1),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '($price)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            Color(0xFF1E1F29), // slightly different surface tint
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY OVERVIEW',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹1,850',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Total Mess Expenditure',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: AppColors.success, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '12%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'VS LAST MONTH',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          const SizedBox(height: AppDimensions.s3),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_today, color: Colors.lightBlueAccent, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.s1),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '22 Days',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Mess Count',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.money, color: Colors.orangeAccent, size: 20),
                    ),
                    const SizedBox(width: AppDimensions.s1),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹84/meal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Average Cost',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
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
                'Mess vs Outside',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'SAVING ₹450/mo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s4),
          _buildProgressBarRow(
            label: 'Eating Outside (Est.)',
            amount: '₹2,300',
            progress: 1.0,
            color: const Color(0xFF333333),
          ),
          const SizedBox(height: AppDimensions.s3),
          _buildProgressBarRow(
            label: 'Current Mess Cost',
            amount: '₹1,850',
            progress: 0.76, // 1850 / 2300 approx
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.s4),
          const Text(
            'You are currently spending 24% less by utilizing the mess facilities consistently.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarRow({
    required String label,
    required String amount,
    required double progress,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.r1),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 12,
          ),
        ),
      ],
    );
  }
}
