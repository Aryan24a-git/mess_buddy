import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  /// Create a dynamic link for a referral code
  Future<String> createReferralLink(String referralCode) async {
    // ignore: deprecated_member_use
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://messbuddy.page.link', // Replace with your actual prefix
      link: Uri.parse('https://messbuddy.com/signup?ref=$referralCode'),
      androidParameters: const AndroidParameters(
        packageName: 'com.Aryan24a.mess_buddy',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.Aryan24a.mess_buddy',
        minimumVersion: '0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'Join Mess Buddy PRO EXCHANGE!',
        description: 'Use my code $referralCode to get 1 day of FREE Premium!',
        imageUrl: Uri.parse('https://messbuddy.com/assets/promo.png'),
      ),
    );

    // ignore: deprecated_member_use
    final ShortDynamicLink shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  /// Share the referral invite
  Future<void> shareInvite(String referralCode) async {
    try {
      // In debug/emulator, Dynamic Links might fail if not configured in console
      String link;
      if (kDebugMode) {
        link = 'https://messbuddy.com/signup?ref=$referralCode';
      } else {
        link = await createReferralLink(referralCode);
      }

      final String message = 
          '🚀 Join me on Mess Buddy PRO EXCHANGE!\n\n'
          'Manage shared expenses like a pro. Use my referral code to get 1 day of FREE Premium immediately!\n\n'
          'Code: $referralCode\n'
          'Link: $link';

      await SharePlus.instance.share(ShareParams(
        text: message,
        subject: 'Mess Buddy PRO Invite',
      ));
    } catch (e) {
      debugPrint('Error sharing invite: $e');
      // Fallback to basic sharing if dynamic link fails
      await SharePlus.instance.share(ShareParams(
        text: 'Join me on Mess Buddy! Use code: $referralCode',
        subject: 'Mess Buddy Invite',
      ));
    }
  }
}
