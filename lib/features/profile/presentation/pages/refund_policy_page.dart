import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Refund & Cancellation', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pLarge, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroduction(),
            const SizedBox(height: 32),
            _buildStandardSection(
                '1. Subscription Service',
                'Mess Buddy Pro is a subscription-based service. Once a subscription is activated, it provides immediate access to premium features for the duration of the subscription period.'
            ),
            _buildStandardSection(
                '2. Cancellation Policy',
                'You may cancel your subscription at any time. Cancellation will take effect at the end of the current billing cycle, and you will continue to have access to premium features until then. We do not provide prorated refunds for partial subscription periods.'
            ),
            _buildStandardSection(
                '3. Refund Eligibility',
                'Refunds are typically only granted for technical issues that we are unable to resolve. If you experience a problem, please contact support with details including your Transaction ID.'
            ),
            _buildStandardSection(
                '4. Google Play/App Store Billing',
                'If your subscription was purchased through the Google Play Store or Apple App Store, refunds must be requested directly through their respective platforms according to their policies.'
            ),
            _buildStandardSection(
                '5. Processing Time',
                'For approved direct refunds, please allow 5-7 business days for the credit to appear in your account.'
            ),
            _buildStandardSection(
                '6. Contact Support',
                'For any billing or refund concerns, please email us at supportmessbuddy@gmail.com.'
            ),
            const SizedBox(height: 40),
            _buildClosingNote(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last Updated: April 7, 2026',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const Text(
          'Refund & Cancellation',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Text(
          'Thank you for using Mess Buddy! Our goal is to ensure a satisfying experience for all users.',
          style: TextStyle(color: AppColors.textPrimary.withValues(alpha: 0.8), fontSize: 15, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStandardSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosingNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Text(
          'For more information, please read our Terms and Conditions.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
    );
  }
}
