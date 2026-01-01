import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Helper method to copy asset image to temporary directory (required for iOS attachments)
  Future<String?> _getImageFilePath(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final fileName = assetPath.split('/').last;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      return file.path;
    } catch (e) {
      print('❌ Error copying asset image for notification attachment: $e');
      return null;
    }
  }

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    print('✅ Timezone set to: Asia/Kolkata (IST)');

    const androidSettings = AndroidInitializationSettings('@drawable/app_icon_light_theme');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        print('🔔 Notification tapped: ${response.payload}');
      },
    );

    print('✅ Notifications initialized: $initialized');

    // Request permissions
    if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        print('✅ iOS notification permissions granted: $granted');
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        print('✅ Android notification permissions: $granted');
      }
    }

    await listPendingNotifications();
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'scheduled_channel',
        'Scheduled Notifications',
        channelDescription: 'Scheduled notification channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/app_icon_light_theme',
      );

      // Prepare iOS attachment only if on iOS
      List<DarwinNotificationAttachment>? iosAttachments;
      if (Platform.isIOS) {
        final attachmentPath = await _getImageFilePath('assets/app_icon/app_icon_light_mode.png');
        if (attachmentPath != null) {
          iosAttachments = [
            DarwinNotificationAttachment(
              attachmentPath,
              hideThumbnail: false, // Set true if you don't want small preview
            ),
          ];
        } else {
          print('⚠️ Could not load attachment image – sending without image');
          iosAttachments = null;
        }
      }

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        attachments: iosAttachments,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);
      final now = tz.TZDateTime.now(tz.local);

      print('📅 Current time: $now');
      print('⏰ Scheduled for: $scheduledTime');
      print('⏱️ Time difference: ${scheduledTime.difference(now).inSeconds} seconds');

      if (scheduledTime.isBefore(now)) {
        print('⚠️ WARNING: Scheduled time is in the past!');
        return;
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print('✅ Notification scheduled successfully with ID: $id');
      await listPendingNotifications();
    } catch (e) {
      print('❌ Error scheduling notification: $e');
    }
  }

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'immediate_channel',
        'Immediate Notifications',
        channelDescription: 'Immediate notification channel',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@drawable/app_icon_light_theme',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, notificationDetails);
      print('✅ Immediate notification shown with ID: $id');
    } catch (e) {
      print('❌ Error showing immediate notification: $e');
    }
  }

  Future<void> listPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    print('📋 Pending notifications: ${pending.length}');
    for (var notification in pending) {
      print('   - ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('🗑️ Cancelled notification ID: $id');
    await listPendingNotifications();
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('🗑️ Cancelled all notifications');
    await listPendingNotifications();
  }
}