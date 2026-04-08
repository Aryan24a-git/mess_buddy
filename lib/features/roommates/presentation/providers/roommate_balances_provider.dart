import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Holds per-roommate split & owe amounts, plus settlement history.
///
/// Data shape per roommate (keyed by roommateId as String):
///   { "split": 0.0, "owe": 0.0, "settled": 0.0 }
///
/// "split" = money they need to pay you back (you paid for them)
/// "owe"   = money you need to pay them (they paid for you)

class RoommateBalanceEntry {
  final double split;
  final double owe;
  final double settled;

  const RoommateBalanceEntry({this.split = 0, this.owe = 0, this.settled = 0});

  double get total => split + owe;
  double get netOwed => split - owe; // positive => they owe you

  Map<String, dynamic> toMap() => {'split': split, 'owe': owe, 'settled': settled};

  factory RoommateBalanceEntry.fromMap(Map<String, dynamic> m) => RoommateBalanceEntry(
        split: (m['split'] as num?)?.toDouble() ?? 0,
        owe: (m['owe'] as num?)?.toDouble() ?? 0,
        settled: (m['settled'] as num?)?.toDouble() ?? 0,
      );

  RoommateBalanceEntry copyWith({double? split, double? owe, double? settled}) =>
      RoommateBalanceEntry(
        split: split ?? this.split,
        owe: owe ?? this.owe,
        settled: settled ?? this.settled,
      );
}

/// Snapshot for undo/redo
class _Snapshot {
  final Map<String, RoommateBalanceEntry> balances;
  _Snapshot(Map<String, RoommateBalanceEntry> src)
      : balances = {for (var e in src.entries) e.key: e.value};
}

class RoommateBalancesNotifier extends StateNotifier<Map<String, RoommateBalanceEntry>> {
  final List<_Snapshot> _undoStack = [];
  final List<_Snapshot> _redoStack = [];
  static const int _maxHistory = 50;

  RoommateBalancesNotifier() : super({}) {
    _load();
  }

  // ─── persistence ──────────────────────────────────────────────────────
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('roommate_balances_v1');
    if (raw != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        state = decoded.map((k, v) => MapEntry(k, RoommateBalanceEntry.fromMap(Map<String, dynamic>.from(v))));
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((k, v) => MapEntry(k, v.toMap())));
    await prefs.setString('roommate_balances_v1', encoded);
  }

  // ─── undo / redo ──────────────────────────────────────────────────────
  void _pushUndo() {
    _undoStack.add(_Snapshot(state));
    if (_undoStack.length > _maxHistory) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_Snapshot(state));
    final prev = _undoStack.removeLast();
    state = prev.balances;
    _save();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_Snapshot(state));
    final next = _redoStack.removeLast();
    state = next.balances;
    _save();
  }

  // ─── mutations ────────────────────────────────────────────────────────
  RoommateBalanceEntry _get(String id) => state[id] ?? const RoommateBalanceEntry();

  void addSplit(String roommateId, double amount) {
    _pushUndo();
    final entry = _get(roommateId);
    state = {...state, roommateId: entry.copyWith(split: entry.split + amount)};
    _save();
  }

  void addOwe(String roommateId, double amount) {
    _pushUndo();
    final entry = _get(roommateId);
    state = {...state, roommateId: entry.copyWith(owe: entry.owe + amount)};
    _save();
  }

  void editSplit(String roommateId, double newAmount) {
    _pushUndo();
    final entry = _get(roommateId);
    state = {...state, roommateId: entry.copyWith(split: newAmount)};
    _save();
  }

  void editOwe(String roommateId, double newAmount) {
    _pushUndo();
    final entry = _get(roommateId);
    state = {...state, roommateId: entry.copyWith(owe: newAmount)};
    _save();
  }

  /// Settle split amount for a single roommate (partial or full)
  void settleSplit(String roommateId, [double? amount]) {
    final entry = _get(roommateId);
    final settleAmt = amount ?? entry.split;
    if (settleAmt <= 0) return;

    _pushUndo();
    state = {
      ...state,
      roommateId: entry.copyWith(
        settled: entry.settled + settleAmt,
        split: (entry.split - settleAmt).clamp(0, double.infinity),
      ),
    };
    _save();
  }

  /// Settle owe amount for a single roommate (partial or full)
  void settleOwe(String roommateId, [double? amount]) {
    final entry = _get(roommateId);
    final settleAmt = amount ?? entry.owe;
    if (settleAmt <= 0) return;

    _pushUndo();
    state = {
      ...state,
      roommateId: entry.copyWith(
        settled: entry.settled + settleAmt,
        owe: (entry.owe - settleAmt).clamp(0, double.infinity),
      ),
    };
    _save();
  }

  /// Settle split amount for multiple roommates (divides totalAmount among them)
  void settleMultipleSplit(Set<String> ids, double totalAmount) {
    if (totalAmount <= 0) return;
    _pushUndo();
    final newState = {...state};
    final perPerson = totalAmount / ids.length;

    for (final id in ids) {
      final entry = newState[id] ?? const RoommateBalanceEntry();
      newState[id] = entry.copyWith(
        settled: entry.settled + perPerson,
        split: (entry.split - perPerson).clamp(0, double.infinity),
      );
    }
    state = newState;
    _save();
  }

  /// Settle owe amount for multiple roommates (divides totalAmount among them)
  void settleMultipleOwe(Set<String> ids, double totalAmount) {
    if (totalAmount <= 0) return;
    _pushUndo();
    final newState = {...state};
    final perPerson = totalAmount / ids.length;

    for (final id in ids) {
      final entry = newState[id] ?? const RoommateBalanceEntry();
      newState[id] = entry.copyWith(
        settled: entry.settled + perPerson,
        owe: (entry.owe - perPerson).clamp(0, double.infinity),
      );
    }
    state = newState;
    _save();
  }

  /// Settle ALL (split + owe) for one roommate
  void settleAll(String roommateId) {
    _pushUndo();
    final entry = _get(roommateId);
    state = {
      ...state,
      roommateId: entry.copyWith(
        settled: entry.settled + entry.split + entry.owe,
        split: 0,
        owe: 0,
      ),
    };
    _save();
  }

  /// Settle ALL for multiple roommates at once
  void settleMultiple(Set<String> ids) {
    if (ids.isEmpty) return;
    _pushUndo();
    final newState = {...state};
    for (final id in ids) {
      final entry = newState[id] ?? const RoommateBalanceEntry();
      newState[id] = entry.copyWith(
        settled: entry.settled + entry.split + entry.owe,
        split: 0,
        owe: 0,
      );
    }
    state = newState;
    _save();
  }

  /// Remove a roommate's balance record
  void removeRoommate(String roommateId) {
    _pushUndo();
    final newState = {...state};
    newState.remove(roommateId);
    state = newState;
    _save();
  }
}

final roommateBalancesProvider =
    StateNotifierProvider<RoommateBalancesNotifier, Map<String, RoommateBalanceEntry>>((ref) {
  return RoommateBalancesNotifier();
});

/// Total others owe you (sum of all split amounts)
final totalOthersOweYouProvider = Provider<double>((ref) {
  final balances = ref.watch(roommateBalancesProvider);
  return balances.values.fold(0.0, (sum, e) => sum + e.split);
});

/// Total you owe others (sum of all owe amounts)
final totalYouOweProvider = Provider<double>((ref) {
  final balances = ref.watch(roommateBalancesProvider);
  return balances.values.fold(0.0, (sum, e) => sum + e.owe);
});
