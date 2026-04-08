import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/colors.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'features/auth/presentation/pages/welcome_signup_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'core/presentation/main_layout.dart';
import 'core/presentation/terms_consent_overlay.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/mess/presentation/pages/mess_page.dart';
import 'features/roommates/presentation/pages/roommates_page.dart';
import 'features/analytics/presentation/pages/analytics_page.dart';
import 'features/goals/presentation/pages/goals_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/add_expense/presentation/pages/add_expense_page.dart';
import 'features/monetization/presentation/pages/referral_dashboard_page.dart';
import 'features/monetization/presentation/pages/unlock_pro_page.dart';
import 'features/profile/presentation/pages/feedback_page.dart';
import 'features/profile/presentation/pages/terms_conditions_page.dart';
import 'features/profile/presentation/pages/refund_policy_page.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'features/monetization/services/unity_ads_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Parallel initialization tasks
  final futures = [
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(), // Pre-warm the cache
  ];
  
  await Future.wait(futures);

  // Initialize Ads
  await MobileAds.instance.initialize();
  await UnityAdsService().init();

  /* 
  if (kDebugMode) {
    try {
      // Connect to local emulators in debug mode
      // 10.0.2.2 for Android emulators, localhost for Web/Desktop/iOS
      String host = "localhost";
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        host = "10.0.2.2";
      }
      
      FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      debugPrint("Connected to Firebase Emulators at $host");
    } catch (e) {
      debugPrint("Error connecting to emulators: $e");
    }
  }
  */
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router = GoRouter(
    navigatorKey: AppRouter.rootNavigatorKey,
    initialLocation: '/welcome',
    redirect: (context, state) {
      final authData = ref.read(authProvider);
      
      // We handle loading at the app level, so the router just waits.
      if (authData.isLoading) return null;

      final auth = authData.value;
      if (auth == null) return null;

      final loc = state.matchedLocation;
      final isAuthPage = loc == '/welcome' || loc == '/login';
      final isSetupPage = loc == '/setup';

      // 1. Not Authenticated → Show Welcome/Login
      if (!auth.isAuthenticated) {
        return (isAuthPage) ? null : '/welcome';
      }

      // 2. Authenticated but No Profile → Forces Setup
      if (!auth.hasProfile) {
        return (isSetupPage) ? null : '/setup';
      }

      // 3. Authenticated and Profile Complete → Redirect away from Auth/Setup
      if (isAuthPage || isSetupPage) {
        return '/';
      }

      return null;
    },
    refreshListenable: _AuthStateNotifier(ref),
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeSignupPage()),
      GoRoute(path: '/login',   builder: (_, __) => const LoginPage()),
      GoRoute(path: '/setup',   builder: (_, __) => const ProfileSetupPage()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const ProfileSetupPage(isEditing: true)),

      ShellRoute(
        navigatorKey: AppRouter.shellNavigatorKey,
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(path: '/',          builder: (_, __) => const DashboardPage()),
          GoRoute(path: '/mess',      builder: (_, __) => const MessPage()),
          GoRoute(path: '/roommates', builder: (_, __) => const RoommatesPage()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsPage()),
          GoRoute(path: '/profile',   builder: (_, __) => const ProfilePage()),
          GoRoute(path: '/goals',     builder: (_, __) => const GoalsPage()),
          GoRoute(path: '/referrals',  builder: (_, __) => const ReferralDashboardPage()),
          GoRoute(path: '/unlock-pro', builder: (_, __) => const UnlockProPage()),
          GoRoute(path: '/feedback', builder: (_, __) => const FeedbackPage()),
          GoRoute(path: '/terms', builder: (_, __) => const TermsConditionsPage()),
          GoRoute(path: '/refund-policy', builder: (_, __) => const RefundPolicyPage()),
        ],
      ),

      GoRoute(
        path: '/add_expense',
        parentNavigatorKey: AppRouter.rootNavigatorKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: true,
          child: AddExpensePage(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp.router(
      title: 'Mess Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: _router,
      builder: (context, child) {
        if (authState.isLoading) {
          return const _InitializationOverlay(isLoading: true);
        }
        if (authState.hasError) {
          return _InitializationOverlay(error: authState.error.toString());
        }
        return TermsConsentOverlay(child: child!);
      },
    );
  }
}

class _InitializationOverlay extends StatelessWidget {
  final bool isLoading;
  final String? error;
  const _InitializationOverlay({this.isLoading = false, this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const CircularProgressIndicator(color: AppColors.primary)
              else ...[
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  error ?? 'An unexpected error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(WidgetRef ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
