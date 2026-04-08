import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../services/payment_service.dart';

class UnlockProPage extends ConsumerStatefulWidget {
  const UnlockProPage({super.key});

  @override
  ConsumerState<UnlockProPage> createState() => _UnlockProPageState();
}

class _UnlockProPageState extends ConsumerState<UnlockProPage> {
  late ConfettiController _confettiController;
  late PaymentService _paymentService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _paymentService = PaymentService();
    _paymentService.onSuccess = () {
      setState(() => _isLoading = false);
      _confettiController.play();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium Unlocked Successfully!'), backgroundColor: AppColors.success),
        );
      }
    };
    _paymentService.onError = (error) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    };
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _confettiController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('PRO EXCHANGE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pNormal, vertical: AppDimensions.pLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Elevate Your Experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock premium features with cash.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.s4),
                  
                  _buildPricingCard(
                    days: 30, // 1 month
                    titlePrefix: "1 Month",
                    costText: '₹49',
                    costValue: 49,
                    icon: Icons.flash_on,
                  ),
                  const SizedBox(height: AppDimensions.s3),
                  _buildPricingCard(
                    days: 180, // 6 months
                    titlePrefix: "6 Months",
                    costText: '₹259',
                    costValue: 259,
                    isBestValue: true,
                    icon: Icons.star,
                  ),
                  const SizedBox(height: AppDimensions.s3),
                  _buildPricingCard(
                    days: 365, // 1 year
                    titlePrefix: "1 Year",
                    costText: '₹499',
                    costValue: 499,
                    icon: Icons.workspace_premium,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          
          // Confetti overlay at top center
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [AppColors.primary, AppColors.secondary, Colors.white, Colors.orangeAccent],
            ),
          ),
          
          // Global Loading Indicator block
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required int days,
    required int costValue,
    required String costText,
    required IconData icon,
    bool isBestValue = false,
    String? titlePrefix,
  }) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(AppDimensions.pLarge),
      decoration: BoxDecoration(
        color: isBestValue ? AppColors.primary.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isBestValue ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          if (isBestValue)
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ).blurred(60),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isBestValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text('BEST VALUE', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isBestValue ? AppColors.primary : AppColors.secondary).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: isBestValue ? AppColors.primary : AppColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(titlePrefix != null ? '$titlePrefix Pro' : '$days Days Pro', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                          const Text('Unlock Everything', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        costText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Feature list directly in the card as requested
              _buildFeatureRow('Remove all ads'),
              const SizedBox(height: 8),
              _buildFeatureRow('Unlock all features'),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading 
                    ? null 
                    : () {
                        setState(() => _isLoading = true);
                        final userEmail = ref.read(authProvider).value?.profile?.email;
                        _paymentService.openCheckout(
                          amountInRupees: costValue, 
                          name: 'Mess Buddy', 
                          description: titlePrefix != null ? '$titlePrefix Pro' : '$days Days Pro Unlock',
                          planDays: days,
                          email: userEmail,
                        ).catchError((e) {
                          setState(() => _isLoading = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                            );
                          }
                        });
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    elevation: isBestValue ? 10 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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
