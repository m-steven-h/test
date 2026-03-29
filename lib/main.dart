import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// 🔔 تهيئة الإشعارات
Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings =
      InitializationSettings(android: androidSettings);

  await notificationsPlugin.initialize(settings);

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

  /// 🧪 اختبار إشعار بعد 5 ثواني
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
    );
  }

  /// ❌ إلغاء الإشعار
  Future<void> cancelNotification() async {
    await notificationsPlugin.cancel(1);
  }

  /// 🔥 إشعار كل جمعة 3:30
  Future<void> fridayNotification() async {
    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      15,
      30,
    );

    while (scheduled.weekday != DateTime.friday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    await notificationsPlugin.zonedSchedule(
      2,
      'تنبيه الجمعة 🙏',
      'متنساش الصلاة وذكر الله',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'friday_channel',
          'Friday Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إشعارات التطبيق')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: testNotification,
              child: const Text('🔔 اختبار بعد 5 ثواني'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: fridayNotification,
              child: const Text('📅 إشعار كل جمعة 3:30'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: cancelNotification,
              child: const Text('❌ إلغاء الإشعار'),
            ),
          ],
        ),
      ),
    );
  }
}
