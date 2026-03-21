import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulating local purchase status, usually tied with shared_prefs or store plugin
class MonetizationState {
  final bool isPro;

  MonetizationState({this.isPro = false});

  MonetizationState copyWith({bool? isPro}) {
    return MonetizationState(isPro: isPro ?? this.isPro);
  }
}

class MonetizationNotifier extends StateNotifier<MonetizationState> {
  MonetizationNotifier() : super(MonetizationState());

  bool get isPro => state.isPro;

  // Upgrade user to pro
  void upgradeToPro() {
    state = state.copyWith(isPro: true);
  }

  // Debug function
  void downgradeToFree() {
    state = state.copyWith(isPro: false);
  }
}

final monetizationProvider = StateNotifierProvider<MonetizationNotifier, MonetizationState>((ref) {
  return MonetizationNotifier();
});
