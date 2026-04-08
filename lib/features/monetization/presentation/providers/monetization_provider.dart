import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulating local purchase status, usually tied with shared_prefs or store plugin
class MonetizationState {
  final bool isPro;
  final DateTime? premiumExpiresAt;

  MonetizationState({this.isPro = false, this.premiumExpiresAt});

  MonetizationState copyWith({bool? isPro, DateTime? premiumExpiresAt}) {
    return MonetizationState(
      isPro: isPro ?? this.isPro,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
    );
  }
}

class MonetizationNotifier extends StateNotifier<MonetizationState> {
  MonetizationNotifier() : super(MonetizationState());

  bool get isPro {
    if (state.premiumExpiresAt != null && DateTime.now().isBefore(state.premiumExpiresAt!)) {
      return true;
    }
    return state.isPro; 
  }

  // Update expiry from Firestore
  void syncFirestoreExpiry(DateTime expiry) {
    state = state.copyWith(
      isPro: true,
      premiumExpiresAt: expiry,
    );
  }

  void downgradeToFree() {
    state = state.copyWith(isPro: false, premiumExpiresAt: null);
  }
}

final monetizationProvider = StateNotifierProvider<MonetizationNotifier, MonetizationState>((ref) {
  return MonetizationNotifier();
});
