import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wordini/Providers/otherproviders.dart';
import 'package:wordini/main.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

Future<void> initializeNotifications({bool? askPermission}) async {
  bool allowNotifications = await Permission.notification.isGranted;
  if (await Permission.notification.isDenied) {
    final prefs = await SharedPreferences.getInstance();
    if (askPermission == null){
      final bool? askedNotifsBefore = prefs.getBool('askedNotifsBefore');
      if (!(askedNotifsBefore ?? false)){
        askPermission = true;
        prefs.setBool('askedNotifsBefore', true);
      }
    }
  }
  if ((askPermission ?? false)){
    allowNotifications = (await Permission.notification.request()).isGranted;
  }
  if (!allowNotifications) return;

  // Settings for Android
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_stat_wordiniforeground');

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
      if ((response.payload?.split('-') ?? []).length == 2) {
        if (response.payload!.split('-')[0] == 'wordReminder') {
          String word = response.payload!.split('-')[1];
          debugPrint('Word: $word');
          // TODO impliment reroute to word test page, needs rewrite of how the test page works
        }
      } else if (response.payload == 'wordReminder') {
        navigatorKey.currentState?.pushNamed(
          '/testing', // Your route name
          // arguments: word,
        );
      }
    },
  );
}

void turnNotificaitonsOff() async{
  final currentNotifs = await Hive.openBox<int>('active-notifications');
  for (String notif in currentNotifs.keys){
    removeNotif(notif);
  }
}

// In notification_controller.dart

void scheduleQuizNotification(WidgetRef ref, {String? word}) async {
  bool notifsOn = ref.read(notificationSettingsProvider.notifier).getValue('Quiz Reminders');
  if (!notifsOn) return;

  final currentNotifs = await Hive.openBox<int>('active-notifications');
  if (currentNotifs.containsKey('wordReminder')) {
    removeNotif('wordReminder');
    debugPrint('Notification already scheduled for word reminder...rescheduling notif');
  }

  // Call the updated function
  scheduleNotification(
    title: word == null ? 'Time for your quiz!' : 'Do you remember what "$word" means?',
    description: 'Your words are waiting for you.',
    duration: const Duration(days: 2),
    notificationType: NotificationType.wordReminder,
    payload: 'wordReminder',
  );
}

Future<void> showInstantNotification({
  required String title,
  required String description,
  required AndroidNotificationDetails androidPlatformChannelSpecifics,
  required String payload,
}) async {

  NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

  int id = await NotificationIdManager.getNextId();

  await flutterLocalNotificationsPlugin.show( // !here
    id, // Notification ID
    title, // Notification title
    description, // Notification body
    platformChannelSpecifics,
    payload: payload, // Data payload
  );
}

// In notification_controller.dart

Future<void> scheduleNotification({
  required String title,
  required String description,
  required Duration duration,
  required NotificationType notificationType, // <-- Use your NotificationType class
  required String payload,
}) async {
  // The Android-specific permission request is not needed here for iOS.
  // The main permission is handled in initializeNotifications.

  // Create platform-specific details from the NotificationType
  NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: notificationType.android,
    iOS: notificationType.iOS,
  );

  int id = await NotificationIdManager.getNextId();

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id,
    title,
    description,
    tz.TZDateTime.now(tz.local).add(duration),
    platformChannelSpecifics, // <-- This now contains iOS details!
    androidScheduleMode:  AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  noteNotification(id, payload);
  debugPrint('Scheduled notification with ID: $id for $payload at $duration');
}

Future<void> noteNotification(int id, String payload) async {
  // Open the box if not already open
  Hive.openBox<int>('active-notifications');
  var box = await Hive.openBox<int>('active-notifications');
  await box.put(payload, id);
}

void removeNotif(String key) async {
  // Ensure the box is open before accessing it
  if (!Hive.isBoxOpen('active-notifications')) {
    await Hive.openBox<int>('active-notifications');
  }
  var box = Hive.box<int>('active-notifications');
  int? id = box.get(key);
  if (id != null) {
    flutterLocalNotificationsPlugin.cancel(id);
    box.delete(key);
  }
  debugPrint('Notification with ID: $id removed for word: $key');
}


// In notification_controller.dart

class NotificationType {
  final String id;
  final AndroidNotificationDetails android;
  final DarwinNotificationDetails iOS; // <-- Add this for iOS

  const NotificationType._(this.id, this.android, this.iOS);

  static const NotificationType wordReminder = NotificationType._(
    'wordReminder',
    // Android Details
    AndroidNotificationDetails(
      'Definition_Reminders_id',
      'Definition Reminders',
      channelDescription: 'mydescription',
      importance: Importance.max,
      priority: Priority.high,
    ),
    // iOS Details
    DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}

class NotificationIdManager {
  static const String _key = 'notification_id_counter';

  /// Get the next available notification ID
  static Future<int> getNextId() async {
    final prefs = await SharedPreferences.getInstance();
    int currentId = prefs.getInt(_key) ?? 0;
    int nextId = currentId + 1;
    await prefs.setInt(_key, nextId);
    return nextId;
  }

  /// Optionally reset the counter
  static Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, 0);
  }
}
