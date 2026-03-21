import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/roommates_provider.dart';

class RoommatesPage extends ConsumerWidget {
  const RoommatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roommatesState = ref.watch(roommatesProvider);

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
              _buildTitleRow(),
              const SizedBox(height: AppDimensions.s4),
              _buildOweCard(
                title: 'Total You Owe',
                amount: '₹450',
                status: 'PENDING',
                statusColor: Colors.orangeAccent,
                borderColor: Colors.orangeAccent,
                showAvatars: true,
                showSettleButton: false,
              ),
              const SizedBox(height: AppDimensions.s2),
              _buildOweCard(
                title: 'Others Owe You',
                amount: '₹1,200',
                status: 'RECEIVABLE',
                statusColor: Colors.cyanAccent,
                borderColor: Colors.cyanAccent,
                showAvatars: false,
                showSettleButton: true,
              ),
              const SizedBox(height: AppDimensions.s4),
              const Text(
                'ACTIVE CIRCLE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppDimensions.s2),
              roommatesState.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (error, _) => Center(child: Text('Error: $error', style: const TextStyle(color: Colors.red))),
                data: (roommates) {
                  if (roommates.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppDimensions.pNormal),
                      child: Text('No roommates added yet.', style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return Column(
                    children: roommates.map((roommate) {
                      return _buildRoommateItem(
                        name: roommate.name,
                        subtitle: roommate.phone.isNotEmpty ? roommate.phone : 'Added recently',
                        amount: '₹0', // Placeholder until expenses are linked
                        status: 'SETTLED',
                        statusColor: Colors.white.withValues(alpha: 0.3),
                        avatarInitials: roommate.name.isNotEmpty ? roommate.name[0].toUpperCase() : '?',
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: AppDimensions.s4),
              _buildQuickSplitCard(),
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

  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roommates',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage shared expenses',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(AppDimensions.rMax),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppDimensions.rMax),
              onTap: () {},
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1, size: 16, color: AppColors.background),
                    SizedBox(width: 8),
                    Text(
                      'Add\nRoommate',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOweCard({
    required String title,
    required String amount,
    required String status,
    required Color statusColor,
    required Color borderColor,
    required bool showAvatars,
    required bool showSettleButton,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.r3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 100, // Explicit height to match typical card content height
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.r3),
                bottomLeft: Radius.circular(AppDimensions.r3),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s1),
                  Row(
                    children: [
                      Text(
                        amount,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.s1),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.s2),
                  if (showAvatars)
                    Row(
                      children: [
                        _buildAvatarStack('R'),
                        const SizedBox(width: AppDimensions.s1),
                        _buildAvatarStack('S'),
                      ],
                    ),
                  if (showSettleButton)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppDimensions.rMax),
                      ),
                      child: const Text(
                        'Settle Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.background,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarStack(String initials) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.surfaceTranslucent,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildRoommateItem({
    required String name,
    required String subtitle,
    required String amount,
    required String status,
    required Color statusColor,
    required String avatarInitials,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.background,
                child: Text(
                  avatarInitials,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppDimensions.s2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSplitCard() {
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppDimensions.r2),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.lightBlueAccent, size: 24),
              ),
              const SizedBox(width: AppDimensions.s2),
              const Text(
                'Quick Split',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s4),
          const Text(
            'WHO PAID?',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppDimensions.s2),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildWhoPaidChip(name: 'Me', isSelected: true, initials: 'M'),
                const SizedBox(width: AppDimensions.s2),
                _buildWhoPaidChip(name: 'Rohan', isSelected: false, initials: 'R'),
                const SizedBox(width: AppDimensions.s2),
                _buildWhoPaidChip(name: 'Sameer', isSelected: false, initials: 'S'),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pLarge, vertical: AppDimensions.pHuge),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.r3),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 24,
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppDimensions.s1),
                Expanded(
                  child: TextFormField(
                    initialValue: '0.00',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted.withValues(alpha: 0.3), // Faded per design
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s3),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.r3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.r3 - 4),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Equal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppDimensions.s2),
                    alignment: Alignment.center,
                    child: const Text(
                      'Custom',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.s4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppDimensions.r3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Text(
              'Split with Circle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhoPaidChip({required String name, required bool isSelected, required String initials}) {
    return Container(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : AppColors.background,
        borderRadius: BorderRadius.circular(AppDimensions.rMax),
        border: Border.all(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: AppDimensions.s1),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
