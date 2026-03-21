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

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/mess',
            builder: (context, state) => const MessPage(),
          ),
          GoRoute(
            path: '/roommates',
            builder: (context, state) => const RoommatesPage(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsPage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: '/goals',
            builder: (context, state) => const GoalsPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/add_expense',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AddExpensePage(),
        ),
      ),
    ],
  );
}
