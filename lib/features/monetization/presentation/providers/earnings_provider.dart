import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';


import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/utils/referral_utils.dart';


class PremiumStatus {
  final bool isPremium;
  final DateTime? premiumExpiresAt;

  const PremiumStatus({
    this.isPremium = false,
    this.premiumExpiresAt,
  });
}


final premiumStatusProvider = StreamProvider<PremiumStatus>((ref) {
  final authState = ref.watch(authProvider).value;
  final uid = authState?.user?.uid;
  if (uid == null) return Stream.value(const PremiumStatus());

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return const PremiumStatus();
        
        final isPremium = data['isPremium'] as bool? ?? false;
        final timestamp = data['premiumExpiresAt'] as Timestamp?;
        
        return PremiumStatus(
          isPremium: isPremium,
          premiumExpiresAt: timestamp?.toDate(),
        );
      });
});

final referralCodeProvider = StreamProvider<String>((ref) {
  final authState = ref.watch(authProvider).value;
  final uid = authState?.user?.uid;
  if (uid == null) return Stream.value('');

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => (doc.data()?['referralCode'] as String?) ?? '');
});


final earningsProvider = Provider<EarningsService>((ref) {
  return EarningsService(ref);
});

class EarningsService {
  final Ref ref;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  EarningsService(this.ref);

  Future<void> ensureReferralCode() async {
    final authState = ref.read(authProvider).value;
    final uid = authState?.user?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && (doc.data()?['referralCode'] == null || doc.data()?['referralCode'] == '')) {
      final code = ReferralUtils.generateCode();
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'referralCode': code,
      });
      ref.invalidate(referralCodeProvider);
    }
  }



  Future<void> applyReferralCode(String code) async {
    try {
      await _functions.httpsCallable('grantReferralBonus').call({'code': code});
    } catch (e) {
      if (e is FirebaseFunctionsException) {
         throw Exception(e.message ?? 'Invalid code');
      }
      throw Exception("Failed to apply code.");
    }
  }
}


