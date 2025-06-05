/*import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService{
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  Future<void> initNotification() async {
    if (_isInitialized) return;
    const initSettingAndroid = AndroidInitializationSettings('@ipmap/ic_launcher');
    const initSettingIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: initSettingAndroid,
      iOS: initSettingIOS,
    );
    await notificationsPlugin.initialize(
      initSettings,
      //onDidReceiveNotificationResponse: (details) {
        // Handle notification response
     // },
    );
  }
  NotificationDetails notificationDetails(){
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notifications',
        channelDescription: 'Daily notifications for Flutter Grad',
        importance: Importance.max,
        priority: Priority.high,
      ),
  iOS : DarwinNotificationDetails()
  );
}

Future<void> showNotification(int id, String title, String body) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(),
    );
  }
}*/