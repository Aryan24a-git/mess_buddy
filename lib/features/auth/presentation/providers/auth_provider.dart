import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/auth_repository.dart';
import '../../domain/user_profile.dart';
import '../../../dashboard/presentation/providers/expenses_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final firebaseUserProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

class AuthState {
  final User? user;
  final UserProfile? profile;
  
  AuthState({this.user, this.profile});

  bool get isAuthenticated => user != null;
  bool get hasProfile => profile != null && profile!.name.isNotEmpty && profile!.monthlyBudget > 0;
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final user = await ref.watch(firebaseUserProvider.future);
      if (user == null) return AuthState();

      final repo = ref.read(authRepositoryProvider);
      final profile = await repo.getProfile();
      
      if (profile != null && profile.monthlyBudget > 0) {
        _syncBudget(profile.monthlyBudget);
      }
      
      _logAppSession(user.uid);
      return AuthState(user: user, profile: profile);
    } catch (e) {
      return AuthState();
    }
  }

  void _syncBudget(double monthlyBudget) {
    Future.microtask(() {
      ref.read(totalBudgetProvider.notifier).setBudget(monthlyBudget);
      ref.read(dailyBudgetProvider.notifier).setBudget(monthlyBudget / 30);
    });
  }

  Future<void> signInWithGoogle({String? referralCode}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithGoogle();
      final user = result.credential.user;
      
      // If it's a new user and they provided a referral code, grant bonus!
      if (result.isNewUser && referralCode != null && referralCode.isNotEmpty) {
        try {
          await FirebaseFunctions.instance
              .httpsCallable('grantReferralBonus')
              .call({'code': referralCode});
        } catch (e) {
          debugPrint('Error granting google referral bonus: $e');
        }
      }

      final profile = await repo.getProfile();
      if (profile != null && profile.monthlyBudget > 0) {
        _syncBudget(profile.monthlyBudget);
      }
      
      if (user != null) _logAppSession(user.uid);
      state = AsyncValue.data(AuthState(user: user, profile: profile));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? referralCode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signUpWithEmail(email: email, password: password, name: name);
      final user = cred.user;

      // Handle referral bonus for email signup
      if (referralCode != null && referralCode.isNotEmpty) {
        try {
          await FirebaseFunctions.instance
              .httpsCallable('grantReferralBonus')
              .call({'code': referralCode});
        } catch (e) {
          debugPrint('Error granting email referral bonus: $e');
        }
      }

      final profile = await repo.getProfile();
      if (profile != null && profile.monthlyBudget > 0) {
        _syncBudget(profile.monthlyBudget);
      }
      
      if (user != null) _logAppSession(user.uid);
      state = AsyncValue.data(AuthState(user: user, profile: profile));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.loginWithEmail(email: email, password: password);
      final user = FirebaseAuth.instance.currentUser;
      final profile = await repo.getProfile();
      
      if (profile != null && profile.monthlyBudget > 0) {
        _syncBudget(profile.monthlyBudget);
      }
      
      if (user != null) _logAppSession(user.uid);
      state = AsyncValue.data(AuthState(user: user, profile: profile));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final cred = await repo.signInAnonymously();
      final user = cred.user;
      final profile = await repo.getProfile();
      
      if (profile != null && profile.monthlyBudget > 0) {
        _syncBudget(profile.monthlyBudget);
      }
      
      if (user != null) _logAppSession(user.uid);
      state = AsyncValue.data(AuthState(user: user, profile: profile));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> setupProfile(UserProfile profile) async {
    final repo = ref.read(authRepositoryProvider);
    await repo.saveProfile(profile);
    
    if (profile.monthlyBudget > 0) {
      _syncBudget(profile.monthlyBudget);
    }
    
    final user = FirebaseAuth.instance.currentUser;
    state = AsyncValue.data(AuthState(user: user, profile: profile));
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AsyncValue.data(AuthState());
  }
  Future<void> _logAppSession(String uid) async {
    final date = DateTime.now().toUtc().toIso8601String().split('T')[0];
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('appSessions')
          .doc(date)
          .set({'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error logging app session: $e');
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
