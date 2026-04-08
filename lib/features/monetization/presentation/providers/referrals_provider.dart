import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/models/referral_model.dart';

final referralsProvider = StreamProvider<List<ReferralModel>>((ref) {
  final authState = ref.watch(authProvider).value;
  final uid = authState?.user?.uid;
  
  if (uid == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('referrals')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => ReferralModel.fromFirestore(doc)).toList();
      });
});
