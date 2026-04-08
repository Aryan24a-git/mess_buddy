import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/models/referral_model.dart';
import '../providers/earnings_provider.dart';
import '../providers/referrals_provider.dart';
import '../../services/referral_service.dart';

class ReferralDashboardPage extends ConsumerWidget {
  const ReferralDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralCode = ref.watch(referralCodeProvider).value ?? '';
    final referralsAsync = ref.watch(referralsProvider);

    // Auto-generate if missing
    if (referralCode.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(earningsProvider).ensureReferralCode();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Referral Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: referralsAsync.when(
        data: (referrals) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildCodeHeader(context, referralCode)),
              SliverToBoxAdapter(child: _buildHowItWorks()),
              _buildActiveReferralsList(referrals),
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for FAB
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(
          child: Text('Error loading referrals: $err', style: const TextStyle(color: AppColors.error)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildReferMoreFAB(referralCode),
    );
  }

  Widget _buildCodeHeader(BuildContext context, String code) {
    if (code.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(AppDimensions.s4),
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r4),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Your Referral Code', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 12),
          Text(
            code,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard!'), backgroundColor: AppColors.secondary),
                  );
                },
                icon: const Icon(Icons.copy, color: AppColors.textPrimary),
                label: const Text('Copy', style: TextStyle(color: AppColors.textPrimary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.ghostBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => ReferralService().shareInvite(code),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share Code', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }


  Widget _buildHowItWorks() {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How it works', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStep('1', 'Share your code', 'Friend downloads & signs up with your code.'),
          _buildStep('2', '7-Day Streak', 'Friend uses the app 7 days in a row.'),
          _buildStep('3', 'Help us grow!', 'Help your friends organize their mess life with you.'),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
            ),
            alignment: Alignment.center,
            child: Text(number, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReferralsList(List<ReferralModel> referrals) {
    if (referrals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.s4, vertical: 32),
          child: Column(
            children: [
              Icon(Icons.group_off, size: 48, color: AppColors.textMuted),
              SizedBox(height: 16),
              Text("No active referrals yet.", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Share your code to help us grow!", style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.s4),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final ref = referrals[index];
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Referrals', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildReferralTile(ref),
                ],
              );
            }
            return _buildReferralTile(ref);
          },
          childCount: referrals.length,
        ),
      ),
    );
  }

  Widget _buildReferralTile(ReferralModel referral) {
    final name = referral.displayName ?? referral.email ?? 'Referred User';
    final progress = (referral.streakDays / 7).clamp(0.0, 1.0);
    final isCompleted = referral.rewardGranted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppDimensions.pNormal),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: AppColors.ghostBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withValues(alpha: 0.1) : AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.ghostBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : AppColors.primary),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${referral.streakDays}/7 Days',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferMoreFAB(String code) {
    if (code.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s4),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('Refer More Friends', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        onPressed: () => ReferralService().shareInvite(code),
      ),
    );
  }
}
