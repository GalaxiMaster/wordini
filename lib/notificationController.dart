import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vocab_app/main.dart';
import 'package:timezone/timezone.dart' as tz;

Future<void> initializeNotifications() async {
  // Settings for Android
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Settings for iOS
  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Initialize settings for both platforms
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      debugPrint('Notification clicked: ${response.payload}');
    },
  );
}
Future<void> showInstantNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    channelDescription: 'your_channel_description',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0, // Notification ID
    'Instant Notification', // Notification title
    'This is an instant notification!', // Notification body
    platformChannelSpecifics,
    payload: 'instant_notification', // Data payload
  );
}
Future<void> scheduleNotification(Duration duration) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'your_scheduled_channel_id',
    'your_scheduled_channel_name',
    channelDescription: 'your_scheduled_channel_description',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  // Schedule notification 20 minutes from now
  await flutterLocalNotificationsPlugin.zonedSchedule(
    1, // Notification ID (different from instant notification)
    'Scheduled Notification', // Notification title
    'This notification was scheduled 20 minutes ago!', // Notification body
    tz.TZDateTime.now(tz.local).add(duration),
    platformChannelSpecifics,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: 'scheduled_notification', // Data payload
  );
}

Future<void> requestNotificationPermission() async {
  final androidImplementation = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidImplementation != null) {
    final bool? granted = await androidImplementation.requestExactAlarmsPermission();
    debugPrint('Notification permission granted: $granted');
  }
}