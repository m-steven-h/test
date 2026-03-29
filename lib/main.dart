import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings);

  // 🔔 طلب إذن الإشعارات (Android 13+)
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TestPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  Future<void> scheduleTestNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 10));

    await notificationsPlugin.zonedSchedule(
      999,
      'اختبار 🔔',
      'لو وصلتك الرسالة دي يبقى الإشعارات شغالة تمام',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification() async {
    await notificationsPlugin.cancel(999);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تجربة الإشعارات'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: scheduleTestNotification,
              child: const Text('جرب إشعار بعد دقيقة 🔔'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cancelNotification,
              child: const Text('إلغاء الإشعار ❌'),
            ),
          ],
        ),
      ),
    );
  }
}
