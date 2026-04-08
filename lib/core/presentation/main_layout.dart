import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/monetization/services/unity_ads_service.dart';
import '../../features/monetization/presentation/providers/earnings_provider.dart';
import '../theme/colors.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context, ref),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            const BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Mess'),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GoRouterState.of(context).uri.toString().startsWith('/add_expense') 
                      ? AppColors.primary 
                      : AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add, 
                  color: GoRouterState.of(context).uri.toString().startsWith('/add_expense') 
                      ? Colors.white 
                      : AppColors.primary, 
                  size: 28
                ),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Roommates'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/mess')) return 1;
    // index 2 is our center button
    if (location.startsWith('/roommates')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    if (index == 2) {
      context.push('/add_expense');
      return;
    }
    
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/mess');
        break;
      case 3:
        // Trigger ad for non-pro users move to roommates
        final isPremium = ref.read(premiumStatusProvider).value?.isPremium ?? false;
        if (!isPremium) {
          UnityAdsService().showInterstitialAd();
        }
        GoRouter.of(context).go('/roommates');
        break;
      case 4:
        GoRouter.of(context).go('/profile');
        break;
    }
  }
}
