import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'local_notification_service.dart';

class LocalNotificationServiceMobile implements LocalNotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  @override
  Future<void> init(Function(int) onNotificationClick) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final id = int.tryParse(details.payload!);
          if (id != null) {
            onNotificationClick(id);
          }
        }
      },
    );
  }

  @override
  Future<void> showNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'main_channel',
      'Main Channel',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(id, title, body, details, payload: id.toString());
  }
}

LocalNotificationService getLocalNotificationService() => LocalNotificationServiceMobile();
