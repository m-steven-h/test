import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    _init();
  }

  void _init() {
    tz.initializeTimeZones();
  }

  // إشعار فوري
  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'immediate_channel',
      'الإشعارات الفورية',
      channelDescription: 'قناة للإشعارات الفورية',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // إشعار مجدول
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    bool isDaily = false,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'scheduled_channel',
      'الإشعارات المجدولة',
      channelDescription: 'قناة للإشعارات المجدولة',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    if (isDaily) {
      // إشعار يومي متكرر
      final tz.TZDateTime tzScheduledTime =
          tz.TZDateTime.from(scheduledTime, tz.local);

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      // إشعار لمرة واحدة
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    }
  }

  // إشعار متكرر كل فترة زمنية
  Future<void> showRepeatedNotification({
    required int id,
    required String title,
    required String body,
    required int intervalMinutes,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'repeated_channel',
      'الإشعارات المتكررة',
      channelDescription: 'قناة للإشعارات المتكررة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      id,
      title,
      body,
      RepeatInterval.everyMinute,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // إلغاء إشعار محدد
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  // إلغاء جميع الإشعارات
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // الحصول على قائمة الإشعارات المجدولة
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }
}
