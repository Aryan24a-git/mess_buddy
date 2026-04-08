import 'dart:math';

class ReferralUtils {
  /// Generates a unique 5-digit alphanumeric referral code (e.g., A5B2D)
  static String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(5, (_) => chars.codeUnitAt(rnd.nextInt(chars.length)))
    );
  }
}
