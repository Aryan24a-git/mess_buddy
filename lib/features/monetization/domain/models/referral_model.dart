import 'package:cloud_firestore/cloud_firestore.dart';

class ReferralModel {
  final String id;
  final String? referredUid;
  final String? displayName;
  final String? email;
  final int streakDays;
  final bool rewardGranted;
  final int creditsEarned;
  final DateTime? streakStartedAt;

  const ReferralModel({
    required this.id,
    this.referredUid,
    this.displayName,
    this.email,
    required this.streakDays,
    required this.rewardGranted,
    this.creditsEarned = 0,
    this.streakStartedAt,
  });

  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      return ReferralModel(
        id: doc.id,
        streakDays: 0,
        rewardGranted: false,
      );
    }

    return ReferralModel(
      id: doc.id,
      referredUid: data['referredUid'] as String?,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      streakDays: data['streakDays'] as int? ?? 0,
      rewardGranted: data['rewardGranted'] as bool? ?? false,
      creditsEarned: data['creditsEarned'] as int? ?? 0,
      streakStartedAt: (data['streakStartedAt'] as Timestamp?)?.toDate(),
    );
  }
}
