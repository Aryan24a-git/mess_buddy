import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/main_layout.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/mess/presentation/pages/mess_page.dart';
import '../../features/roommates/presentation/pages/roommates_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/goals/presentation/pages/goals_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/add_expense/presentation/pages/add_expense_page.dart';
import '../../features/auth/presentation/pages/profile_setup_page.dart';
import '../../features/monetization/presentation/pages/referral_dashboard_page.dart';
import '../../features/profile/presentation/pages/feedback_page.dart';
import '../../features/profile/presentation/pages/terms_conditions_page.dart';
import '../../features/profile/presentation/pages/refund_policy_page.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Static fallback router (auth-aware router is built in main.dart via ConsumerWidget).
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/setup',
    routes: [
      GoRoute(path: '/setup', builder: (_, __) => const ProfileSetupPage()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const ProfileSetupPage(isEditing: true)),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/',           builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/mess',       builder: (_, __) => const MessPage()),
          GoRoute(path: '/roommates',  builder: (_, __) => const RoommatesPage()),
          GoRoute(path: '/analytics',  builder: (_, __) => const AnalyticsPage()),
          GoRoute(path: '/profile',    builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/goals',      builder: (_, __) => const GoalsPage()),
          GoRoute(path: '/referrals',  builder: (_, __) => const ReferralDashboardPage()),
          GoRoute(path: '/feedback', builder: (_, __) => const FeedbackPage()),
          GoRoute(path: '/terms', builder: (_, __) => const TermsConditionsPage()),
          GoRoute(path: '/refund-policy', builder: (_, __) => const RefundPolicyPage()),
        ],
      ),
      GoRoute(
        path: '/add_expense',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: true,
          child: AddExpensePage(),
        ),
      ),
    ],
  );
}
