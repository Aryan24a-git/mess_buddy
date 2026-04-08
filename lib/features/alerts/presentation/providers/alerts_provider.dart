import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../data/repositories/sqlite_alert_repository.dart';
import '../../domain/services/notification_service.dart';

// Provide the repository
final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return SqliteAlertRepository();
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AppAlert>>> {
  final AlertRepository repository;
  final NotificationService _notificationService = NotificationService();

  AlertsNotifier(this.repository) : super(const AsyncValue.loading()) {
    _initNotifications();
    loadAlerts();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
  }

  Future<void> loadAlerts() async {
    try {
      state = const AsyncValue.loading();
      final alerts = await repository.getRecentAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await repository.markAllAsRead();
      if (state.hasValue) {
          state = AsyncValue.data(state.value!.map((a) => a.copyWith(isRead: true)).toList());
      }
    } catch (e) {
      if (kDebugMode) print('Error marking as read: $e');
    }
  }

  /// Triggers a low balance alert if the condition is met and it hasn't been triggered today.
  Future<void> triggerLowBalanceAlert(double balance) async {
    // Only trigger if balance is under say ₹2,000 threshold
    if (balance > 2000) return;

    final hasFiredToday = await repository.hasAlertBeenSentToday('low_balance');
    if (hasFiredToday) return;

    final alert = AppAlert(
      title: 'Low Balance Warning!',
      message: 'You have only ₹${balance.toStringAsFixed(0)} left in your budget. Spend carefully.',
      createdAt: DateTime.now(),
      type: 'low_balance',
    );

    await _insertAndNotify(alert, 1);
  }

  /// Triggers an overspending alert if daily burn rate is too high.
  Future<void> triggerOverspendingAlert(double burnRate) async {
    // Arbitrary threshold: daily burn rate > ₹800
    if (burnRate <= 800) return;

    final hasFiredToday = await repository.hasAlertBeenSentToday('overspending');
    if (hasFiredToday) return;

    final alert = AppAlert(
      title: 'High Burn Rate',
      message: 'Your current burn rate is ₹${burnRate.toStringAsFixed(0)}/day. Consider cutting back.',
      createdAt: DateTime.now(),
      type: 'overspending',
    );

    await _insertAndNotify(alert, 2);
  }

  /// Triggers a daily budget limit alert (50% info, 80% warning or exceeded).
  Future<void> triggerDailyBudgetAlert(double spent, double limit) async {
    if (limit <= 0) return;
    double ratio = spent / limit;
    String type;
    String title;
    String message;
    
    if (ratio >= 0.8) {
      type = 'daily_limit_warning';
      title = '80% Daily Budget Used';
      message = 'You have used 80% of your budget for today.';
    } else {
      return;
    }

    // Check if we already sent this specific level alert today
    final hasFiredToday = await repository.hasAlertBeenSentToday(type);
    if (hasFiredToday) return;

    final alert = AppAlert(
      title: title,
      message: message,
      createdAt: DateTime.now(),
      type: type,
    );

    await _insertAndNotify(alert, type == 'daily_limit_exceeded' ? 101 : 102);
  }

  Future<void> _insertAndNotify(AppAlert alert, int notificationId) async {
    try {
      // 1. Insert into DB so we know it fired today
      final saved = await repository.insertAlert(alert);
      
      // 2. Dispatch Local Notification wrapper
      await _notificationService.showNotification(
        id: notificationId,
        title: saved.title,
        body: saved.message,
      );

      // 3. Update the UI state
      if (state.value != null) {
        state = AsyncValue.data([saved, ...state.value!]);
      } else {
        await loadAlerts();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error triggering alert: $e');
      }
    }
  }
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<AppAlert>>>((ref) {
  final repo = ref.watch(alertRepositoryProvider);
  return AlertsNotifier(repo);
});
