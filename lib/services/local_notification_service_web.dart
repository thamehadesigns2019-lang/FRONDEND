import 'local_notification_service.dart';

class LocalNotificationServiceWeb implements LocalNotificationService {
  @override
  Future<void> init(Function(int) onNotificationClick) async {
    print("Local notifications init on web (no-op)");
  }

  @override
  Future<void> showNotification(int id, String title, String body) async {
     print("Show notification web: $title - $body");
  }
}

LocalNotificationService getLocalNotificationService() => LocalNotificationServiceWeb();
