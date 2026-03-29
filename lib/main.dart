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

  // Android 13+
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Cairo'));

  await initNotifications();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> testNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(const Duration(seconds: 5));

    await notificationsPlugin.zonedSchedule(
      1,
      'اختبار 🔔',
      'الإشعار شغال تمام',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),

      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // 🔥 مهم جدًا في الإصدار الجديد
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification() async {
    await notificationsPlugin.cancel(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تجربة الإشعارات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testNotification,
              child: const Text('إشعار بعد 5 ثواني 🔔'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: cancelNotification,
              child: const Text('إلغاء ❌'),
            ),
          ],
        ),
      ),
    );
  }
}
