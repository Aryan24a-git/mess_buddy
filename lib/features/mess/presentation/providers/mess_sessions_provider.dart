import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/mess_session.dart';
import '../../domain/repositories/mess_repository.dart';
import '../../data/repositories/sqlite_mess_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the repository
final messRepositoryProvider = Provider<MessRepository>((ref) {
  return SqliteMessRepository();
});

// StateNotifier for the specific date's mess sessions
class MessSessionsNotifier extends StateNotifier<AsyncValue<List<MessSession>>> {
  final MessRepository _repository;
  DateTime _currentDate = DateTime.now();

  MessSessionsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSessionsForDate(_currentDate);
  }

  DateTime get currentDate => _currentDate;

  Future<void> loadSessionsForDate(DateTime date) async {
    _currentDate = date;
    try {
      state = const AsyncValue.loading();
      final sessions = await _repository.getSessionsForDate(date);
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSessionAttendance(String type, bool isAttending, double cost) async {
    final currentState = state.value;
    if (currentState == null) return;

    final existingIndex = currentState.indexWhere((s) => s.sessionType == type);
    MessSession session;

    if (existingIndex != -1) {
      // Preserve existing add-ons if attending; if skipping, clear cost
      final existing = currentState[existingIndex];
      double newCost = cost;
      if (isAttending && existing.addons.isNotEmpty) {
        // Re-add the add-on costs on top of base price
        double addonTotal = 0;
        for (final addonStr in existing.addons) {
          if (addonStr.contains('|')) {
            final parts = addonStr.split('|');
            addonTotal += double.tryParse(parts[1]) ?? 0.0;
          }
        }
        newCost = cost + addonTotal;
      }
      session = existing.copyWith(
        status: isAttending ? 'Attended' : 'Skipped',
        sessionCost: isAttending ? newCost : 0,
      );
      try {
        await _repository.updateSession(session);
      } catch (e) {
        rethrow;
      }
    } else {
      session = MessSession(
        sessionDate: _currentDate,
        sessionType: type,
        status: isAttending ? 'Attended' : 'Skipped',
        sessionCost: isAttending ? cost : 0,
      );
      try {
        await _repository.addSession(session);
      } catch (e) {
        rethrow;
      }
    }
    await loadSessionsForDate(_currentDate);
  }

  /// [basePrice] is the configured base price for the session type (Breakfast/Lunch/Dinner).
  /// This ensures that when an add-on is tapped before explicitly marking attendance,
  /// the base cost is included in the total.
  Future<void> addAddonToSession(String type, String addonName, double addonPrice, {double basePrice = 0}) async {
    final currentState = state.value;
    if (currentState == null) return;

    final existingIndex = currentState.indexWhere((s) => s.sessionType == type);
    if (existingIndex != -1) {
      final session = currentState[existingIndex];
      final newAddons = List<String>.from(session.addons)..add(addonName);
      // If session was Skipped, switching to Attended means we need to add base cost + addon
      double newCost;
      if (session.status == 'Skipped' || session.sessionCost == 0) {
        newCost = basePrice + addonPrice;
      } else {
        newCost = session.sessionCost + addonPrice;
      }

      final updatedSession = session.copyWith(
        addons: newAddons,
        sessionCost: newCost,
        status: 'Attended',
      );

      try {
        await _repository.updateSession(updatedSession);
      } catch (e) {
        rethrow;
      }
    } else {
      // No session record yet: create one with base + addon price
      final session = MessSession(
        sessionDate: _currentDate,
        sessionType: type,
        status: 'Attended',
        sessionCost: basePrice + addonPrice,
        addons: [addonName],
      );
      try {
        await _repository.addSession(session);
      } catch (e) {
        rethrow;
      }
    }
    await loadSessionsForDate(_currentDate);
  }

  Future<void> removeAddonFromSession(String type, String addonName, double addonPrice) async {
    final currentState = state.value;
    if (currentState == null) return;

    final existingIndex = currentState.indexWhere((s) => s.sessionType == type);
    if (existingIndex != -1) {
      final session = currentState[existingIndex];

      final newAddons = List<String>.from(session.addons);
      final indexToRemove = newAddons.indexOf(addonName);

      if (indexToRemove != -1) {
        newAddons.removeAt(indexToRemove);

        final newCost = session.sessionCost - addonPrice;

        final updatedSession = session.copyWith(
          addons: newAddons,
          sessionCost: newCost >= 0 ? newCost : 0,
        );

        try {
          await _repository.updateSession(updatedSession);
        } catch (e) {
          rethrow;
        }
        await loadSessionsForDate(_currentDate);
      }
    }
  }
}

// ─── Persisted Session Prices ─────────────────────────────────────────────────
class SessionPricesNotifier extends StateNotifier<Map<String, double>> {
  SessionPricesNotifier() : super({'Breakfast': 0, 'Lunch': 0, 'Dinner': 0}) {
    _load();
  }

  static const _key = 'session_prices_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final b = prefs.getDouble('${_key}_Breakfast');
    final l = prefs.getDouble('${_key}_Lunch');
    final d = prefs.getDouble('${_key}_Dinner');
    if (b != null || l != null || d != null) {
      state = {
        'Breakfast': b ?? 0,
        'Lunch': l ?? 0,
        'Dinner': d ?? 0,
      };
    }
  }

  Future<void> setPrices(Map<String, double> prices) async {
    state = {...state, ...prices};
    final prefs = await SharedPreferences.getInstance();
    for (final entry in prices.entries) {
      await prefs.setDouble('${_key}_${entry.key}', entry.value);
    }
  }
}

final sessionPricesProvider =
    StateNotifierProvider<SessionPricesNotifier, Map<String, double>>(
  (ref) => SessionPricesNotifier(),
);

// ─── Persisted Add-ons ────────────────────────────────────────────────────────
class AddonItem {
  final String name;
  final double price;

  AddonItem({required this.name, required this.price});

  AddonItem copyWith({String? name, double? price}) {
    return AddonItem(name: name ?? this.name, price: price ?? this.price);
  }

  Map<String, dynamic> toJson() => {'name': name, 'price': price};

  factory AddonItem.fromJson(Map<String, dynamic> json) =>
      AddonItem(name: json['name'] as String, price: (json['price'] as num).toDouble());
}

class AddonsNotifier extends StateNotifier<List<AddonItem>> {
  AddonsNotifier() : super([]) {
    _load();
  }

  static const _key = 'addons_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw != null && raw.isNotEmpty) {
      state = raw.map((s) => AddonItem.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    }
  }

  Future<void> setAddons(List<AddonItem> addons) async {
    state = addons;
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _key, state.map((a) => jsonEncode(a.toJson())).toList());
  }
}

final addonsProvider =
    StateNotifierProvider<AddonsNotifier, List<AddonItem>>(
  (ref) => AddonsNotifier(),
);

// Provider for the MessSessionsNotifier
final messSessionsProvider =
    StateNotifierProvider<MessSessionsNotifier, AsyncValue<List<MessSession>>>((ref) {
  final repository = ref.watch(messRepositoryProvider);
  return MessSessionsNotifier(repository);
});

final trackingStartDateProvider = StateProvider<DateTime?>((ref) => null);

final allMessSessionsProvider = FutureProvider<List<MessSession>>((ref) async {
  final repo = ref.watch(messRepositoryProvider);
  ref.watch(messSessionsProvider); // Reload whenever sessions are updated
  final now = DateTime.now();
  final start = DateTime(now.year - 1, now.month);
  final end = DateTime(now.year + 1, now.month);
  return await repo.getSessionsBetweenDates(start, end);
});

final monthlyOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(messRepositoryProvider);
  ref.watch(messSessionsProvider); // Watch to rebuild when sessions are modified

  final prefs = await SharedPreferences.getInstance();
  final savedDateStr = prefs.getString('mess_tracking_start_date');
  DateTime? customStart = savedDateStr != null ? DateTime.tryParse(savedDateStr) : null;

  final stateStart = ref.watch(trackingStartDateProvider);
  if (stateStart != null) {
    customStart = stateStart;
    await prefs.setString('mess_tracking_start_date', customStart.toIso8601String());
  }

  final now = DateTime.now();
  DateTime start = DateTime(now.year, now.month, 1);
  final DateTime end = DateTime(now.year, now.month + 1, 0);

  if (customStart != null) {
    if (customStart.year == now.year && customStart.month == now.month) {
      start = DateTime(customStart.year, customStart.month, customStart.day);
    }
  }

  final sessions = await repo.getSessionsBetweenDates(start, end);

  double totalExpense = 0;
  final Set<String> attendedDays = {};

  for (final s in sessions) {
    if (s.status == 'Attended') {
      totalExpense += s.sessionCost;
      attendedDays.add(s.sessionDate.toIso8601String().split('T')[0]);
    }
  }

  return {
    'totalExpense': totalExpense,
    'messCount': attendedDays.length,
    'avgCost': attendedDays.isEmpty ? 0.0 : totalExpense / attendedDays.length,
  };
});
