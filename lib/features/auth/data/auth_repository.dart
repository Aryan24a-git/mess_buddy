import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_profile.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const _keyMonthlyBudget = 'monthlyBudget';
  static const _keyRoomNo = 'roomNo';
  static const _keyRoommateName = 'roommateName';
  static const _keyHostelName = 'hostelName';
  static const _keyProfilePicPath = 'profilePicPath';
  static const _keyProfileComplete = 'profileComplete';

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserProfile?> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    
    String? referralCode;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        referralCode = doc.data()?['referralCode'];
      }
    } catch (e) {
      debugPrint('Error fetching firestore profile: $e');
    }

    final isComplete = prefs.getBool(_keyProfileComplete) ?? false;
    if (!isComplete) {
      return UserProfile(
        name: user.displayName ?? '',
        email: user.email ?? '',
        monthlyBudget: 0,
        loginMethod: _loginMethod(user),
        profilePicPath: user.photoURL,
        referralCode: referralCode,
      );
    }

    return UserProfile(
      name: user.displayName ?? prefs.getString('userName') ?? '',
      email: user.email ?? '',
      monthlyBudget: prefs.getDouble(_keyMonthlyBudget) ?? 0,
      roomNo: prefs.getString(_keyRoomNo),
      roommateName: prefs.getString(_keyRoommateName),
      hostelName: prefs.getString(_keyHostelName),
      loginMethod: _loginMethod(user),
      profilePicPath: prefs.getString(_keyProfilePicPath) ?? user.photoURL,
      referralCode: referralCode,
    );
  }

  String _loginMethod(User user) {
    if (user.isAnonymous) return 'guest';
    final providers = user.providerData.map((p) => p.providerId).toList();
    if (providers.contains('google.com')) return 'google';
    return 'email';
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProfileComplete, true);
    await prefs.setString('userName', profile.name);
    await prefs.setDouble(_keyMonthlyBudget, profile.monthlyBudget);
    if (profile.roomNo != null) await prefs.setString(_keyRoomNo, profile.roomNo!);
    if (profile.roommateName != null) await prefs.setString(_keyRoommateName, profile.roommateName!);
    if (profile.hostelName != null) await prefs.setString(_keyHostelName, profile.hostelName!);
    if (profile.profilePicPath != null) {
      await prefs.setString(_keyProfilePicPath, profile.profilePicPath!);
    } else {
      await prefs.remove(_keyProfilePicPath);
    }

    final user = _auth.currentUser;
    if (user != null && user.displayName != profile.name) {
      await user.updateDisplayName(profile.name);
    }
  }

  Future<({UserCredential credential, bool isNewUser})> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google login cancelled by user.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final result = await _auth.signInWithCredential(credential);
      return (credential: result, isNewUser: result.additionalUserInfo?.isNewUser ?? false);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);
    await cred.user?.reload();
    return cred;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  Future<bool> isLoggedIn() async => _auth.currentUser != null;
}
