import 'local_notification_service_mobile.dart' if (dart.library.html) 'local_notification_service_web.dart';

abstract class LocalNotificationService {
  Future<void> init(Function(int) onNotificationClick);
  Future<void> showNotification(int id, String title, String body);
  
  factory LocalNotificationService() => getLocalNotificationService();
}
