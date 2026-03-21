import '../models/alert.dart';

abstract class AlertRepository {
  Future<List<AppAlert>> getRecentAlerts();
  Future<AppAlert> insertAlert(AppAlert alert);
  Future<bool> hasAlertBeenSentToday(String type);
}
