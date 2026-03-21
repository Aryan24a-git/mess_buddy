import '../../domain/models/alert.dart';
import '../../domain/repositories/alert_repository.dart';

class MockAlertRepository implements AlertRepository {
  final List<AppAlert> _alerts = [];
  int _nextId = 1;

  @override
  Future<List<AppAlert>> getRecentAlerts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final sorted = List<AppAlert>.from(_alerts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(20).toList();
  }

  @override
  Future<AppAlert> insertAlert(AppAlert alert) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newAlert = AppAlert(
      id: _nextId++,
      title: alert.title,
      message: alert.message,
      createdAt: alert.createdAt,
      type: alert.type,
    );
    _alerts.add(newAlert);
    return newAlert;
  }

  @override
  Future<bool> hasAlertBeenSentToday(String type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now();
    return _alerts.any((a) =>
      a.type == type &&
      a.createdAt.year == now.year &&
      a.createdAt.month == now.month &&
      a.createdAt.day == now.day
    );
  }
}
