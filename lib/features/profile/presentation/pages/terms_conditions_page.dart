import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Terms & Conditions', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
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
                '1. Acceptance of Terms',
                'By accessing or using Mess Buddy, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use the service.'
            ),
            _buildStandardSection(
                '2. User Account',
                'You are responsible for maintaining the confidentiality of your account and password. You agree to notify us immediately of any unauthorized use of your account.'
            ),
            _buildStandardSection(
                '3. Use of Service',
                'Mess Buddy is provided for personal use only. You may not use the service for any illegal or unauthorized purpose.'
            ),
            _buildStandardSection(
                '4. Data Privacy',
                'We value your privacy. Please refer to our Privacy Policy for details on how we collect and use your information.'
            ),
            _buildStandardSection(
                '5. Limitations of Liability',
                'Mess Buddy is provided "as is" without any warranties. We are not liable for any damages arising from your use of the service.'
            ),
            _buildStandardSection(
                '6. Modifications to Terms',
                'We reserve the right to modify these terms at any time. Your continued use of the service constitutes acceptance of the new terms.'
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
          'Welcome to Mess Buddy!',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Text(
          'These Terms and Conditions govern your use of our application. Please read them carefully.',
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
              color: AppColors.primary,
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
          'If you have any questions about these Terms, please contact us at supportmessbuddy@gmail.com.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
    );
  }
}
