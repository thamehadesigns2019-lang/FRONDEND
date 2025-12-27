import 'package:flutter/foundation.dart';
import 'package:thameeha/services/api_service.dart';
import 'package:thameeha/services/local_notification_service.dart';

class NotificationManager {
  final ApiService _apiService;
  final LocalNotificationService _localService = LocalNotificationService();
  int? _lastNotificationId;

  NotificationManager(this._apiService);

  Future<void> init() async {
    if (kIsWeb) return;

    await _localService.init((id) {
      _lastNotificationId = id;
      _trackAction(id, 'clicked');
    });
    
    // Initial poll
    await pollForNotifications();
  }

  Future<void> pollForNotifications() async {
    if (kIsWeb) return;
    
    try {
      final pending = await _apiService.fetchPendingNotifications();
      for (var note in pending) {
        await _showLocalNotification(note);
      }
    } catch (e) {
      debugPrint('Error polling notifications: $e');
    }
  }

  Future<void> _showLocalNotification(Map<String, dynamic> note) async {
    final id = note['id'] as int;
    final title = note['title'] ?? 'New Notification';
    final body = note['body'] ?? '';

    await _localService.showNotification(id, title, body);
    
    // Mark as 'seen' once it's shown as a local notification
    _trackAction(id, 'seen');
  }

  void _trackAction(int notificationId, String action) {
     _apiService.trackNotification(notificationId, action);
  }

  int? get lastNotificationId => _lastNotificationId;

  void reportActionAfterNotification(String action) {
    if (_lastNotificationId != null) {
      _apiService.trackNotification(_lastNotificationId!, action);
      if (action == 'purchased') _lastNotificationId = null;
    }
  }
}
