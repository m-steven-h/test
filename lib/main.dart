import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timezone init
  tz.initializeTimeZones();

  // Android init settings
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);

  await notificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificationPage(),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  // 🔥 طلب إذن الإشعارات (Android 13+)
  Future<void> requestPermission() async {
    final androidPlugin =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
  }

  // 📌 Notification details
  NotificationDetails _details() {
    const androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Test Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    return const NotificationDetails(android: androidDetails);
  }

  // ⚡ إشعار فوري
  Future<void> showInstant() async {
    await notificationsPlugin.show(
      0,
      '🔥 إشعار فوري',
      'ده إشعار ظهر فوراً',
      _details(),
    );
  }

  // ⏳ إشعار بعد 5 ثواني
  Future<void> showDelayed() async {
    await Future.delayed(const Duration(seconds: 5));

    await notificationsPlugin.show(
      1,
      '⏳ إشعار متأخر',
      'ظهر بعد 5 ثواني',
      _details(),
    );
  }

  // ⏰ إشعار مجدول بعد 10 ثواني
  Future<void> scheduleNotification() async {
    await notificationsPlugin.zonedSchedule(
      2,
      '⏰ إشعار مجدول',
      'ده إشعار بعد 10 ثواني',
      tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
      _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Test App'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: showInstant,
              child: const Text('🔥 إشعار فوري'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: showDelayed,
              child: const Text('⏳ إشعار بعد 5 ثواني'),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: scheduleNotification,
              child: const Text('⏰ إشعار مجدول (10 ثواني)'),
            ),
          ],
        ),
      ),
    );
  }
}
