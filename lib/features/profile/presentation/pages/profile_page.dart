import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/monetization/presentation/providers/monetization_provider.dart';
import '../../../../features/export/services/pdf_export_service.dart';
import '../../../../features/dashboard/presentation/providers/expenses_provider.dart';
import '../../../../features/analytics/presentation/providers/analytics_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetizationState = ref.watch(monetizationProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDimensions.s4),
              _buildProfileInfo(),
              const SizedBox(height: AppDimensions.s4),
              !monetizationState.isPro 
                  ? _buildUpgradeCard(context, ref)
                  : _buildProActiveCard(),
              const SizedBox(height: AppDimensions.s3),
              _buildMonthlyBudgetCard(),
              const SizedBox(height: AppDimensions.s2),
              GestureDetector(
                onTap: () => {
                  context.push('/goals')
                },
                child: _buildSimpleTile(
                  icon: Icons.flag_outlined,
                  title: 'Savings Goals',
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: AppDimensions.s2),
              _buildSimpleTile(
                icon: Icons.payments_outlined,
                title: 'Currency',
                trailing: const Text(
                  'INR (₹)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.s2),
              _buildThemeTile(),
              const SizedBox(height: AppDimensions.s2),
              _buildExportDataCard(context, ref),
              const SizedBox(height: AppDimensions.s2),
              _buildSimpleTile(
                icon: Icons.sync_rounded,
                title: 'Backup & Restore',
                trailing: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppDimensions.s4),
              _buildLogoutButton(),
              const SizedBox(height: AppDimensions.s4),
              _buildFooter(),
              const SizedBox(height: AppDimensions.pHuge * 2),
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

  Widget _buildProfileInfo() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person, size: 60, color: AppColors.textMuted), // Placeholder since we don't have the image
                // If there’s an image: backgroundImage: AssetImage('assets/images/user.png'),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2), // The background circle around edit
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 14, color: AppColors.background),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.s2),
        const Text(
          'Aryan Sharma',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.s1 / 2),
        const Text(
          'Hostel B, Room 302',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.primary, // 0xFF6366F1
            AppColors.accent,  // 0xFFC084FC
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upgrade to Pro',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlock unlimited roommates &\nadvanced analytics.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(monetizationProvider.notifier).upgradeToPro();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Successfully Upgraded to Pro! (Mock)'))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.rMax),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProActiveCard() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium, color: AppColors.accent, size: 40),
          SizedBox(width: AppDimensions.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Enabled',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                SizedBox(height: 4),
                Text(
                  'Ads removed, unlimited PDF exports.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMonthlyBudgetCard() {
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
            children: [
              _buildIconContainer(Icons.account_balance_wallet_outlined, Colors.lightBlueAccent.withValues(alpha: 0.2), Colors.lightBlueAccent),
              const SizedBox(width: AppDimensions.s2),
              const Text(
                'Monthly Budget',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '₹12,000',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'EDIT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTile({required IconData icon, required String title, required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIconContainer(icon, AppColors.background, AppColors.textMuted),
              const SizedBox(width: AppDimensions.s2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildThemeTile() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIconContainer(Icons.dark_mode, Colors.orangeAccent.withValues(alpha: 0.2), Colors.orangeAccent),
              const SizedBox(width: AppDimensions.s2),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Dark (Auto)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: true,
            onChanged: (val) {},
            activeThumbColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: AppColors.background,
          ),
        ],
      ),
    );
  }

  Widget _buildExportDataCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconContainer(Icons.ios_share, AppColors.background, AppColors.textMuted),
              const SizedBox(width: AppDimensions.s2),
              const Text(
                'Export Data',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s3),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV Export coming soon!')));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.r1),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'CSV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.s2),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final isPro = ref.read(monetizationProvider).isPro;
                    if (!isPro) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upgrade to PRO to unlock PDF exports!')));
                      return;
                    }
                    
                    final analyticsState = ref.read(analyticsProvider);
                    final expensesState = ref.read(expensesProvider);
                    
                    if (analyticsState.value == null || expensesState.value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait for data to load...')));
                      return;
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
                    
                    try {
                      await PdfExportService.generateAndShareFinancialReport(
                        userName: 'Aryan Sharma', // Dynamic user mapping happens here in future
                        recentExpenses: expensesState.value!,
                        analytics: analyticsState.value!,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimensions.r1),
                    ),
                    alignment: Alignment.center,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'PDF',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.workspace_premium, size: 12, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.r2),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'MESS BUDDY V2.4.0 • MADE FOR HOSTELS',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppColors.textMuted.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.r2),
      ),
      child: Icon(icon, color: iconColor, size: 20),
    );
  }
}
