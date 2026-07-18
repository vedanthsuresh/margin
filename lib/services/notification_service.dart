import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Service for managing local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    // Skip initialization on web (plugin not supported)
    if (kIsWeb) {
      debugPrint('⚠️ NotificationService skipped - running on web');
      _initialized = false;
      return;
    }

    try {
      // Initialize timezone database
      tz_data.initializeTimeZones();
      // tz.local is automatically set to system timezone after initialization

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(initSettings);

      // Request Android permissions (required for Android 13+)
      final androidImplemented = await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplemented != null) {
        final granted = await androidImplemented.requestNotificationsPermission();
        debugPrint('📱 Android notification permission granted: $granted');
      }

      _initialized = result ?? false;
      if (_initialized) {
        debugPrint('✅ NotificationService initialized');
      } else {
        debugPrint('⚠️ NotificationService initialization returned false');
      }
    } catch (e) {
      // Allow app to continue if notifications aren't available
      debugPrint('⚠️ NotificationService initialization failed: $e');
      debugPrint('   App will continue without notification support');
      _initialized = false;
    }
  }

  /// Schedule a notification for when quarantine ends
  Future<void> scheduleQuarantineEndNotification() async {
    debugPrint('🔔 scheduleQuarantineEndNotification called');
    debugPrint('   kIsWeb: $kIsWeb');
    debugPrint('   _initialized: $_initialized');

    if (kIsWeb || !_initialized) {
      debugPrint('⚠️ Cannot schedule notification - service not available on this platform');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'friction_lock',
        'Friction Lock',
        channelDescription: 'Notifications for friction lock timer',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule for 30 seconds from now (testing)
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 30));

      debugPrint('📅 Scheduling notification for: $scheduledTime');

      await _notifications.zonedSchedule(
        0, // notification id
        'Cooling-Off Period Complete',
        'Your 30-second reflection period has ended. You can now copy your response.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexact, // Changed from exactAllowWhileIdle
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('✅ Notification scheduled successfully for 30 seconds from now');

      // Verify pending notifications
      final pendingNotifications = await _notifications.pendingNotificationRequests();
      debugPrint('📋 Pending notifications count: ${pendingNotifications.length}');
      for (final notification in pendingNotifications) {
        debugPrint('   - ID: ${notification.id}, Title: ${notification.title}');
      }
    } catch (e) {
      debugPrint('❌ Failed to schedule notification: $e');
    }
  }

  /// Cancel the quarantine end notification
  Future<void> cancelQuarantineEndNotification() async {
    await _notifications.cancel(0);
    debugPrint('🗑️ Cancelled quarantine end notification');
  }

  /// Show immediate notification when quarantine ends
  Future<void> showQuarantineEndNotification() async {
    debugPrint('🔔 showQuarantineEndNotification called');

    if (kIsWeb || !_initialized) {
      debugPrint('⚠️ Cannot show notification - service not available');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'friction_lock',
        'Friction Lock',
        channelDescription: 'Notifications for friction lock timer',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0, // Same ID as scheduled notification
        'Cooling-Off Period Complete',
        'Your 30-second reflection period has ended. You can now copy your response.',
        notificationDetails,
      );

      debugPrint('✅ Quarantine end notification shown immediately');
    } catch (e) {
      debugPrint('❌ Failed to show immediate notification: $e');
    }
  }

  /// Show an immediate notification (for testing)
  Future<void> showTestNotification() async {
    if (kIsWeb || !_initialized) {
      debugPrint('⚠️ Cannot show notification - service not available on this platform');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'friction_lock',
      'Friction Lock',
      channelDescription: 'Notifications for friction lock timer',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      1,
      'Test Notification',
      'This is a test notification from Margin',
      notificationDetails,
    );
  }
}
