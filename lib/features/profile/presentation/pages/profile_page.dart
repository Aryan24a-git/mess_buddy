import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../features/monetization/presentation/providers/monetization_provider.dart';
import '../../../../features/export/services/pdf_export_service.dart';
import '../../../../features/export/services/excel_export_service.dart';
import '../../../../features/dashboard/presentation/providers/expenses_provider.dart';
import '../../../../features/analytics/presentation/providers/analytics_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

// Import the specific charts/painters we'll use from analytics
// (Assuming we might need to expose them or just import the page if it's embeddable)
import '../../../../features/analytics/presentation/pages/analytics_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (kIsWeb) {
      if (path.startsWith('data:image')) {
        final base64Content = path.split(',').last;
        return MemoryImage(base64Decode(base64Content));
      }
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authData = authState.value;
    final user = authData?.profile;
    final uid = authData?.user?.uid;
    
    if (user == null || uid == null) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile Setting', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pro mode is coming soon!', style: TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.workspace_premium, color: AppColors.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pNormal, vertical: AppDimensions.pLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildProfileInfo(context, user, uid),
              const SizedBox(height: AppDimensions.s4),
              _buildMonthlyBudgetCard(context, user),
              const SizedBox(height: AppDimensions.s4),
              const _EmbeddedAnalyticsSection(),
              const SizedBox(height: AppDimensions.s3),
              _buildActionGrid(context, ref, user.name),
              const SizedBox(height: AppDimensions.s4),
              _buildCustomerCareSection(context),
              const SizedBox(height: AppDimensions.s4),
              const Text('Version 1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppDimensions.pHuge * 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, var user, String uid) {
    final hostelInfo = [
      if (user?.hostelName != null) user!.hostelName,
      if (user?.roomNo != null) 'Room ${user!.roomNo}',
    ].join(', ');

    return Column(
      children: [
        GestureDetector(
          onTap: () => context.push('/edit-profile'),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceVariant,
                  backgroundImage: _getImageProvider(user?.profilePicPath),
                  child: user?.profilePicPath == null 
                      ? const Icon(Icons.person, size: 48, color: AppColors.textMuted)
                      : null,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.s2),
        Text(
          user?.name ?? 'Guest User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hostelInfo.isNotEmpty ? hostelInfo : 'No hostel info set',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (user?.roommateName != null) ...[
          const SizedBox(height: 2),
          Text(
            'Roommate: ${user!.roommateName}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
        const SizedBox(height: 12),
        _buildUidField(context, uid),
      ],
    );
  }

  Widget _buildUidField(BuildContext context, String uid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: uid));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile ID Copied!'), behavior: SnackBarBehavior.floating),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ID: ', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(
              uid.length > 12 ? '${uid.substring(0, 12)}...' : uid,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.copy, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }


  Widget _buildMonthlyBudgetCard(BuildContext context, var user) {
    return GestureDetector(
      onTap: () => context.push('/edit-profile'),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.pLarge),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet, color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Monthly Budget', style: TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${user?.monthlyBudget?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(100)),
                  child: const Text('EDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context, WidgetRef ref, String userName) {
    final bool isPro = ref.watch(monetizationProvider.select((m) => m.isPro));

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildGridItem(
          icon: Icons.flag,
          title: 'Budget Goals',
          color: AppColors.primary,
          onTap: () {
            if (isPro) {
              context.push('/goals');
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Pro mode is coming soon!', style: TextStyle(color: Colors.white)),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          },
        ),
        _buildGridItem(
          icon: Icons.download,
          title: 'Data Export',
          color: AppColors.secondary,
          onTap: () => _showExportOptions(context, ref, userName, isPro),
        ),
        _buildGridItem(
          icon: Icons.refresh,
          title: 'Reset Account',
          color: Colors.orangeAccent,
          onTap: () => _handleReset(context, ref),
        ),
        _buildGridItem(
          icon: Icons.logout,
          title: 'Sign Out',
          color: AppColors.error,
          onTap: () => _handleLogout(context, ref),
        ),
      ],
    );
  }

  Widget _buildGridItem({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref, String userName, bool isPro) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Export Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.primary),
              title: const Text('Export as Excel (.xlsx)', style: TextStyle(color: AppColors.textPrimary)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              onTap: () async {
                Navigator.pop(ctx);
                final analyticsState = ref.read(analyticsProvider);
                final expensesState = ref.read(expensesProvider);
                if (analyticsState.value == null || expensesState.value == null) return;


                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing Excel Sheet...')));
                try {
                  await ExcelExportService.exportToExcel(
                    userName: userName,
                    expenses: expensesState.value!,
                    analytics: analyticsState.value!,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.secondary),
              title: const Text('Export as PDF', style: TextStyle(color: AppColors.textPrimary)),
              trailing: !isPro ? const Icon(Icons.lock, color: AppColors.textMuted, size: 16) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              tileColor: Colors.white.withValues(alpha: 0.05),
              onTap: () async {
                Navigator.pop(ctx);
                if (!isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Pro mode is coming soon!', style: TextStyle(color: Colors.white)),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ));
                  return;
                }
                final analyticsState = ref.read(analyticsProvider);
                final expensesState = ref.read(expensesProvider);
                if (analyticsState.value == null || expensesState.value == null) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF Report...')));
                try {
                  await PdfExportService.generateAndShareFinancialReport(
                    userName: userName,
                    recentExpenses: expensesState.value!,
                    analytics: analyticsState.value!,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handleReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Reset Profile?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will clear your local profile. Expenses will remain.', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(ctx);
              context.go('/setup');
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Reset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out from Mess Buddy?', style: TextStyle(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(ctx);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  Widget _buildCustomerCareSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'CONTACT WITH US',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(AppDimensions.pNormal),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _buildContactItem(
                context,
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'supportmessbuddy@gmail.com',
                color: Colors.redAccent,
                onTap: () => _launchURL('mailto:supportmessbuddy@gmail.com?subject=Mess Buddy Support'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white10),
              ),
              _buildContactItem(
                context,
                icon: Icons.camera_alt_outlined,
                title: 'Instagram',
                subtitle: '@codex_aryan24',
                color: Colors.purpleAccent,
                onTap: () => _launchURL('https://www.instagram.com/codex_aryan24?utm_source=ig_web_button_share_sheet&igsh=ZDNlZDc0MzIxNw=='),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white10),
              ),
              _buildContactItem(
                context,
                icon: Icons.feedback_outlined,
                title: 'Feedback',
                subtitle: 'Help us improve',
                color: Colors.amberAccent,
                onTap: () {
                  const url = "https://docs.google.com/forms/d/e/1FAIpQLSdWzcmliiONVj3w5kuLA2fgy3zGEip9T0cDinhUUKLC7fzEUA/viewform?usp=publish-editor";
                  if (kIsWeb) {
                    _launchURL(url);
                  } else {
                    context.push('/feedback');
                  }
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white10),
              ),
              _buildContactItem(
                context,
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read our policies',
                color: Colors.blueAccent,
                onTap: () => context.push('/terms'),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(color: Colors.white10),
              ),
              _buildContactItem(
                context,
                icon: Icons.assignment_return_outlined,
                title: 'Refund Policy',
                subtitle: 'Cancellation & Refunds',
                color: Colors.orangeAccent,
                onTap: () => context.push('/refund-policy'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }
}

class _EmbeddedAnalyticsSection extends ConsumerWidget {
  const _EmbeddedAnalyticsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);

    return analyticsState.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'FINANCIAL ANALYTICS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppDimensions.pLarge),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly Spending',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    Text(
                      '₹${data.monthlySpending.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: TrendChartPainter(
                      data.dailyCumulativeSpending,
                      DateTime.now().day,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatMini(
                      label: 'Burn Rate',
                      value: '₹${data.burnRate.toStringAsFixed(0)}',
                      icon: Icons.local_fire_department,
                      color: Colors.orangeAccent,
                    ),
                    _buildStatMini(
                      label: 'Best Category',
                      value: data.mostSpentCategory,
                      icon: Icons.pie_chart_outline,
                      color: AppColors.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => context.push('/analytics'),
                    child: const Text('VIEW DETAILED REPORT', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMini({required String label, required String value, required IconData icon, required Color color}) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Extension to help blur containers without nested BackDropFilters going wild
extension WidgetExtensions on Widget {
  Widget blurred(double sigmaX) {
    return ImageFilterWrapper(sigmaX: sigmaX, child: this);
  }
}

class ImageFilterWrapper extends StatelessWidget {
  final Widget child;
  final double sigmaX;
  const ImageFilterWrapper({super.key, required this.child, required this.sigmaX});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaX),
      child: child,
    );
  }
}
