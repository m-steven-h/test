import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// ✅ دالة الخلفية للإشعارات (يجب أن تكون خارج الـ main)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == "scheduleWeeklyPrayerNotification") {
      await showWeeklyNotification();
    }
    return Future.value(true);
  });
}

// ✅ دالة عرض الإشعار
Future<void> showWeeklyNotification() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'prayer_channel',
    'تذكير الصلاة',
    channelDescription: 'تذكير أسبوعي للصلاة',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    '🕊️ تذكير بالصلاة',
    'حان وقت الصلاة - يوم الجمعة الساعة 3:30 عصراً',
    platformDetails,
  );
}

// ✅ دالة جدولة الإشعار الأسبوعي
Future<void> scheduleWeeklyNotification() async {
  tz.initializeTimeZones();
  final location = tz.getLocation('Africa/Cairo');

  final now = tz.TZDateTime.now(location);
  final tz.TZDateTime scheduledDate = tz.TZDateTime(
    location,
    now.year,
    now.month,
    now.day,
    15,
    30,
  ).isBefore(now)
      ? tz.TZDateTime.now(location).add(Duration(days: 7))
      : tz.TZDateTime(
          location,
          now.year,
          now.month,
          now.day,
          15,
          30,
        );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.zonedSchedule(
    1,
    '🕊️ تذكير بالصلاة',
    'حان وقت الصلاة - يوم الجمعة الساعة 3:30 عصراً',
    scheduledDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_channel',
        'تذكير الصلاة',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة الإشعارات المحلية
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
      InitializationSettings(android: androidSettings);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ طلب إذن الإشعارات (لأندرويد 13+)
  if (await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.areNotificationsEnabled() ??
      false) {
  } else {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ✅ تشغيل WorkManager فقط على Android (وليس على Web)
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerOneOffTask(
      "weeklyPrayerTask",
      "scheduleWeeklyPrayerNotification",
      initialDelay: Duration(seconds: 5),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  double _fontSize = 30.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final isDark = prefs.getBool('isDark') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _fontSize = prefs.getDouble('fontSize') ?? 30.0;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', _themeMode == ThemeMode.dark);
    await prefs.setDouble('fontSize', _fontSize);
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      _saveSettings();
    });
  }

  void updateFontSize(double newSize) {
    setState(() {
      _fontSize = newSize;
      _saveSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      darkTheme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        brightness: Brightness.dark,
        useMaterial3: true,
        primaryColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      home: PrepPage(
        toggleTheme: toggleTheme,
        themeMode: _themeMode,
        fontSize: _fontSize,
        updateFontSize: updateFontSize,
      ),
    );
  }
}

class PrepPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final ThemeMode themeMode;
  final double fontSize;
  final Function(double) updateFontSize;

  const PrepPage({
    super.key,
    required this.toggleTheme,
    required this.themeMode,
    required this.fontSize,
    required this.updateFontSize,
  });

  void _testNotification() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'prayer_channel',
      'تذكير الصلاة',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      999,
      '✅ اختبار الإشعارات',
      'الإشعارات تعمل بشكل صحيح في تطبيق اعدادي!',
      platformDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.black, const Color(0xFF1A1A1A)]
                : [Colors.white, const Color(0xFFF5F5F5)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            Text(
                              "خدمة",
                              style: TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w300,
                                color: isDark ? Colors.white70 : Colors.black54,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "اعدادي",
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                                shadows: [
                                  Shadow(
                                    blurRadius: 20,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.blue.shade200,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 60),
                Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 50 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) =>
                                          PrayerTimeSelectionPage(
                                        isDark: isDark,
                                        fontSize: fontSize,
                                        updateFontSize: updateFontSize,
                                      ),
                                      transitionsBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(1.0, 0.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;
                                        var tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.play_arrow, size: 28),
                                    SizedBox(width: 12),
                                    Text(
                                      "ابدأ الصلاة",
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 70 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26,
                                    width: 1.5,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                      ) =>
                                          SettingsPage(
                                        isDark: isDark,
                                        fontSize: fontSize,
                                        toggleTheme: toggleTheme,
                                        updateFontSize: updateFontSize,
                                      ),
                                      transitionsBuilder: (
                                        context,
                                        animation,
                                        secondaryAnimation,
                                        child,
                                      ) {
                                        const begin = Offset(0.0, 1.0);
                                        const end = Offset.zero;
                                        const curve = Curves.easeInOutCubic;
                                        var tween = Tween(
                                          begin: begin,
                                          end: end,
                                        ).chain(CurveTween(curve: curve));
                                        return SlideTransition(
                                          position: animation.drive(tween),
                                          child: child,
                                        );
                                      },
                                      transitionDuration: const Duration(
                                        milliseconds: 500,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(
                                  Icons.settings_outlined,
                                  size: 26,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  "الإعدادات",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // 🟢 زر اختبار الإشعارات
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 90 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  side: BorderSide(
                                    color: Colors.green.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                onPressed: _testNotification,
                                icon: Icon(
                                  Icons.notifications_active,
                                  size: 26,
                                  color: Colors.green,
                                ),
                                label: const Text(
                                  "🔔 اختبار الإشعارات",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PrayerTimeSelectionPage extends StatelessWidget {
  final bool isDark;
  final double fontSize;
  final Function(double) updateFontSize;

  const PrayerTimeSelectionPage({
    super.key,
    required this.isDark,
    required this.fontSize,
    required this.updateFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.black : Colors.white;

    final List<Map<String, dynamic>> prayerTimes = [
      {
        'title': 'صلاة باكر',
        'subtitle': '',
        'icon': Icons.wb_sunny,
        'color': Colors.blue,
        'description': '',
      },
      {
        'title': 'صلاة الغروب',
        'subtitle': '',
        'icon': Icons.wb_twighlight,
        'color': Colors.blue,
        'description': 'صلاة الساعة الحادية عشر',
      },
      {
        'title': 'صلاة النوم',
        'subtitle': '',
        'icon': Icons.nightlight_round,
        'color': Colors.blue,
        'description': 'صلاة الساعة الثانية عشر',
      },
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    "اختر وقت الصلاة",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView.builder(
                  itemCount: prayerTimes.length,
                  itemBuilder: (context, index) {
                    final prayer = prayerTimes[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: Duration(milliseconds: 500 + (index * 100)),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(50 * (1 - value), 0),
                          child: Opacity(
                            opacity: value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(25),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) =>
                                            PrayerPage(
                                          isDark: isDark,
                                          fontSize: fontSize,
                                          updateFontSize: updateFontSize,
                                          prayerTime:
                                              prayer['title'].toString(),
                                        ),
                                        transitionsBuilder: (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                        ) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOutCubic;
                                          var tween = Tween(
                                            begin: begin,
                                            end: end,
                                          ).chain(CurveTween(curve: curve));
                                          return SlideTransition(
                                            position: animation.drive(
                                              tween,
                                            ),
                                            child: child,
                                          );
                                        },
                                        transitionDuration: const Duration(
                                          milliseconds: 500,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [
                                                Colors.grey[900]!,
                                                Colors.grey[850]!,
                                              ]
                                            : [Colors.white, Colors.grey[50]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? Colors.white10
                                              : Colors.black12,
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  (prayer['color'] as Color)
                                                      .withOpacity(0.2),
                                                  (prayer['color'] as Color)
                                                      .withOpacity(0.1),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              prayer['icon'] as IconData,
                                              color: Colors.blue,
                                              size: 40,
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  prayer['title'] as String,
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  prayer['description']
                                                      as String,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: textColor
                                                        .withOpacity(0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            color: Colors.blue.withOpacity(0.7),
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final double fontSize;
  final VoidCallback toggleTheme;
  final Function(double) updateFontSize;

  const SettingsPage({
    super.key,
    required this.isDark,
    required this.fontSize,
    required this.toggleTheme,
    required this.updateFontSize,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _currentFontSize;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.fontSize;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDark ? Colors.black : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    "الإعدادات",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [Colors.grey[900]!, Colors.grey[850]!]
                              : [Colors.white, Colors.grey[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.isDark ? Colors.white10 : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(25),
                          onTap: () {
                            widget.toggleTheme();
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    widget.isDark
                                        ? Icons.dark_mode
                                        : Icons.light_mode,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "المظهر",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.isDark
                                            ? "الوضع الليلي"
                                            : "الوضع النهاري",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: !widget.isDark,
                                  onChanged: (_) {
                                    widget.toggleTheme();
                                    Navigator.pop(context);
                                  },
                                  activeColor: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [Colors.grey[900]!, Colors.grey[850]!]
                              : [Colors.white, Colors.grey[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color:
                                widget.isDark ? Colors.white10 : Colors.black12,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.text_fields,
                                    color: Colors.blue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "حجم الخط",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "تحكم في حجم الخط داخل التطبيق",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: widget.isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${_currentFontSize.round()}px",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Slider(
                              value: _currentFontSize,
                              min: 20,
                              max: 50,
                              divisions: 30,
                              onChanged: (value) {
                                setState(() {
                                  _currentFontSize = value;
                                });
                                widget.updateFontSize(value);
                              },
                              activeColor: Colors.blue,
                              thumbColor: Colors.blue,
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "معاينة النص",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "هذا مثال لتغيير حجم الخط",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: _currentFontSize * 0.6,
                                      color: widget.isDark
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PrayerPage extends StatefulWidget {
  final bool isDark;
  final double fontSize;
  final Function(double) updateFontSize;
  final String prayerTime;

  const PrayerPage({
    super.key,
    required this.isDark,
    required this.fontSize,
    required this.updateFontSize,
    required this.prayerTime,
  });

  @override
  State<PrayerPage> createState() => _PrayerPageState();
}

class _PrayerPageState extends State<PrayerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int currentIndex = 0;
  final FocusNode _focusNode = FocusNode();
  bool _showList = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, String>> bakrPrayers = [
    {
      'title': 'صلاة الشكر',
      'body':
          'فَلْنشْكُرّ صَانِعَ الخَيراتِ الرَّحُومَ الله أبَا رَبِّنَا وإلهِنَا ومُخَلِصَنا يَسُوعِ المسِيحِ. لأنَّهُ سَتَرنَا، وأعَانَنَا، وحَفِظَنا، وقَبِلَنا إليهِ، وأشْفَقَ عَلينَا، وعَضَّدنَا، وأَتَى بنا إلى هَذِهِ السَّاعَة. هُو أيْضاً فَلْنَسْأَلَهُ أنْ يَحْفَظَنا فى هَذَا اليَومِ المقَدَّسِ وكُلِّ أيَّامِ حَيَاتنَا بكلِّ سَلامِ. الضَّابِطُ الكُلّ الرَّبُ إلَهنَا. أيُّهَا السَّيِدُ الرَّبُّ الإلَه ضَابطُ الكُلِّ أبُو ربِّنَا وإلهنَا ومُخَلصَّنَا يَسُوعِ المسِيح نَشْكرُكَ عَلَى كُلِّ حالٍ، ومِنْ أجْل كلِّ حَالٍ، وفى كُلِّ حالٍ، لأنَّكَ سَترْتَنا، وأعَنْتَنا، وحفِظْتنَا، وقَبلْتنَا إليْكَ، وأشْفَقْت عَلينا، وعَضَّدْتَنَا، وأتَيتَ بِنَا إلىَ هَذِه السَّاعةِ. من أجْلِ هَذَا نَسْألُ ونَطْلبُ مِنْ صَلاحِكَ يَامُحبَّ البَشَر، امْنَحنَا أنْ نُكْملَ هذا اليَوْمَ المقَدَّسَ وكلّ أيَّامِ حَياتِنَا بِكلِّ سَلامٍ مَعَ خَوفِكَ، كُلُّ حَسَدٍ، وكلُّ تَجربَةٍ. وكلُّ فِعْلِ الشَّيْطانِ، ومُؤامَرةِ النَّاسِ الأشْرارِ، وقِيام الأعْدَاءِ الخَفيِّينَ والظَّاهِرينَ، إنْزَعهَا عنَّا وعَنْ سَائِرِ شَعْبكَ وعَنْ مَوضِعِكَ المقَدَّسِ هَذا. أمَّاَ الصَّالِحاتُ والنَّافعاتُ فَارزُقْنا إيَّاهَا. لأنَّكَ أنْتَ الذِى أعْطَيتَنا السُّلْطانَ أنْ ندوسَ الحَيَّاتِ والعَقارِبَ وكُلَّ قوَّةِ العَدوِّ. ولا تُدْخِلنَا فى تَجربَةٍ، لَكنْ نَجِّنا مِنَ الشِّرِّيرِ. بالنِّعْمةِ والرَّأْفَاتِ ومَحبَّة البَشرِ اللَّواتِى لإبْنِك الوَحيدِ ربِّنا وإلهِنَا ومُخلِّصِنا يَسُوعِ المسيحِ. هَذَا الذِى مِنْ قِبَلِه الَمجْدُ والإكْرام والعزَّةُ والسُّجودُ تَلِيقُ بكَ مَعهُ مَعُ الرُّوحِ القُدُسِ الَمحْيى المسَاوِى لَكَ الآنَ وكلَّ أوَانٍ وإلىَ دَهرِ الدُّهُورِ. آمين.',
    },
    {
      'title': 'المزمور الخمسون',
      'body':
          'إرْحَمنِى يَا الله كَعَظيمِ رَحْمتِكَ، ومِثْل كَثْرةِ رَأفتِكَ تَمْحُو إثْمِى. تَغْسلُنِى كَثيراً مِنْ إثْمِى، ومِنْ خَطيَّتِى تُطهَّرنِى. لأنِّى عارفٌ بإثْمِى، وخَطيَّتِى أمَامِى فى كلِّ حينٍ. لَكَ وحْدَك أخْطأْت، والشَّرُّ قدامَكَ صَنعْتُ. لِكىْ تَتَبرَّرَ فى أقْوالِكَ. وتَغْلبَ إذَا حَاكمْت. لأنِّى هَا أنَذَا بالاثْمِ حُبلَ بِى، وبالَخَطايَا وَلَدتْنِى أمِّى. لأنَّكَ هَكَذا قَدْ أحْبَبتُ الحقَّ، إذْ أوْضَحتَ لِى غَوامِضَ حِكْمتِكَ ومَسْتورَاتِها. تَنضَحُ عَلىَّ بِزُوفَاكَ فأطَّهَّرُ، تَغْسلُنِى فَأبْيضُّ أكْثَر مِنَ الثَّلجِ، تَسْمعُنِى سُرُوراً وفَرحاً، فتَبْتهجُ عِظامِى المنْسَحقةُ. أصْرِفْ وجْهَكَ عَنْ خَطايَاىَ، وأمْحُ كلَّ اثَامِى. قَلبِاً نَقياً أخْلقْ فىَّ يَا الله، ورُوحاً مُسْتَقيماً جدِّدهُ فى أحْشَائِى. لا تَطْرحْنِى مِنْ قُدَّامَ وجْهكَ، ورُوحكَ القُدُّوسِ لا تَنْزعْهُ مِنِّى. امْنَحْنِى بَهْجةَ خَلاصِكَ، وبرُوحِ مُدبِّرٍ عَضِّدّنِى فأعْلمِ الأثَمَةَ طُرُقكَ، والمنَافِقونَ إليْكَ يَرجعونَ، نَجِّنِى مِنَ الدِّماء يا الله إلَه خَلاصِى، فيَبتَّهجُ لِسانِى ببرَّكَ. يَاربِّ إفْتَح شَفتَىَّ فَيُخبرُ فَمِى بَتَسْبيحِكَ. لأنَّكَ لَوْ أثَرتَ الذَّبيحةَ، لَكُنْتُ الآنَ أعْطِى. ولَكنَّكَ لا تُسرُّ بالَمحْرقَاتِ، فالذَبيحَةُ للهِ رُوحَّ مُنْسحقَّ. القَلْبُ المنْكسِرُ والمتَواضِعُ لايُرْزلهُ الله، أنْعمْ يَا ربّ بِمَسرتكَ عَلى صِهْيُون، ولْتَبنِ أسْوَارَ أورْشَلِيم. حِينَئذٍ تُسرُّ بذَبائِح البَرِّ قرباناً ومُحْرقَات ويُقَّربون عَلى مَذابِحكَ العُجُول. هَلِّلُويا.',
    },
    {
      'title': 'هلم نسجد',
      'body':
          'هَلمَّ نَسْجدُ هَلمَّ نَسْألَ المسِيحَ إلَهنَا. هَلمَّ نَسْجدُ، هَلمَّ نَطْلبُ مِنَ المسِيحِ مَلِكِنا. هَلمَّ نَسْجدُ، هَلمَّ نَتضرَّعُ إلى المسِيح مُخَلصِنَا. يارَبَّنا يَسُوعُ المسِيحُ كَلمَةُ الله إلهنَا، بشَفَاعةِ القدِّيسة مَرْيَمٍ وجَمِيعِ قِدِيسيكَ، إحْفَظنَا ولنَبدَأ بَدْءاً حَسناً. ارْحَمْنا كإرَادَتكَ إلَى الأبَد. اللَّيْلَ عَبَر، نَشْكركَ يَارَبّ ونَسْألُ أنْ تَحْفَظَنا فى هذا اليَومِ بِغَير خَطيَّةٍ وإنْقذْنا.',
    },
    {
      'title': 'البولس (افسس4:1-5)',
      'body':
          'أسْألُكُم أنَا الأسِيرُ فى الرَّبِّ أنْ تَسْلكُوا كَمَا يَحقُّ للدَّعْوةِ التِى دُعِيتُم إليْها، بكلّ تَواضُعِ القَلْب والوَدَاعةِ وطُولِ الأنَاةِ مُحْتمِلينَ بعْضَكُم بَعْضاً فى الَمَحبَّةِ. مُسْرعِينَ إلَى حِفْظِ وَحْدانَّية الروُّحِ برِبَاطِ الصُّلحِ الكَاملِ لِكىْ تَكونُوا جَسَداً واحِداً ورُوحاً واحِداً، كَما دُعِيتُم إلى رَجاءِ دَعْوتِكمْ الوَاحِد. رَبُّ وَاحِدُّ. إيِمَانٌ واحِدٌ. مَعْمودِيَّةٌ وَاحِدةٌ.',
    },
    {
      'title': 'من إيمان الكنيسة',
      'body':
          'واحِدٌ هُوَ الله أبُو كلِّ أحَدٍ. واحِدٌ هُوَ أيْضاً إبْنُه يَسُوعُ المسِيحُ الكَلِمةُ، الذِى تَجسَّدَ وماتَ وقَامَ مِنَ الأمْواتِ فى اليَومِ الثَّالثِ وأقَامَنَا مَعهُ. واحِدٌ هُوَ الرُّوحُ القُدُسُ المعزَّى الوَاحدُ بإقْنُومِه، مُنبَثقٌ مِنَ الآبِ، يُطهِّرُ كلِّ البَريَّة. يُعلِّمُنا أنْ نَسْجدَ للثَّالُوثِ القُدَّوسِ بِلاهُوتِ واحِدٍ وطَبيعَةٍ واحِدَةٍ، نُسبِّحهُ ونُبارِكهُ إلى الأبَدِ. آمين.',
    },
    {
      'title': 'بدء الصلاة',
      'body':
          'صَلاةٌ بَاكر مِنَ النَّهارِ المبارَكِ أقدِّمها للْمَسيحِ مَلِكى وإلَهى وأرْجوهُ أنْ يَغْفرَ لِى خَطاياىَ.',
    },
    {
      'title': 'مز1: طوبى للرجل',
      'body':
          'طُوبَى للرَّجُل الذِى لَمْ يَسْلكْ فى مَشُورةِ المنَافِقِينَ. وفى طَريقِ الَخُطَاةِ لَمْ يَقِفْ، وفى مَجْلسِ المسْتَهزِئينَ لَمْ يَجِلسْ. لكنْ فى نَامُوسِ الرَّبَّ إرادَتُه، وفى نَامُوسِهِ يَلْهجُ نَهاراً وليْلاً. فيَكونُ كالشجَرةِ المغْروسَةِ عَلى مَجارِى المياهِ، التِى تُعْطِى ثَمَرَها فى حِينِهِ. وَورَقُها لاينْتَثِرُ، وكلُّ ما يَصْنعُ ينْجَحُ فِيهِ. لَيسَ كَذلِكَ المنَافِقُونَ، لَيسَ كَذلَكَ. لكنَّهمْ كالَهَبَاءِ الذِى تَذْرِيهِ الرِّيحُ عَنْ وجُهِ الأرْضِ. فَلهَذَا لا يَقومُ المنَافِقُونَ فى الدَّينُونَةِ، ولاَ الخُطَاةُ فى مَجْمَعِ الصِّدِّيقينَ. لأنَّ الرَّبِّ يَعْرِفُ طَريق الأبْرارِ، وأمَّا طَرِيقُ المنَافِقينَ فَتُبادُ. هَلِّلُويا.',
    },
    {
      'title': 'مز2: لماذا ارتجت الامم',
      'body':
          'لِماذَا إرْتَجَّتِ الأمَمُ، وفَكَّرتِ الشُّعوبُ بالبَاطِل. قَامَ مُلوكُ الأرْضِ، وتآمَرَ الرُّؤساءُ مَعاً عَلى الرَّبِّ وعَلىِ مَسِيحِهِ قائِلينَ: لِنَقْطَعْ أغْلالَهُم، ولِنَطرحْ عنَّا نَيْرهَا. السَاكِنُ فى السَّمَواتِ يَضْحَكُ بِهِم، والرَّبُّ يَمْقُتُهُم. حِينَئذٍ يُكلِّمهُم بغَضَبهِ، وبِرَجزِهِ يُقْلقُهمْ. أنَا أقَمْتهُ مَلكاً عَلى صُهْيونٍ جَبَل قُدْسهِ، لأكُرِّزَ بأَمْر الرَّبِّ. الرَّبُّ قالَ لِى: أنْتَ إبْنِى، وأنَاَ اليَومَ وَلدْتُك. سَلْنِى فأُعْطِيكَ الأُمَمَ مِيرَاثَكَ، وسُلْطانَكَ إلَى أقْطارِ الأرْضِ. لترْعَاهُم بقضِيبٍ مِنْ حَديدٍ. ومِثْل آنِيةِ الفَخَّارِ تَسْحقُهمْ. فالآنَ أيُّهَا الملُوكُ إفْهَموا، تأدَّبُوا ياجَميعَ قَضَاةِ الأرْضِ أعْبدُوا الرَّبَّ بَخَشْيةِ. وهَللُوا لَهُ برعْدَةٍ. الْزَمُوا الأدَبَ لِئلاَّ يغْضَبَ الرَّبُّ فتَضِلُّوا عَنْ طَريقِ الحَقِّ. عِنْدمَا يتَّقدُ غَضَبُه بسُرْعةٍ. طُوبَى لجَمِيع المتَّكلِينَ عَليْهِ. هَلِّلُويا.',
    },
    {
      'title': 'مز3: يارب لماذة كثر',
      'body':
          'يَارَبُّ لماذَا كَثُرَ الذِينَ يُحزْنُونِى، كَثِيرونَ قامُوا علىَّ. كَثِيرونَ يقُولُونَ لِنفْسِى، لَيسَ لَهُ خَلاصٌ بإلَهِهِ. أنْتَ يارَبّ أنْتَ هُو نَاصِرِى، مَجْدِى ورَافِعُ رَأسِى. بصَوْتى إلَى الرَّبِّ صَرخْتُ. فإسْتَجابَ لِى مِنْ جَبَلِ قُدْسه. أنَا إضْطَجَعتُ ونِمْتُ، ثمَّ إسْتَيقظْتُ لأنَّ الرَّبَّ نَاصِرى. فَلاَ أخَافَ مِنْ رَبَوات الَجُمُوع المُحِيطِينَ بى القَائميِنَ عَلَىِّ. قُمْ يَارَبّ خلِّصْنِى يَا إلَهِى، لأنَّكَ ضَرَبْتَ كُلَّ مِنْ يُعادِينى بَاطِلاً. أسْنانُ الخُطاةِ سَحَقَتْها. للرَّبِّ الخَلاَص وعَلَى شَعبِه بَرَكتهُ. هَلِّلُويا.',
    },
    {
      'title': 'مز4: اذ دعوت استجابت لي',
      'body':
          'إذْ دَعَوْتُ إسْتَجَبْتَ لِى يَا إلهَ برِّى، فى الشّدَّةِ فَرَّجتَ عَنِّى. تَراءَفْ عَلىَّ يَارَبِّ وإسْمَعْ صَلاتِى. يا بَنِى البَشَرَ حتَّى مَتَى تَثْقلُ قلُوبُكُم؟ لماذَا تُحبُّونَ البَاطِلَ وتَبْتَغونَ الكَذبَ؟ أعْلمُوا أنَّ الرَّبَّ قَدْ جَعَل قُدُّوسَه عَجباً. الرَّبُّ يَسْتَجيبُ لِى إذا ما صَرخْتُ إلَيهِ. إغْضَبُوا ولا تُخْطِئوا، الذِى تَقولُونَه فى قُلوبِكُم أنْدمُوا عَليْهِ فى مَضَاجعكُم. إذْبَحُوا ذَبيحَة البِرِّ، وتَوكَّلُوا عَلى الرَّبِّ. كَثيرُونَ يقُولُونَ مَنْ يُرينَا الخَيْرات؟ قَدْ أضَاءَ عَلَينَا نُورَ وجْهكَ يَاربِّ. أعْطَيتَ سُرُوراً لِقلْبِى أوْفَرَ مِنَ الذِينَ كَثُرتْ حِنْطَتهُمْ وخَمْرُهُم وزَيتُهُم. فَبالسَّلامِ أضْطَجعُ أيْضاً وأنَام، لأنَّكَ أنْتَ وحْدَك ياربِّ أسْكَنتَنِى علَى الرَّجَاء هَلِّلُويا.',
    },
    {
      'title': 'مز5: انصت يارب لكلماتي',
      'body':
          'أنًصِتْ يَارَبُّ لِكَلِماتِى، وإسْمَعْ صُراخِى. إصْغَ إلى صَوْتِ طَلبَتى يامَلِكى وإلَهِى، لأنِّى إليْكَ أصلِّى. يارَبُّ بالغّداةِ تَسمَعُ صَوتِى، بالغَداةِ أقف أمَامكَ وتَرانِى. لأنَّكَ إلهٌ لا تَشَاء الأثْمَ، ولا يُساكِنُكَ مَنْ يَصنَعُ الشَّرَّ. ولا يَثْبتُ مُخالفُو النَّامُوس أمَامَ عَيْنَيكَ. يَاربُّ أبْغَضتَ جَمِيعَ فَاعِلِى الأثْمِ، وتُهِلكُ كلَّ النَّاطِقينَ بالكَذبِ. رَجلُ الدِّماءِ والغاشِّ يَرذلُهُ الرَّبُّ. أمَّا أنَا فبكثْرةِ رحْمَتكَ أدْخلُ بَيْتِكَ، وأسْجدُ قَدَّامَ هَيْكلِ قُدسِك بَمَخَافَتكَ. ياربُّ أهْدِنِى بِبرِّكَ، مِنْ أجْل أعْدائِى. سَهِّلْ أمَامِى طَريقَكَ. لأنَّهُ لَيسَ فى أفْواهِهِمْ صِدقٌ. بَاطِلٌ هُوَ قَلبُهُمِ. حَنْجرتَهُمْ قَبْرٌ مفْتُوحٌ. وبألسِنتِهم قد غَشُّوا. دِنْهُمْ يا الله. وليسْقُطُوا مِنْ جَميعِ مُؤامَراتِهِمْ وكِكَثْرةِ نِفاقِهِمْ اسْتَأصِلْهُم، لأنَّهُم قَدْ أغْضَبوكَ يَاربُّ. وليَفْرحْ جَميعُ المتَّكلِينَ عَليكَ، إلى الأبَدِ يُسرُّونَ وتَحلُّ فِيهِمْ. ويفْتَخرُ بكَ كلُّ الذِينَ يُحبُّونَ إسْمكَ. لأنَّكَ أنْتَ بَارَكتَ الصِّدِّيقَ يَاربُّ. كَما بتُرْسِ المسَرَّةِ كَلَلتَنَا. هَلِّلُويا.',
    },
    {
      'title': 'مز6: يارب لا تبكتني بغطبك',
      'body':
          'يَاربُّ لا تُبكِّتْنِى بغَضَبكَ، ولا تُؤدِّبْنِى بسَخَطكَ. إرْحَمنِى يَاربُّ فإنِّى ضَعِيفٌ، إشْفِنِى يارَبُّ فإنَّ عِظَامِى قَد إضْطَربَتْ ونَفْسِى قدِ إنْزَعجَت جِدّاً. وأنْتَ يَاربُّ فإلَى مَتَى؟ عُدْ ونَجِّى نَفْسى، وأحْيِنِى مِنْ أجْلِ رَحْمتكَ. لأنَّه لَيسَ فى الموْتِ مِنْ يَذْكُركَ ولا فى الَجَحِيم مَنْ يَعْترفُ لَك. تَعِبتُ فى تَنهُّدِى. أعُوِّمُ كلَّ لَيلةٍ سَرِيرِى، وبدُمُوعِى أبلُّ فِراشِى. تَعكَّرتْ مِنَ الغَضَبِ عَيْناىَ. هُرِمتُ مِنْ سَائِرِ أعْدائِى. أبْعُدوا عَنِّى يَاجَميعَ فَاعِلى الأثْمِ. لأنَّ الرَّبَّ قَد سَمعَ صَوتَ بُكائِى. الرَّبُّ سَمعَ تَضرُّعِىِ، الرَّبُّ لِصَلاتِى قَبِلَ، فَلْيَخزَ ولْيضْطَربَ جدِّا جَميعُ أعْدائى، ولْيرتدُّوا إلى ورَائِهِمْ بالخِزْى سَريعاً جِدِّا. هَلِّلُويا.',
    },
    {
      'title': 'مز8: ايها الرب ربنا',
      'body':
          'أيُّهَا الرَّبُّ رَبُّنَا ما أعْجَب إسْمَكَ عَلَى الأرْضِ كلِّهَا، لأنَّهُ قَدِ ارْتفَعَ عِظَمُ جَلالِكَ فَوْقَ السَّمواتِ. مِنْ أفْواهِ الأطْفالِ والرُّضْعانِ هَيَّأتَ سَبْحاً، مِنْ أجْلِ أعْدائِكَ لتُسِكتَ عَدوِّا ومُنْتَقماً. لأنَّى أرَى السَّمواتِ أعْمَالَ يَديْكَ، القَمَرَ والنُّجومَ أنْتَ أسَّسْتَها. مَنْ هُوَ الإنْسانُ حتَّى تَذْكَرهُ. وإبْنُ الإنْسانِ حَتَّى تَفْتَقِدهُ؟ أنْقَصتَهُ قَليلاً عَنِ الملائِكَةِ. بالَمجْدِ والكَرامَةِ تَوُّجْتهُ، وعَلَىِ أعْمَال يَدَيْكَ أقَمْتهُ. كلُّ شَئٍ أخْضَعْت تَحْت قَدَميْهِ. الغَنَمَ والبَقَرَ جَميِعاً وأيْضاً بَهَائِمَ الحَقْل، وطُيورَ السَّماءِ وأسْمَاكَ البَحْر السَّالِكَة فى البِحار. أيُّها الرَّبُّ ربُّنَا، مَا أعْجَبَ أسْمَكَ فى الأرْضِ كلِّها. هَلِّلُويا.',
    },
    {
      'title': 'مز11: خلصنى يارب',
      'body':
          'خَلِّصْنِى يَاربُّ فإنَّ البَارَّ قَدْ فَنَى، وقَدْ قَلَّتِ الأمَانَةُ مِنْ بَنِى البَشَر. تَكَّلم كُلٌ أحَدٍ مَعَ قَريبهِ بالبَاطِلِ. شِفاةٌ غَاشَّةٌ فى قُلوبِهِمْ، وبقُلُوبِهِمْ تكَلَّمُوا. يَسْتأصِلُ الرَّبُّ جَمَيعَ الشِّفاةِ الغَاشَّةِ، واللِّسَانِ النَّاطِقِ بالكِبْريَاءِ، الذِينَ قالُوا نُعظِّمُ ألْسِنَتَنَا. شِفَاهُنا مَعَنا. فَمَن هُوَ يَسُوُد عَلْينا؟ مِنْ أجْل شَقَاءِ المسَاكِين وتَنهُّدِ البَائِسينَ الآنَ أقُومُ، يقُولُ الرَّبُّ، أصْنَعُ الَخَلاصَ عَلانيةً. كَلامُ الرَّبِّ كَلامّ نَقىٌّ، كفِضَّةٍ مُصفَّاةٍ مُجرَّبةٍ فى الأرْض قَدْ صُفِّيتْ سَبْعةَ أضْعَافٍ. وأنْتَ يارَبُّ تُنَجِّينَا وتَحْفَظُنا مِنْ هَذا الجيل وإلى الدَّهْر. المنَافِقُونَ حَوْلَنا يَمْشُونَ مِثْلَ عَظَمَتِكَ. رَفَعْتَ بَنِى البَشَرِ. هَلِّلُويا.',
    },
    {
      'title': 'مز12: الي متى يارب تنساني؟',
      'body':
          'إلَى مَتَى يارَبُّ تَنْسانِى؟ إلَى الإنْقِضَاءِ؟ حَتَّى مَتّى تَصْرفُ وَجْهَك عنِّى؟ إلَى مَتَى أرْدُدْ هَذِهِ المشُورَاتِ فى نَفْسِى، وهَذِهِ الأوْجَاعُ فى قَلْبى النّهَارَ كُلَّه؟ إلَى مَتَى يَرْتفِعُ عَدوِّى عَلىَّ؟ أنْظُرْ وإسْتَجِبْ إلىَّ يَاربِّى وإلَهِى. أنَرْ عَيْنىَّ لِئلاَّ أنَامُ نَومَ الموْتِ، لِئلاَّ يَقولَ عَدوِّى إنِّى قَدْ قَويتُ عَليْهِ. الذينَ يُحْزنُونَنِى يَتهلَّلُونَ إنْ أنَا زَلَلْتُ. أمَّا أنَا فَعَلىِ رَحْمتكَ توَكَّلتُ، يبْتَهجُ قَلبِى بَخَلاصِكَ. أُسبِّحُ الرَّبَّ الَمحْسِن إلىَّ، وأُرتِّل لإسْمِ الرَّبِّ العَالِى. هَلِّلُويا.',
    },
    {
      'title': 'مز14: يارب من يسكن في مسكنك',
      'body':
          'يارَبَّ مَنْ يَسْكنُ فى مَسْكنِكَ، مَنْ يَحلُّ فى جَبَل قُدْسِكَ؟ السَّالِكُ بِلاعَيبٍ. والفَاعِلُ البِرَّ، والمتكَلِّمُ بالَحَقِّ فى قَلْبهِ، الذِى لا يَغشُّ بلِسَانهِ، ولا يَصْنعُ بقَريبِهِ سُوءاً، ولا يَقْبلُ عَاراً عَلى جِيرانِهِ. فاعِلُ الشَّرِّ مَرْذُولٌ أمَامَه، ويُمجِّدُ الذِين يتَّقُونَ الرَّبَّ. الذِى يَحْلفُ لِقَريبِهِ، ولايَغْدرُ بهِ. ولايُعْطِى فِضَّتَهُ بالرِّبَا، ولا يَقْبلُ الرَّشْوةَ عَلَى الأبْرِياء، الذِى يَصْنعُ هَذا لايَتَزعْزعُ إلَى الأبَدِ. هَلِّلُويا.',
    },
    {
      'title': 'مز15: احفظني يا رب',
      'body':
          'إحْفَظْنِى يا رَبُّ فإنِّى عَليْكَ تَوكَّلتُ. قُلتُ للرَّبِّ أنْتَ رَبِّىِ. ولا تَحْتاجُ إلى صَلاحِى. أظْهَرَ عَجائِبَهُ لِقدِّيسِيهِ الذِينَ فى أرْضِهِ، وصَنعَ فِيِهمْ كلَّ مِشيئاتِهِ. كَثُرتْ أمْراضُهُمْ الذِينَ أسْرَعوا وَراءَ الهٍ آخَرَ، لا أشْتَركُ فى قَرابِينِهِم مِنَ الدِّماءِ، ولا أذْكرُ أسْمَاءَهُم بشَفَتىَّ، الرَّبُّ هُوَ نَصيبُ مِراثِى وكأسِي، أنْتَ الذِى تَردُّ إلىَّ مِيرَاثِى. حِبالُ التَّقْسِيمِ وقَعَتْ لِى فى أرْضٍ خِصْبَةٍ. وإنَّ مِيراثِى لَثَابتٌ لِى. أُبارِكُ الرَّبَّ الذِى أفْهَمنِى. وأيْضاً إلَى اللَّيلِ وعَظَتْنى كُلْيَتاىَ، تقدَّمتُ فرأيْتُ الرَّبَّ أمامِى فى كُلِّ حينٍ، لأنَّه عَنْ يَمينِى لِكْى لا أتَزَعْزعَ، مِنْ أجْل هَذا فَرِحَ قَلْبى وتَهلَّلَ لِسَانِى. جَسَدِى أيْضاً يسْكنُ عَلىِ الرَّجاءِ. لأنَّكَ لاتَتْركُ نَفْسى فى الجحِيمِ. ولاتَدَعُ قُدُّوسَكَ يَرَى فَساداً. قَدْ عَرَّفتْنِى سُبُل الحَياةِ. تَمْلأنِى فَرحاً أمامَ وجْهكَ. البَهجَةُ فى يَمينِكَ إلَى الإنْقِضاءِ. هَلِّلُويا.',
    },
    {
      'title': 'مز18: السموات تحدث بمجد الله',
      'body':
          'السَّموات تُحدِّثُ بِمَجْدِ الله. والفَلَكُ يُخْبرُ بعَمَلِ يَديْهِ. يَومِّ إلى يَوْمٍ يُبْدى قَولاً. ولَيلِّ إلَى ليلٍ يُظْهرُ عِلْماً. لاقولَ ولاكلامَ، الذِينَ لاتَسْمعُ أصْوَاتَهُم. فى كلِّ الأرْضِ خَرَجَ مَنْطقُهُم. وإلَى أقْصَى المسْكُونةِ بَلغتْ أقْوالُهُم. جَعَلَ فى الشَّمْسِ مِظلتَهُ. وهِىَ مِثلُ العَريسِ الخَارجِ مِنْ خِدْرهِ. يتَهلَّلُ مِثْل الجَبَّار الذِى يُسْرعُ فى طَريقِهِ. مِنْ أقْصَى السَّماءِ خُروجُها، ومُنْتهَاهَا إلَى أقْصَى السَّماءِ ولا شَئ يخْتَفى مِنَ حَرارَتْهَا.نَامُوسُ الرَّبِّ بِلاَعَيبٍ، يَردُّ النُّفوسَ. شَهادَةُ الرَّبِّ صادِقَةٌ، تُعلِّمُ الأطْفال. فَرائِضَ الرَّبِّ مُسْتقِيمةٌ، تُفْرحُ القَلْب. وَصيَّةُ الرَّبِّ مُضيئةٌ. تُنَيرُ العَيْنيْنِ عَنْ بُعدٍ. خَشْيةُ الرَّبِّ زَكيَّةٌ، دَائمَةٌ إلَى أبَدِ الأبَدِ. أحْكامُ الرَّبِّ أحْكامُ حَقِّ وعادِلةٌ مَعاً. مَشِيئةُ قَلْبهِ مُخْتارَةٌ أفْضَلُ مِنَ الذَّهَبِ والحَجَرِ الكَثِيرِ الثَّمنِ، وأحْلَى مِنَ العَسَلِ والشَّهدِ. عَبْدكَ يَحْفظُها، وفى حِفْظهَا ثَوابٌ عَظِيمٌ. الهَفَواتُ مِنَ يَشْعرُ بِهَا؟ مِنَ الخَطايَا المسْتَتِرةُ يَاربُّ طهِّرِنى. ومِنَ المتكبِّرينَ أحْفَظْ عَبْدَكَ، حَتَّى لايَتسَلَّطوا عَلىَّ فَحينَئذٍ أكُونُ بِلا عَيبٍ، وأتَنقَّى مِنْ خَطيَّةٍ عَظِيمةٍ، وتَكونُ جَميعُ أقْوالِ فَمِى وفِكْرِ قَلبىِ مَرضِيَّةً أمَامَكَ فى كلِّ حينٍ. يَاربُّ أنتَ مُعيِنى ومُخلِّصِى. هَلِّلُويا.',
    },
    {
      'title': 'مز24: اليك يارب رفعت نفسي',
      'body':
          'إلَيكَ يَارَبُّ رفَعْتُ نَفْسِى. يا إلهِى عَليْكَ تَوكَّلتُ. فَلاَ تُخْزنِى إلى الأبَدِ. ولا تُشْمِتْ بى أعْدائِى. لأنَّ جِميعَ الذِينَ ينْتظِرونَكَ لا يُخَزَونَ. ليُخْزَ الذِينَ يصْنَعونَ الإثْمَ باطِلاً. أظْهِرْ لى يَاربُّ طُرقَكَ، وعلِّمْنى سُبُلَكَ. إهْدِنى إلى عَدلِكَ وعلِّمْنِى. لأنَّكَ أنتَ هُو اللهُ مُخلِّصِى. وإيَّاكّ إنْتَظرتُ النَّهارَ كلَّهُ. إذْكُر يَاربُّ رَأْفاتِكَ ومَراحِمَك، لأنَّهَا ثَابتَةٌ مُنذُ الأزلِ. خَطايَا شَبَابِى وجَهْلى لا تُذْكَر. كَرحْمتِك إذْكُرنِى أنْتَ منْ أجْلِ خَلاصكَ يَاربُّ. الرَّبُّ صَالحِّ ومُسْتَقيمٌ، لِذلِكَ يُرشِدُ الذِينَ يُخْطئونَ فى الطَّريقِ. يَهْدى الوُدعَاءَ فى الحُكْمِ، يُعلِّمُ الوُدعَاءَ طُرقَهُ. جَميعُ طُرق الرَّبِّ رَحْمةٌ وحَقٌ لحَافِظِى عَهْدهِ وشَهَادَاتِه. مِنْ أجْلِ إسْمِكَ يارَبُّ إغْفِر لى خَطيَّتِى لأنَّها كَثيرةٌ. مَنْ هُو الإنْسانُ الخَائفُ الرَّبِّ، يرْشِدهُ فى الطَّريقِ التِى إرْتَضَاهَا. نَفْسهُ فى الخَيْراتِ تثْبُتُ، ونَسْلهُ يَرثُ الأرْضَ. الرَّبِّ عزٌّ لخَائفِيهِ. وإسْمُ الرَّبِّ لأتْقيَائه. ولَهُم يُعْلنُ عَهدَه. عَيْناىَ تَنْظرَان إلى الرَّبِّ فى كلِّ حينٍ. لأنَّهُ يُخْرجُ مِنْ الفخِّ رِجْلَىَّ. إنْظُرْ إلىَّ وأرْحَمنِى. لأنِّى إبنٌ وَحِيدٌ وفَقِيرٌ أنَا. أحْزانُ قَلبِى قَدْ كثُرَتْ. أخْرِجْنِى مِنْ شَدائِدِى. أنْظُر إلى ذُلِّى وتَعَبى. وأغْفِرْ لى جَمِيعَ خَطايَاىَ. أنْظُر إلى أعْدائِىِ فإنَّهمْ قَد كَثُرُوا وأبّغَضونِى ظلْماً. أحْفَظْ نَفْسِى ونَجِّنِى، لا أخْزَى لأنِّى عَليكَ تَوكَّلتُ. الذِينَ لا شَرَّ فِيهمْ والمسْتَقيمُونَ لَصقُوا بى، لأنِّى إنْتظَرْتَكَ يارَبُّ. يا اللَّهُ إنْقذْ إسْرائِيلَ مِنْ جَمِيعِ شَدائِدِهِ. هَلِّلُويا.',
    },
    {
      'title': 'مز26: الرب نوري وخلاصي',
      'body':
          'الرَّبُّ نُورِى وخَلاصِى مِمَّن أخَافُ. الرَّبُّ نَاصِرُ حَياتِى مِمَّن أجْزَعُ. عِندَ اقْتِرابِ الأشْرارِ مِنِّى لِيأْكُلوا لحْمِى، مُضايقَىَّ وأعْدائِى عَثُروا وسَقَطُوا. إنْ يُحارِبَنِى جَيشٌ فلَنْ يَخافَ قَلْبى. إنْ قامَ علىَّ قِتالٌ فَفى هَذا أنَا أطَمْئنُّ. وَاحِدة سَألتُ مِنَ الرَّبِّ وإيَّاهَا ألْتمسُ. أنْ أسْكُنَ فى بَيتِ الرَّبِّ كلَّ أيَّامِ حَياتِى. لِكىْ أنْظرَ نَعيمَ الرَّبِّ، أتَفرَّسَ فى هَيْكلِه المقُدَّسِ. لأنَّهُ أخْفانِى فى خَيْمتِهِ، فى يَومِ شِدَّتِى، سَتَرنِى بسِتْرِ مِظلَّتهِ. وعَلَى صَخْرةٍ رفَعَنى. والآنَ هُوذَا قَدْ رَفَع رَأسِى عَلَى أعْدائِى. طُفْتُ وذَبَحْتُ فى مِظلَّتِه ذَبيحَةَ التَّهْليلِ. أسبِّحُ وأرتِّلُ للرَّبِّ. اسْتَمعْ يارَبُّ صَوْتِى الذِى بِهِ دَعوتُكَ. ارْحَمنِى واسْتَجبْ لى فإنَّهُ لكَ قالَ قلْبِى: طَلبْتُ وجْهَك، ووَجْهَك ياربُّ ألْتمِسُ. لا تَحْجبْ وجْهَك عنِّى ولا تُعْرضْ بغَضَبٍ عَن عَبْدكَ. كُنْ لى مُعيناُ. لا تخْذُلنِى ولا تَرْفضنِى يَا اللهُ مُخلِّصِى. فإنَّ أبِى وأُمِّى قَدْ ترَكانِى، وأمَّا الرَّبُّ فقبِلَنِى. علِّمْنىِ ياربُّ طّريقَكَ وأهْدِنى فى سَبِيلٍ مسْتَقيمٍ مِنْ أجل أعدائىِ. لا تسلمَنى إلى أيدى مُضايِقىَّ، لأنَّه قَدْ قامَ عَلىَّ شُهودُ زُورٍ. وكَذبُوا عَلىَّ ظُلماً. أنَا أؤمِنُ أنِّى أُعايِنُ خَيْرات الرَّبِّ فى أرْض الأحْياءِ. أنْتظِرِ الرَّبِّ تَقوَّ وليتَشَدَّدْ قلْبكَ وأنْتَظِر الرَّبِّ. هَلِّلُويا.',
    },
    {
      'title': 'مز62: يا الله الهي اليك ابكر',
      'body':
          'يا اللَّهُ إلَهِى إليْكَ أُبكِّرُ. إذْ عَطِشَتْ إلَيكَ نَفْسِى. يَشْتاقُ إليْكَ جَسَدِى، فى أرْضٍ مُقفِرةٍ وموْضِعٍ غَيرِ مَسْلوكٍ ومَكانٍ بِلا مَاءٍ. هَكَذا ترَاءيْتَ لَكَ فى القُدسِ، لأرَى قُوَّتكَ ومَجْدكَ. لأنَّ رحْمتَكَ أفْضَلُ مِنَ الحَياةِ، شَفَتاىَ تُسبِّحانِكَ. لذلِكَ أُباركُكَ فى حَياتِى، وباسْمِكَ أرْفَع يَدِىَّ. فتَشَبعُ نَفْسِى كَما مِنْ شَحْمٍ ودَسَمٍ، بشِفاةِ الإبْتِهاجِ نُبارِكُ أسْمَكَ. كنْتُ أذْكرُكَ عَلى فِراشِى. وفى أوْقاتِ الأسْحَارِ كُنتُ أرتِّل لَكَ. لأنَّكَ صِرْتَ لى عَوناً، وبِظلِّ جَنَاحَيكَ أبْتَهجُ. إلْتَصقَتْ نَفْسىِ بكَ، ويَمينُكَ عَضَّدتْنِى، أمَّا الذِينَ طلَبُوا نَفْسى للْهَلاكِ، فيَدْخلُونَ فى أسافِلِ الأرْضِ. ويُدْفَعونَ إلى يَدِ السَّيْفِ، وَيكونُونَ أنْصِبَةً للثَّعالِبِ. أمَّا الملِكُ فَيفْرحُ باللهِ، ويفْتَخرُ كلُّ مَنْ يَحلفُ بهِ. لأنَّ أفْواهَ المتَكلِّمينَ بالظَّلمِ تُسَدُّ. هَلِّلُويا.',
    },
    {
      'title': 'مز66: ليتراءف الله علينا',
      'body':
          'لِيتَراءفَ اللَّهُ عَلينَا ولِيُباركِنَا، وليُنِرْ بوجْهِهِ عَليْنَا ويَرْحَمْنا. لَتُعْرفَ فى الأرْض طَريقُكَ، وفى جَميعِ الأممِ خَلاصُكَ. فلْتَعْتَرَفْ لكَ الشَّعوبُ يااللَّهُ، فلْتَعْترفْ لكَ الشُّعوبُ كلُّها. لتَفْرَح الأمَمُ وتَبْتهجُ، لأنَّكَ تدِينُ الشَّعوبَ بالإسْتِقامَةِ وتَهْدى الأممَ فى الأرْض. فلْتَعْتَرفْ لَكَ الشُّعوبُ يَااللَّهُ، فلْتَعْتَرفْ لَكَ الشُّعوبُ جَميعاً الأرْضُ أعْطَتْ ثَمَرتَها. فَليُبارِكنَا اللهُ إلهنَا. لِيُباركنَا اللهُ. فَلْتَخشَهُ جَميعُ أقْطارِ الأرْضِ. هَلِّلُويا.',
    },
    {
      'title': 'مز69: اللهم التفت الي معونتى',
      'body':
          'اللَّهُمَّ إلْتَفتْ إلى مَعُونَتِى، يَاربُّ أسْرعْ وأعِنِّى. ليُخْزَ ويَخْجَل طَالبُو نَفْسى، وليرْتَدَّ إلى خَلْفٍ ويَخْجَل الذِينَ يبْتَغونَ لى الشَّرَّ. وليرْجعَ بالخِزْىِ سَريعاً القَائِلونَ لى نَعماً نعمَا. ولِيبْتَهجْ ويَفْرَح بكَ جَميعُ الذِينَ يلْتمسُونِكَ، ولِيَقَل فى كلِّ حينٍ مُحبُّو خَلاصِكَ لِيتعَظَّمَ الرَّبُّ. وأمَّا أنَا فمِسْكينٌ وفَقِيرٌ. اللَّهمَّ أعِنِّى. أنْتَ مُعينِى ومُخلِّصِى يَاربُّ فَلا تُبْطِئ. هَلِّلُويا.',
    },
    {
      'title': 'مز112: سبحوا الرب ايها الفتيان',
      'body':
          'سبِّحُوا الرَّبِّ أيُّها الفتِيانُ، سَبِّحُوا إسْمَ الرَّبِّ. لِيَكُنِ إسْمُ الرَّبِّ مُبارَكاً مِنَ الآنِ وإلى الأبَدِ. مِنْ مَشَارقِ الشَّمْسِ إلى مَغارِبِها بَاركُوا إسْمَ الرَّبِّ. الرَّبُّ عَالٍ عَلى كلِّ الأمُمِ، فَوْقَ السَّمَوات مَجْدهُ. مَنْ مِثْلُ الرَّبِّ إلَهنَا السَّاكِنِ فى الأعَالى، النَّاظِرِ إلى المتَواضِعِينَ فى السَّماءِ وعَلى الأرْضِ. المقِيمِ المسْكِينَ مِنَ التُّرابِ، الرَّافِع البَائِسِ مِنَ المزْبَلةِ، لِكىْ يُجْلسَهُ مَعَ رُؤسَاءِ شَعْبهِ. الذِى يَجْعلُ العَاقِرَ ساكِنَة فى بَيْتٍ، أمَّ أوْلادٍ فرِحةً. هَلِّلُويا.',
    },
    {
      'title': 'مز142: يا رب اسمع صلاتي',
      'body':
          'يارَبُّ إسْمَع صَلاتِى. إنْصِتْ إلى طَلبَتِى بَحَقِّكَ. إسْتَجبْ لى بَعدْلِكَ. ولا تدْخُلْ فى المحَاكَمةِ مَعَ عَبْدكَ فإنَّهُ لَنْ يَتَزكَّىِ قُدَّامكَ كلُّ حَىِّ. لأنَّ العَدوَّ قدِ إضْطهدَ نَفْسِى، وأذَلَّ فى الأرْضِ حَياتِى. أجْلسَنِى فى الظَلَّمَاتِ مِثْلَ الموْتَى مُنْذُ الدَّهرٍ. أضّجَرتْ فى رُوحى، إضْطَربَ فى قَلْبِى. تذكَّرتُ الأيَّامَ الأولَى ولَهِجْتُ فى كلِّ أعْمالِكَ، وفى صَنائِع يَدَيْك كنْتُ أتَأمَّلُ. بَسَطتُ إليْكَ يَدىَّ، صَارتْ نَفْسِى لكَ مِثلُ أرْضٍ بِلا مَاءٍ. إسْتَجبْ لى يَاربُّ عاجلاً فَقَد فَنِيتْ رُوحِى، لا تَحْجبْ وجْهَكَ عنِّى فأشَابهُ الهابِطينَ فى الجُبِّ. فلأسْمَعْ فى الغَدَاةِ رحْمَتكَ، فإنِّى عَليكَ تَوكَّلتُ. عرِّفْنِى يارَبُّ الطَّريقَ التى أسْلُكَ فِيهَا لأنِّى إليْكَ رفَعْتُ نَفْسِى. إنْقِذْنِى مِنْ أعْدائِى يارَبُّ، فإنِّى لجأْتُ إليْكَ. علِّمنِى أنْ أصْنَعَ مَشِيئتَكَ، لأنَّك أنْتَ هُو إلهِى. رُوحُكَ القُدُّوسُ فَليهْدنِى إلى الإسْتِقامَةِ. مِنْ أجْلِ إسْمِكَ ياربُّ تُحْيِينِى، بَحَقِّكَ تُخْرجُ مِنَ الشِّدَّةِ نَفْسى. وبرَحْمتِكَ تَسْتأصِلُ أعْدائِى، وتُهلِكَ جُميعَ مُضايقى نَفْسِى لأنِّى أنَا هُو عَبْدكَ أنَا. هَلِّلُويا.',
    },
    {
      'title': 'الانجيل (يوحنا1:1-17)',
      'body':
          'فى البَدْءِ كَانَ الكَلِمةَ، والكَلِمةُ كانَ عِنْدَ اللهِ، وكانَ الكَلِمةَ اللَّهُ. هَذا كانَ فى البَدءِ عِنْدَ اللهِ. كلُّ شئٍ بهِ كانَ، وبِغيرهِ لمْ يَكُن شَئٍ مْمَّا كانَ. فِيهِ كانَتِ الحَياةُ والحَياةُ كَانَتْ نُورَ النَّاسِ والنُّورُ أضَاءَ فى الظَّلْمةِ، والظَّلْمةُ لَمْ تُدْركهُ. كانَ إنْسانٌ مُرْسَلٌ مِنَ اللهِ أسْمُه يُوحَنَّا، هَذَا جَاءَ للشَّهَادةِ لِيشْهَد للنُّورِ لِيؤمِنَ الكُلُّ بوَاسِطتهِ. لَمْ يَكُن هُوَ النُّورُ بَلْ ليشْهَدَ للنَّورِ. كانَ النُّورُ الحَقِيقىُّ الذِى يُنِيرُ كلَّ إنْسَانٍ آتِياً إلى العَالمِ. كانَ فى العَالَم وكَونُ العَالَم بهِ ولَمْ يَعْرفْهُ العَالَمُ. إلى خاصَّتِه جَاءَ، وخاصَّتُهُ لَمْ تَقْبلْهُ. وأمَّا الذِينَ قَبلُوهُ فأعْطاهُمْ سُلْطاناً أنْ يَصيرُوا أبْنَاءَ اللهِ الذِينَ يُؤمنُونَ بإسْمِهِ، الذِينَ وُلدُوا لَيسَ مِنْ دَمٍ، ولا مِنْ مَشِيئةِ جَسَدٍ، ولا مِنْ مَشِيئةِ رَجُلٍ، لِكنْ مِنَ اللهِ وُلدُوا. والكَلمةُ صارَ جَسَداً وحَلَّ بَيْننَا ورَأينَا مَجْدهُ مِثْل مَجدِ إبْنٍ وَحيدِ لأبِيهِ مَمْلوءاً نِعْمةً وحَقَّا. يُوحنَّا شَهِدَ لَهُ وصَرخَ قائِلاً: هَذا هُو الذِى قلْتُ عَنْهِ أنَّ الذِى يَأتِى بَعْدِى كانَ قَبْلِى، حَقَّا كانَ أقْدَمَ مِنِّى، ونَحنُ جَميعاً أخَذْنا مِنَ إمتِلائِه، ونعْمةً عِوضاً عَنْ نِعْمةٍ. لأنَّ النَّامُوسَ بَمُوسَى أعْطَى، أمَّا النِّعْمةُ والحَقُّ فبيَسُوع المسَيح صَاراَ. والمجْدَ للَهِ دَائماً.',
    },
    {
      'title': 'القطعة الاولي',
      'body':
          'أيُّهَا النُّورُ الحَقِيقىُّ الذِىِ يُضئُّ لِكلِّ إنْسَانٍ آتٍ إلى العَالَمِ، أتَيْتَ إلى العَالَم بِمَحِّبتَكَ للبَشَرِ، وكلُّ الخَلِيقَةِ تَهَّللَت بْمَجِيِئكَ. خَلَّصْتَ أبَانَا أدَمَ مِنَ الغِوايَةِ، وعتَقْتَ أمَّنَا حَواءَ مِنْ طَلقَاتِ الموْتِ وأعْطَيتنَا رُوحَ البُنوَّةِ، فَلنسَبِّحْكَ ونُبارِككَ قائِلينَ. ( ذُوكصَابترى )',
    },
    {
      'title': 'القطعة الثانية',
      'body':
          'عِنْدمَا دِخَلَ إليْنَا وقْتَ الصَّباحِ أيُّهَا المسَيحُ إلهنَا النّورُ الحَقِيقى، فَلتشْرقْ فَينَا الحَواسُّ المضِيئةُ والأفْكارُ النُّورانَّيةُ. ولا تُغَطِّينَا ظُلْمة الآلاَمِ، لِكىْ نُسبِّحكَ عَقليَّاً مَعَ دَاودَ قَائلينَ: "سَبَقَتْ عَيْنَاىَ وقْتَ السَّحَر لأتَلُو فى جَمِيعِ أقْوالِكَ". إسْمَعُ أصْواتَنَا كعَظيَم رَحْمَتِكَ، ونجِّنا أيُّها الرَّبُّ إلهنَا بَتحنُّنكَ. ( كى نين )',
    },
    {
      'title': 'القطعة الثالثة',
      'body':
          'أنْت هِىَ أمُّ النُّورِ المكرَّمةُ مِنْ مَشَارقِ الشَّمسِ إلى مَغارِبَها، يُقدِّمُونَ لَكَ تَمْجيدَات يَاوَالدَة الإلَهِ السَّماء الَّثانِيَة، لأنَّكَ أنْتَ هِىَ الزَّهْرةُ النَّيِّرةُ غَيْر المتَغيِّرةِ والأمُّ البَاقِيةَ عَذْراءَ لأنَّ الآب إخْتَارك والرُّوحَ القُدُس ظَلَّلك والأبْنَ تَنازَلَ وتَجسَّدَ مِنْك. فإسْألِيهِ أنْ يُعْطىَ الخَلاصَ للعالَمِ الذِى خَلقَهُ، وأنْ يُنجيَهُ مِنَ التَّجارِبِ. ولنُسَبِّحهُ تَسْبيحاً جَدِيداً ونُباَرِكهُ الآنَ وكُلَّ أوانٍ وإلى الأبَدِ. آمين.',
    },
    {
      'title': 'تسبحة الملائكة',
      'body':
          'فَلْنُسبِّحْ مَعَ الملائِكةِ قائِلينَ: المجْدُ للهِ فى الأعالِى وعَلَى الأرْضِ السَّلامُ وَفى النّاسِ المسَرَّةُ. نُسَبِّحكَ. نُبارِككَ. نَخْدمُكَ. نَسْجُدُ لَكَ. ونَعْترِفُ لكَ. نَنْطقُ بمَجْدكَ. نَشْكُركَ مِنْ أجْل عِظَمِ مَجْدكَ. أيُّها الرَّبُّ المالِكُ عَلَى السَّمواتِ اللهُ الآبُ ضابِطُ الكُلِّ، والرَّبُ الابْنُ الواحدُ الوَحيدُ يسوعُ المسيحُ، والرّوحُ القُدُسُ. أيُّها الرِّبُّ الإلَهُ حَمَل الله إبْنَ الآبِ رافِعَ خَطِيّةِ العالَم إرْحَمْنا. يا حَامِلَ خطيَّةِ العالَم اقْبَل طَلَباتِنا إليْكَ. أيُّها الجالسُ عَنْ يَمينِ أبيهِ ارْحَمْنا. أنْتَ وحْدَكَ القُدّوسُ. أنْتَ وحْدَكَ العالى يا رَبّى يسوعُ المسيحُ والرّوحُ القُدُسُ. مَجْداً للهُُُ الآبَ آمين. أُبارِككَ كُلَّ يَومٍ، وأسبِّحُ إسْمَكَ القُدّوسَ إلَى الأبَدِ وإلَى أبَدِ الأبَدِ آمين. مُنْذُ اللَّيلِ روحى تُبَكرُ إليْكَ يا إلَهى، لأنَّ أوامِركَ هِىَ نورٌ عَلَى الأرْضِ. كنْتُ أتْلو فى طُرقكَ، لأنَّكَ صِرْتَ لِى مُعيناً. باكراً يا ربُّ تَسْمعُ صوْتى، بالغَداةِ أقِفُ أمامكَ وتَرانى.',
    },
    {
      'title': 'الثلاث تقديسات',
      'body':
          'قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الَّذى وُلِدَ مِنَ العَذْراءِ إرْحَمْنا. قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الَّذى صُلِبَ عنّا إرْحَمْنا. قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الّذى قامَ مِنَ الأمْواتِ وصَعِدَ إلَى السَّمواتِ إرْحَمْنا. المجْدُ للآبِ والإبنِ والرّوحِ القُدُسِ، الآنَ وكلُّ أَوان وإلَى دَهْرِ الدّهورِ آمين. أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، يا رَبُّ إغْفِرْ لَنا خَطايانا. يا رَبُّ إغْفِرْ لَنا آثامَنا، يا رَبُّ إغْفِرْ لَنا زَلاّتَنا. يا رَبُّ إفْتَقدْ مَرْضَى شَعْبكَ، إشْفِهمْ مِنْ أجْل إسْمكَ القُدّوسِ. آباؤُنا وإخْوَتنا الَّذينَ رَقدوا يا رَبُّ نَيِّحْ نُفوسَهُم، يا مَنْ هُوَ بِلا خَطيَّة يا رَبُّ إرْحَمْنا، يا الَّذى بِلا خَطيَّةِ يا رَبُّ أَعِنّا، واقْبَلْ طَلباتِنا إلَيْكَ. لأنَّ لَكَ المجْدَ والعِزَّةَ والتَّقْديسَ المثلَّثَ. يا رَبُّ إرْحَمْ، يا رَبُّ إرْحَمْ، يا رَبُّ بارِكْ. آمين.',
    },
    {
      'title': 'الصلاة الربانية',
      'body':
          'اللَّهُم اجْعلنا مُستحِقين أنْ نقولَ بِشكرٍ: أبانا الذي في السَّمَواتِ، لِيتَقدس اسْمكَ. ليأتِ مَلكوتُكَ. لتَكن مَشيئَتُكَ، كما في السّماءِ كَذلك على الأرْضِ. خُبزَنا الذي للغدِ اعطِنا اليومَ. واغفِر لنا ذنوبَنا كما نغْفر نحنُ أيضّا للمذنبينَ إلينا. ولا تُدخِلنا في تَجرِبةٍ. لكن نجّنا مِنْ الشّريرِ. بالمسيحِ يسوعُ ربُّنا، لأنَّ لَكَ المُلكَ والقوةَ والمجدَ إلى الأبدِ. آمين.',
    },
    {
      'title': 'السلام لك',
      'body':
          'السَّلامُ لَك. نَسْألكِ أيَّتُها القِدّيسَةُ الممْتَلِئةُ مَجْداً العَذْراءُ كلَّ حينٍ والِدةُ الإلَهِ أمُّ المسيحِ، أصْعدى صَلَواتَنا إلَى إبْنِكِ الحَبيبِ ليغْفِرَ لَنا خَطايانا. السَّلامُ لِلَّتى وَلَدتْ لَنا النّورَ الحَقيقىَّ المسيحَ إلَهنا العَذْراءُ القدّيسَةُ، إسْألى الرَّبَّ عنّا ليَصْنَعَ رَحْمَةً مَعَ نُفوسِنا ويغْفر لَنا خَطايانا. أيَّتُها العَذْراءُ مَرْيَم والِدةُ الإلهِ القِدّيسَةُ الشَّفيعَةُ الأمينَةُ لجنْسِ البَشرِيّةِ، إشْفَعى فينا أَمامَ المَسيحِ الَّذى وَلدْتيهِ لِكَىْ يُنْعِم عَلَيْنا بغُفْران خَطايانا. السَّلامُ لَكِ أيَّتُها العَذْراءُ الملِكةُ الحَقيقيَّةُ. السَّلامُ لفَخْر جنْسِنا، وَلدْتِ لَنا عمّانوئيل. نَسْألُكِ اذْكرينا أيَّتُها الشَّفيعَةُ المؤْتَمَنةُ أَمامَ ربِّنا يَسوعِ المسيحِ ليغْفِرَ لَنا خَطايانا.',
    },
    {
      'title': 'بدء قانون الإيمان',
      'body':
          'نُعظِّمُكِ يا أمَّ النّورِ الحَقيقىِّ ونُمجِّدكِ أيَّتُها العَذْراءُ القِدّيسةُ والِدةُ الإلهِ لأنَّكِ وَلدْتِ لَنا مُخلِّصَ العالَم، أتَى وخَلَّصَ نُفوسَنا. المجْدُ لكَ يا سَيِّدُنا ومَلكُنا المسيحُ، فَخْرَ الرُّسُل، إكْليلَ الشُهداءِ، تَهْليلَ الصِدّيقينَ، ثَباتَ الكَنائسِ، غُفْرانَ الخَطايا. نُبشِّرُ بالثَّالوثِ القُدّوسِ، لاهوتٌ واحِدٌ نَسجُدُ لهُ ونُمجِّدهُ يا رَبُّ إرْحَم. يا رَبُّ إرْحَم. يا رَبُّ بارِك. آمين.',
    },
    {
      'title': 'قانون الإيمان',
      'body':
          'بالحَقيقَةِ نُؤمِنُ بإلهٍ واحدٍ اللَُّهُ الآبُ ضابطُ الكُلِّ خالِقُ السَّماءِ والأرضِ، ما يُرَى وما لا يُرَى. نُؤمِنُ بربٍّ واحدٍ يَسوعِ المسيحِ إبْن اللهِ الوَحيدِ الموْلودِ مِنَ الآبِ قَبْلَ كلِّ الدُّهورِ. نورٌ مِنْ نورٍ إلهٌ حَقٌ مِنْ إلهٍ حَقٍّ، مَولودٌ غَيْرُ مَخْلوقٍ، مُساوٍ للآبِ فى الجَوْهرِ. الَّذى بِهِ كانَ كلُّ شئٍ. هَذا الَّذى مِنْ أجْلنا نَحنُ البَشَرَ ومِنْ أجْلِ خَلاصِنا نَزلَ مِنَ السَّماءِ وتَجسَّدَ مِنَ الرّوحِ القُّدُسِ، ومِنْ مَرْيَم العَذْراءِ تَأنَّسَ. وصُلبَ عنّا علَى عَهدِ بيلاطُس البنْطى، تألَّمَ وقُبرَ وقامَ مِن بَين الأمْواتِ فى اليَومِ الثّالثِ كَما في الكتُبِ، وصَعِدَ إلَى السَّمواتِ وجَلسَ عَنْ يَمينِ أبيهِ وأيْضاً يَأتي فى مَجدهِ ليُدينَ الأحْياءَ والأمْوات، الَّذى لَيسَ لملْكِهِ إنْقِضاءٌ. نَعَم نُؤمِنُ بالرّوحِ القُدُسِ، الرَّبُّ المحْيى المنْبَثقِ مِنَ الآبِ نَسْجُد لهُ ونُمجِّدهُ مَعَ الآبِ والإبْنِ النّاطِقِ فى الأنْبياءِ. وبكنيسَةٍ واحِدَةٍ مُقدَّسةٍ جامعَةٍ رسوليَّةٍ، ونَعْترِفُ بمَعْموديَّةٍ واحِدَةٍ لمغْفِرَةِ الخَطايا. وننْتَظرُ قِيامَةَ الأمْواتِ وحَياةَ الدَّهرِ الآتى. آمين.',
    },
    {
      'title': 'كيريى لَيْسُون',
      'body': 'يُقال ( كيريى لَيْسُون ) يَارَبُّ ارْحَمْ 41 مرة.',
    },
    {
      'title': 'قدوس قدوس قدوس',
      'body':
          'قُدّوسٌ قُدّوسٌ قُدّوسٌ رَبُّ الصَّباؤوتِ. السَّماءُ والأرْضُ مَمْلوءتانِ مِنْ مَجْدكَ وكَرامَتكَ. إرْحَمْنا يا اللَّهُ الآبُ ضابِطُ الكُلِّ، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا. أيُّها الرَّبُّ إلهُ القُوّاتِ كُنْ مَعَنا، لأنَّهُ لَيسَ لَنا مُعينٌ فى شَدائِدنا وضيقاتِنا سِواكَ. حلّ واغْفِرْ واصْفَحْ لَنا يا اللَّهُ عَنْ سَيِّئاتِنا الَّتى صَنَعْناها بإرادَتِنا والَّتى صَنَعْناها بغَيرِ إرادَتنا، الَّتى فَعلْناها بمَعرِفةٍ والَّتى فَعلْناها بغَير مَعْرِفةٍ، الخَفيَّةِ والظاهِرةِ، يا رَبُّ اغْفِرها لَنا مِنْ أجْلِ إسْمِكَ القُدّوسِ الَّذى دُعى عَليْنا. كَرحْمتِكَ يا رَبُّ ولا كَخَطايانا.',
    },
    {
      'title': 'الصلاة الربانية',
      'body':
          'للَّهُم اجْعلنا مُستحِقين أنْ نقولَ بِشكرٍ: أبانا الذي في السَّمَواتِ، لِيتَقدس اسْمكَ. ليأتِ مَلكوتُكَ. لتَكن مَشيئَتُكَ، كما في السّماءِ كَذلك على الأرْضِ. خُبزَنا الذي للغدِ اعطِنا اليومَ. واغفِر لنا ذنوبَنا كما نغْفر نحنُ أيضّا للمذنبينَ إلينا. ولا تُدخِلنا في تَجرِبةٍ. لكن نجّنا مِنْ الشّريرِ. بالمسيحِ يسوعُ ربُّنا، لأنَّ لَكَ المُلكَ والقوةَ والمجدَ إلى الأبدِ. آمين.',
    },
    {
      'title': 'التحليل',
      'body':
          'أيُّها الرَّبُّ إلَهُ القُوّاتِ الكائنُ قَبْل الدُّهورِ، والدّائمُ إلَى الأبَدِ، الَّذى خَلقَ الشَّمسَ لِضياءِ النَّهارِ واللَّيلَ راحَةً لِكلِّ البَشَرِ، نشْكُركَ يا مَلكَ الدُّهورِ لأنَّكَ أجَزْتَنا هَذا اللَّيلَ بِسَلامٍ وأتَيْتَ بِنا إلَى مَبْدأ النَّهارِ. مِنْ أجْل هَذا نَسْألكَ يا مَلِكنا مَلكَ الدُّهورِ، ليشْرقْ لَنا نورُ وجْهكَ وليُضِئ عَلَيْنا نورُ عِلْمكَ الإلَهى. واجْعَلنا يا سَيِّدنا أنْ نَكونَ بَنى النّورِ وبَنى النَّهارِ، لِكىْ نَجوزَ هَذا اليوْمَ بِبِرٍّ وطهارةٍ وتَدْبيرٍ حَسَنٍ، لِنكمِّلَ بَقيَّةَ أيّامِ حَياتِنا بِلا عَثْرةٍ. بالنِّعمةِ والرَّأفةِ ومَحَبةِ البَشَرِ اللَّواتى لإبْنِكَ الوَحيدِ يَسوعِ المسيحِ، ومَوْهبَةِ روحِكَ القُدّوس. الآنَ وكلّ أوانٍ وإلَى الأبَدِ. آمين.',
    },
    {
      'title': 'تحليل أخر',
      'body':
          'أيُّها الباعثُ النّورَ فَينْطلقُ، المشْرِقُ شَمسه عَلى الأبْرارِ والأشْرارِ، الَّذى صَنَع النّورَ الَّذى يُضئ عَلَى المسْكونةِ، أنِرْ عُقولَنا وقُلوبَنا وأفْهامَنا يا سَيِّد الكلِّ.هَبْ لَنا فى هَذا اليَومِ الحاضِرِ أنْ نُرْضيكَ فيهِ، واحْرُسْنا مِنْ كلِّ شئٍ ردِئٍ، ومِنْ كلِّ خَطيَّةٍ، ومِنْ كلِّ قُوةٍ مُضادةٍ بالمسيحِ يَسوعِ ربِّنا. هَذا الَّذى أنْتَ مُبارَكٌ مَعهُ ومَعَ الرّوحِ القُدُسِ المحْيى المساوِى لَكَ الآنَ وكلُّ أَوانٍ وإلَى دَهْرِ الدُّهورِ. آمين.',
    },
    {
      'title': 'طلبة آخر كل ساعة',
      'body':
          'إرْحَمْنا يا اللَّهُ ثمَّ إرْحَمْنا، يا مَنْ فى كلِّ وقْتٍ وكلِّ ساعَةٍ، فى السَّماءِ وعلَى الأرْض مَسْجودٌ لَهُ ومُمجَّدٌ، المسيحُ إلَهنا الصّالحُ الطَّويلُ الرّوحِ الكثيرُ الرَّحْمةِ الجَزيلُ التَّحنُّنِ، الَّذى يُحبُّ الصِّدّيقيَن ويَرْحمُ الخُطاةَ الَّذينَ أوَّلهُم أَنا، الَّذى لا يَشاءُ مَوْت الخاطِئ مِثل ما يَرجعُ ويَحْيا، الدّاعى الكُلَّ إلَى الخَلاصِ لأجْلِ الموْعدِ بالخَيْراتِ المنْتَظرةِ. يا رَبُّ اقْبَل مِنّا فى هَذهِ السّاعةِ وكُلِّ ساعَةٍ طلباتِنا. سَهِّلْ حَياتَنا، وأرشِدْنا إلَى العَمَل بوَصاياكَ. قَدِّسْ أرْواحَنا.طهِّرْ أجْسامَنا. قَوِّمْ أفْكارَنا. نَقِّ نِيّاتَنا واشْفِ أمْراضَنا واغْفِرْ خَطايانا. ونَجِّنا مِنْ كلِّ حُزنٍ رَدئٍ ووَجَِعِ قَلْبٍ، أحِطْنا بمَلائِكتِكَ القدّيسينَ لكىْ نَكونَ بمُعَسْكَرهِم مَحْفوظينَ ومُرْشَدينَ، لنَصِلَ إلَى إتِّحاد الإيمانِ وإلَى مَعْرفةِ مَجْدكَ غَيرِ المحْسوسِ وغَيْر المحْدود، فإنَّكَ مُبارَكٌ إلَى الأبَدِ. آمين',
    },
  ];

  final List<Map<String, String>> arbonPrayers = [
    {
      'title': 'صلاة الشكر',
      'body':
          'فَلْنشْكُرّ صَانِعَ الخَيراتِ الرَّحُومَ الله أبَا رَبِّنَا وإلهِنَا ومُخَلِصَنا يَسُوعِ المسِيحِ. لأنَّهُ سَتَرنَا، وأعَانَنَا، وحَفِظَنا، وقَبِلَنا إليهِ، وأشْفَقَ عَلينَا، وعَضَّدنَا، وأَتَى بنا إلى هَذِهِ السَّاعَة. هُو أيْضاً فَلْنَسْأَلَهُ أنْ يَحْفَظَنا فى هَذَا اليَومِ المقَدَّسِ وكُلِّ أيَّامِ حَيَاتنَا بكلِّ سَلامِ. الضَّابِطُ الكُلّ الرَّبُ إلَهنَا. أيُّهَا السَّيِدُ الرَّبُّ الإلَه ضَابطُ الكُلِّ أبُو ربِّنَا وإلهنَا ومُخَلصَّنَا يَسُوعِ المسِيح نَشْكرُكَ عَلَى كُلِّ حالٍ، ومِنْ أجْل كلِّ حَالٍ، وفى كُلِّ حالٍ، لأنَّكَ سَترْتَنا، وأعَنْتَنا، وحفِظْتنَا، وقَبلْتنَا إليْكَ، وأشْفَقْت عَلينا، وعَضَّدْتَنَا، وأتَيتَ بِنَا إلىَ هَذِه السَّاعةِ. من أجْلِ هَذَا نَسْألُ ونَطْلبُ مِنْ صَلاحِكَ يَامُحبَّ البَشَر، امْنَحنَا أنْ نُكْملَ هذا اليَوْمَ المقَدَّسَ وكلّ أيَّامِ حَياتِنَا بِكلِّ سَلامٍ مَعَ خَوفِكَ، كُلُّ حَسَدٍ، وكلُّ تَجربَةٍ. وكلُّ فِعْلِ الشَّيْطانِ، ومُؤامَرةِ النَّاسِ الأشْرارِ، وقِيام الأعْدَاءِ الخَفيِّينَ والظَّاهِرينَ، إنْزَعهَا عنَّا وعَنْ سَائِرِ شَعْبكَ وعَنْ مَوضِعِكَ المقَدَّسِ هَذا. أمَّاَ الصَّالِحاتُ والنَّافعاتُ فَارزُقْنا إيَّاهَا. لأنَّكَ أنْتَ الذِى أعْطَيتَنا السُّلْطانَ أنْ ندوسَ الحَيَّاتِ والعَقارِبَ وكُلَّ قوَّةِ العَدوِّ. ولا تُدْخِلنَا فى تَجربَةٍ، لَكنْ نَجِّنا مِنَ الشِّرِّيرِ. بالنِّعْمةِ والرَّأْفَاتِ ومَحبَّة البَشرِ اللَّواتِى لإبْنِك الوَحيدِ ربِّنا وإلهِنَا ومُخلِّصِنا يَسُوعِ المسيحِ. هَذَا الذِى مِنْ قِبَلِه الَمجْدُ والإكْرام والعزَّةُ والسُّجودُ تَلِيقُ بكَ مَعهُ مَعُ الرُّوحِ القُدُسِ الَمحْيى المسَاوِى لَكَ الآنَ وكلَّ أوَانٍ وإلىَ دَهرِ الدُّهُورِ. آمين.',
    },
    {
      'title': 'المزمور الخمسون',
      'body':
          'إرْحَمنِى يَا الله كَعَظيمِ رَحْمتِكَ، ومِثْل كَثْرةِ رَأفتِكَ تَمْحُو إثْمِى. تَغْسلُنِى كَثيراً مِنْ إثْمِى، ومِنْ خَطيَّتِى تُطهَّرنِى. لأنِّى عارفٌ بإثْمِى، وخَطيَّتِى أمَامِى فى كلِّ حينٍ. لَكَ وحْدَك أخْطأْت، والشَّرُّ قدامَكَ صَنعْتُ. لِكىْ تَتَبرَّرَ فى أقْوالِكَ. وتَغْلبَ إذَا حَاكمْت. لأنِّى هَا أنَذَا بالاثْمِ حُبلَ بِى، وبالَخَطايَا وَلَدتْنِى أمِّى. لأنَّكَ هَكَذا قَدْ أحْبَبتُ الحقَّ، إذْ أوْضَحتَ لِى غَوامِضَ حِكْمتِكَ ومَسْتورَاتِها. تَنضَحُ عَلىَّ بِزُوفَاكَ فأطَّهَّرُ، تَغْسلُنِى فَأبْيضُّ أكْثَر مِنَ الثَّلجِ، تَسْمعُنِى سُرُوراً وفَرحاً، فتَبْتهجُ عِظامِى المنْسَحقةُ. أصْرِفْ وجْهَكَ عَنْ خَطايَاىَ، وأمْحُ كلَّ اثَامِى. قَلبِاً نَقياً أخْلقْ فىَّ يَا الله، ورُوحاً مُسْتَقيماً جدِّدهُ فى أحْشَائِى. لا تَطْرحْنِى مِنْ قُدَّامَ وجْهكَ، ورُوحكَ القُدُّوسِ لا تَنْزعْهُ مِنِّى. امْنَحْنِى بَهْجةَ خَلاصِكَ، وبرُوحِ مُدبِّرٍ عَضِّدّنِى فأعْلمِ الأثَمَةَ طُرُقكَ، والمنَافِقونَ إليْكَ يَرجعونَ، نَجِّنِى مِنَ الدِّماء يا الله إلَه خَلاصِى، فيَبتَّهجُ لِسانِى ببرَّكَ. يَاربِّ إفْتَح شَفتَىَّ فَيُخبرُ فَمِى بَتَسْبيحِكَ. لأنَّكَ لَوْ أثَرتَ الذَّبيحةَ، لَكُنْتُ الآنَ أعْطِى. ولَكنَّكَ لا تُسرُّ بالَمحْرقَاتِ، فالذَبيحَةُ للهِ رُوحَّ مُنْسحقَّ. القَلْبُ المنْكسِرُ والمتَواضِعُ لايُرْزلهُ الله، أنْعمْ يَا ربّ بِمَسرتكَ عَلى صِهْيُون، ولْتَبنِ أسْوَارَ أورْشَلِيم. حِينَئذٍ تُسرُّ بذَبائِح البَرِّ قرباناً ومُحْرقَات ويُقَّربون عَلى مَذابِحكَ العُجُول. هَلِّلُويا.',
    },
    {
      'title': 'بدء الصلاة',
      'body':
          'تَسْبحَةُ الغُروب مِنَ النَّهارِ المبارَكِ أقدِّمها للْمَسيحِ مَلِكى وإلَهى وأرْجوهُ أنْ يَغْفرَ لِى خَطاياىَ.',
    },
    {
      'title': 'مز116: سبحو الرب يا جميع الامم',
      'body':
          'سَبِّحوا الرَّبَّ يا جَميعَ الأممِ، ولتُبارِكهُ كافَّةُ الشُّعوب، لأنَّ رَحْمَتهُ قَدْ قَويَتْ عَليْنا، وحَقُّ الرَّبِّ يَدومُ إلَى الأبَدِ. هَلِّلُويا.',
    },
    {
      'title': 'مز117: اعترفوا للرب لانه صالح',
      'body':
          'اعْتَرفوا للرَّبِّ لأنَّهُ صالِحُ وأنَّ إلَى الأبَدِ رَحْمَتَهُ. لِيَقُلْ بَيْتُ إسْرائيلَ إنَّهُ صالِحٌ وإنَّ إلَى الأبَدِ رَحْمَتَهُ. لِيَقُلْ بَيْتُ هَرونَ إنَّهُ صالِحٌ وإنَّ إلَى الأبَدِ رَحْمَتَهُ. لِيَقُلْ أتْقِياءُ الرَّبِّ إنَّهُ صالِحٌ وإنَّ إلَى الأبَدِ رَحْمَتَهُ. فى ضيقَتى صَرَخْتُ إلَى الرَّبِّ، فاسْتَجابَ لى وأخْرجَنى إلَى الرَّحْبِ. الرَّبُّ عَوْنى فَلا أخْشَى، ماذا يَصْنعُ بى الإنْسانُ؟ الرَّبُّ لى مُعينٌ، وأنا أرَى بأعْدائى. الإتِّكالُ عَلَى الرَّبِّ خَيْرٌ مِنَ الإتِّكالِ عَلَى البَشَرِ. الرَّجاءُ بالرَّبِّ خَيْرٌ مِنَ الرَّجاءِ بالرُّؤَساءِ. كُلُّ الأممِ أَحاطوا بى، وباسْمِ الرَّبِّ انْتَقَمتُ مِنْهُمْ. أَحاطوا بى احْتِياطًا واكْتَنَفونى وباسْمِ الرَّبِّ قَهَرْتُهُمْ. أَحاطوا بي مِثْلَ النَّحْلِ حَولَ الشَّهْدِ، والْتَهَبوا كَنارٍ فى شَوْكٍ، باسْمِ الرَّبِّ انْتَقمْتُ مِنْهُم. دُفِعْت لأَسْقُطَ والرَّبّ عَضدَنى. قُوَّتى وتَسْبِحَتى هُوَ الرَّبُّ، وقَدْ صارَ لى خَلاصاً. صَوْتُ التَّهْليلِ والخَلاصِ فى مَساكِنِ الأبْرارِ، يَمينُ الرَّبِّ صَنَعَتْ قُوَّةً، يَمينُ الرَّبِّ رَفَعَتْنى، يَمينُ الرَّبِّ صَنَعَتْ قُوَّةً فَلَنْ أَموت بَعْدَ، بَلْ أحْيا وأُحَدِّثُ بأعْمالِ الرَّبِّ، تأْديبًا أدَّبَنى الرَّبُّ. وإلَى الموْتِ لَمْ يُسلِمنى. إفْتَحوا لى أبْوابَ البِرِّ، لِكَىْ أدْخُلَ فيها وأعْتَرف للرَّبِّ. هَذا هُوَ بابُ الرَّبِّ، والصِّدّيقونَ يَدْخُلونَ فيهِ. أعْتَرفُ لَكَ يارَبُّ، لأنَّكَ اسْتَجَبْتَ لى وكُنتَ لى مُخلِّصًا. الحَجَرُ الَّذى رَذَلهُ البَنّاؤونَ، هَذا صارَ رَأْسًا للزّاوِيةِ. مِنْ قِبَلِ الرَّبِّ كانَ هَذا وهُوَ عَجيبٌ فى أعْيُننا. هَذا هُوَ اليَوْمُ الَّذى صَنَعَهُ الرَّبُّ، فَلْنَبْتَهجُ ونَفْرَحُ فيهِ. يا رَبُّ خَلِّصْنا، يارَبُّ سَهِّلْ سُبُلَنا، مُبارَكٌ الآتى باسْمِ الرَّبِّ، بارَكْناكُم مِنْ بَيْتِ الرَّبِّ، اللَّهُ الرَّبّ أضاءَ عَلَيْنا. رَتِّبوا عيداً بِمَوْكِبٍ حَتَّى قُرونِ المذْبَحِ، أنْتَ هُوَ إلَهى فأشْكُركَ، إلَهى أنْتَ فَأَرْفَعكَ. أعْتَرفُ لَكَ يا رَبُّ، لأنَّكَ إسْتَجَبتَ لى وصِرْتَ لى مُخلِّصًا. اشْكُروا الرَّبَّ فإنَّه صالحٌ وأنَّ إلَى الأبَدِ رَحْمتُهُ. هَلِّلُويا.',
    },
    {
      'title': 'مز119: اليك يا رب صرخت',
      'body':
          'إلَيْكَ يا رَبُّ صَرَخْتُ فى حُزْنى، فاسْتَجَبْتَ لى. يا رَبُّ نَجِّ نَفْسى مِنَ الشِّفاهِ الظّالمةِ، ومِنَ اللِّسانِ الغاشِ، ماذا تُعْطَى وماذا تُزادُ أيُّها اللِّسانُ الغاشُّ؟ سِهامُ الأقْوياءِ مُرهَفةٌ مَعَ جَمْر البَرِّيَةِ. ويْلٌ لى فإنَّ غُرْبَتى قَدْ طالَت عَلَّى، وسَكنْتُ فى مَساكِن قيدار. طَويلاً سَكنَتْ نَفْسى فى الغُرْبَةِ، ومَعَ مُبْغِضى السَّلامِ كُنْتُ صاحِبَ سَلامٍ. وحينَ كُنتُ أُكَلِّمهُم بهِ كانوا يُقاتِلونَنى باطلاً. هَلِّلُويا.',
    },
    {
      'title': 'مز120: رفعت عيني الي الجبال',
      'body':
          'رَفَعْتُ عَيْنَيَّ إلَى الجِبالِ، مِنْ حَيْثُ يَأتى عَوْنى. مَعونَتى مِنْ عِنْدِ الرَّبِّ، الَّذى صَنَعَ السَّماءَ والأرْضَ. لا يُسَلِّمُ رِجْلَكَ للزَّللِ، فَما يَنْعسُ حافِظُك. هُوَذا لا يَنْعَسُ ولا يَنامُ حارِسُ إسْرائِيلَ. الرَّبُّ يَحْفَظُكَ، الرَّبُّ يُظلَّلُ عَلَى يَدِكَ اليُمْنَى. فَلا تَحْرقُكَ الشَّمْسُ بالنَّهارِ، ولا القَمَرُ باللَّيْلِ. الرَّبُّ يَحْفَظكَ مِنْ كُلِّ سوءٍ، الرَّبُّ يَحْفَظُ نَفْسَك. الرَّبُّ يَحْفَظُ دُخولَكَ وخُروجَكَ مِنَ الآنِ وإلَى الأبَدِ. هَلِّلُويا.',
    },
    {
      'title': 'مز121: فرحت بالقئلين لي',
      'body':
          'فَرحْتُ بالقائِلينَ لى إلَى بَيْتِ الرَبِّ نّذْهَبُ. وَقَفَتْ أرْجلُنا فى أبْوابِ أورُشَليم. أورُشَليمُ المبْنِيَّةُ مِثْل مَدينَةٍ مُتَّصِلةٍ بَعْضُها ببَعْضٍ. لأَّن هُناكَ صَعِدَت القَبائِلُ، قَبائِلُ الرَّبِّ شَهادةً لإسْرائِيلَ. يَعْتَرِفونَ لإسْمِ الرَّبِّ. هُناكَ نُصِبَتْ كَراسِى للْقَضاءِ، كَراسى بَيْتِ داوُدَ. إسْأَلوا السَّلامَ لأورُشَليمَ، والخِصْبَ لِمُحِبِّيكِ، لِيَكُنْ السَّلامُ فى حِصْنِك، والخِصْبُ فى أبْراجِك الرَّصينَةِ. مِنْ أجْلِ إخْوَتي وأقارِبى، تَكَلَّمتُ مِنْ أجْلِك بالسَّلامِ. ومِنْ أجْلِ بَيْتِ الرَّبِّ إلَهِنا، إلْتَمَسْتُ لَك الخَيْرات. هَلِّلُويا.',
    },
    {
      'title': 'مز122: اليك رفعت عيني',
      'body':
          'إلَيْكَ رفَعْتُ عَيْنى يا ساكِنَ السَّماءِ. فَها هُما مِثْل عُيونِ العَبيدِ إلَى أيْدى مَواليهمْ، ومِثْل عَيْنَى الأمَةِ إلَى يَدَىْ سَيِّدَتِها. كَذَلِكَ أعْيُنُنا نَحْو الرَّبِّ إلَهِنا حَتَّى يَتَرأفَ عَلَيْنا. إرْحَمْنا يا رَبُّ إرْحَمْنا، فإنَّنا كَثيراً ما امْتَلأْنا هَواناً. وكَثيراً ما امْتَلأَتْ نُفوسُنا عاراً مِنَ المخَصِّبينَ، وإهانَةً مِنَ المتَعَظِّمينَ. هَلِّلُويا.',
    },
    {
      'title': 'مز123: لولا ان الرب كان معنا',
      'body':
          'لَوْلا أنَّ الرَّبَّ كانَ مَعنا لِيَقُلْ إسْرائيلُ. لَوْلا أنَّ الرَّبَّ كان مَعنا عِنْدَما قامَ النّاسُ عَلَيْنا. لابْتَلَعونا ونَحْنُ أحْياء، عِنْدَ سَخطِ غَضَبِهِمْ عَلَيْنا. إذَنْ لَغرَقْنا فى الماءِ، وجازَ عَلَى نُفوسِنا السَّيْلُ. بَلْ جازَ عَلَى نُفوسِنا الماءُ الَّذى لا نِهايَةَ لَهُ. مُبارَكٌ الرَّبُّ الّذى لَمْ يُسَلِّمْنا فَريسةً لأسْنانِهِم. نَجَتْ أنْفُسُنا مِثْلَ العُصْفورِ مِنْ فَخِّ الصَّيّادينَ، الفَخُّ انْكَسَرَ ونَحْنُ نَجَوْنا، عَوْنُنا بإسْمِ الرَّبِّ، الَّذى صَنَعَ السَّماءَ والأرْضَ. هَلِّلُويا.',
    },
    {
      'title': 'مز124: المتوكلون علي الرب',
      'body':
          'المتَوَكِّلونَ عَلَى الرَّبِّ مِثْلُ جَبَلِ صِهْيونَ، لا يَتَزعْزَعُ إلَى الأبَدِ. السّاكِنُ بأورُشَليمَ. الجِبالُ حَوْلَها والرَّبُّ حَوْلَ شَعبهِ مِنَ الآنَ وإلَى الأبَدِ. الرَّبُّ لا يَتْركُ عَصا الخُطاةِ تَسْتقرُّ عَلَى نَصيبِ الصِّدّيقينَ. لِكَىْ لا يَمُدَّ الصِّدّيقونَ أيْدِيَهُم إلَى الإثْمِ. أحْسِنْ يا رَبُّ إلَى الصّالِحينَ وإلَى المسْتقيمى القُلوبِ. أمّا الَّذينَ يَميلونَ إلَى العَثَراتِ يَنْزَعهُم الرَّبُّ مَعَ فَعَلةِ الإثْمِ. والسَّلامُ عَلَى إسْرائِيلَ. هَلِّلُويا.',
    },
    {
      'title': 'مز125: اذا ما رد الرب سبي صهيون',
      'body':
          'إذا ما رَدَّ الرَّبُّ سَبْىَ صِهْيونَ صِرْنا فَرِحينَ. حينَئِذٍ امْتَلأَ فَمُنا فَرحًا ولِسانُنا تَهْليلاً. حينَئِذٍ يُقالُ فى الأممِ إنَّ الرَّبّ قَدْ عَظَّمَ الصَّنيعَ مَعَهُم. عَظَّمَ الرَّبُّ الصَّنيعَ مَعَنا فَصِرْنا فَرِحينَ. ارْدد يا رَبُّ سَبْيَنا، مِثْلَ السُّيولِ فى الجَنوبِ. الَّذينَ يَزْرَعونَ بالدُّموعِ يَحْصُدونَ بالابْتِهاجِ. سَيْراً كانوا يَسيرونَ وهُمْ باكونَ حامِلينَ بِذارَهُم، ويَعودون بالفَرَحِ حامِلينَ أغْمارَهُم. هَلِّلُويا.',
    },
    {
      'title': 'مز126: ان لم يبن الرب البيت',
      'body':
          'إنْ لَمْ يَبْنِ الرَّبُّ البَيْتَ، فَباطِلاً يَتْعبُ البَنّاؤُونَ. وإنْ لَمْ يَحْرُس الرَّبُّ المَدينَةَ، فَباطِلاً يَسْهرُ الحُرّاسُ. باطِلٌ هُوَ لَكُم التَّبْكيرُ في القِيامِ والتَّأَخُّر عَن الرقادِ يا آكِلي الخُبْزَ بالهُمومِ. فَإنَّهُ يَمْنَح أحِبّاءَهُ نَوْماً. البَنونَ ميراثٌ مِنَ الرَّبِّ، وثَمَرَةُ البَْنِ عَطِيَّةٌ مِنْهُ. كالسِّهامِ بِيَدِ القَوِيِّ، كَذلِكَ أبْناء الشَّبيبَةِ. مَغْبوطٌ هُوَ الرَّجُلُ الَّذي يَمْلأُ جُعْبَتَه مِنْهُم، حينَئِذٍ لا يُخْزَوْنَ إذا كَلَّموا أعْداءَهُم في الأبْوابِ. هَلِّلُويا.',
    },
    {
      'title': '127: طوبي لجميع الذين يتقون الرب',
      'body':
          'طوبَى لِجَميعِ الَّذينَ يتَّقونَ الرَّبَّ، السّالِكينَ فى طُرُقِه. لأنَّكَ تَأْكُلُ مِنْ ثَمَرةِ أتْعابِكَ، تَصيرُ مَغْبوطاً ويَكونُ لَكَ الخَيْر. إمْرأَتُكَ تَصير مِثْلَ كَرْمةٍ مُخْصِبَةٍ فى جَوانِبِ بَيْتِكَ، بَنوكَ مِثْلُ غُروسِ الزَّيْتونِ الجُددِ حَوْلَ مائِدَتكَ. هَكَذا يُبارِِكُ الإنْسانُ المتَّقى الرَّبَّ. يُباركُكَ الرَّبُّ مِنْ صِهْيونَ، وتُبْصِرُ خَيْراتِ أورُشَليمَ جَميعَ أيّامِ حَياتِكَ. وتَرَى بَنى بَنيكَ، والسَّلامُ عَلَى إسْرائيلَ. هَلِّلُويا.',
    },
    {
      'title': 'مرارا كثيرة حاربوني',
      'body':
          'مِرارًا كَثيرةً حارَبونى مُنْذُ صِباى لِيَقُلْ إسْرائيلُ. مِرارًا كَثيرةً قاتَلونى مُنْذُ شَبابى، وإنَّهُم لَمْ يَقْدِروا عَلَىَّ. عَلَى ظَهْرى جَلَدنى الخُطاةُ وأَطالوا إثْمَهُمْ. الرَّبّ صِدّيقٌ هُوَ، يَقْطعُ أعْناقَ الخُطاةِ، فَلْيَخْزَ وَلْيَرْتَدَّ إلَى الوَراءِ، كُلُّ الَّذينَ يُبْغِضونَ صِهْيونَ، وليَكونوا مِثْلَ عُشْبِ السُّطوحِ، الَّذى يَيْبَسُ قَبْل أنْ يُقْطَع. الَّذى لَمْ يَمْلأ الحاصِدُ مِنْهُ يَدَهُ، ولا الَّذى يَجْمَعُ الغُمورُ حُضْنَهُ. ولَمْ يَقُل المجْتازونَ إنَّ بَرَكَة الرَّبِّ عَلَيْكُم، وبارَكْناكُم بإسْمِ الرَّبِّ. هَلِّلُويا.',
    },
    {
      'title': 'الانجيل(لوقا4:38-41)',
      'body':
          'ثُمَّ قامَ مِنَ المجْمَعِ ودَخَلَ بَيْتَ سِمْعانَ. وكانَتْ حَماةُ سِمْعانَ بِحُمَّى شَديدةٍ، فَسَألوهُ مِنْ أجْلِها، فَوَقَفَ فَوْقَاً مِنْها وزَجَرَ الحُمَّى فَتَرَكتْها وفى الحالِ قامَتْ وخَدَمَتْهُم. وعِنْدَ غُروبِ الشَّمْسِ كانَ الَّذينَ عِنْدَهُمْ مَرْضَى بأنْواعِ أمْراضٍ كَثيرةٍ يُقَدِّمونَهُم إليْهِ، أمّا هُوَ فَكانَ يَضَعُ يَدَيهِ عَلَى كُلِِّ واحِدٍ فَيشْفيهم، وكانت الشَّياطينُ تَخْرجُ مِنْ كَثيرينَ وهِىَ تَصْرخُ وتَقولُ: أنْتَ هُوَ المسيحُ إبْنُ اللَّهِ. فَكانَ يَنْتَهِرهُم ولا يَدَعهُم يَنْطِقون، لأنَّهُمْ كانوا قَدْ عَرفوهُ أنَّهُ هُوَ المَسيحُ. والمجْدُ للَّهِ دائِماً.',
    },
    {
      'title': 'القطعة الاولي',
      'body':
          'إذا كانَ الصِّدّيقُ بالجَهْدِ يُخلَّصُ فَأيْنَ أظْهَر أَنا الْخاطئ؟ ثِقَل النَّهار وحَرّه لَمْ أحْتَمِلْ لِضَعْفِ بَشَرِيَّتى. لَكِنْ أنْتَ يا اللَّهُ الرَّحومُ إحْسِبْنى مَعَ أصْحابِ السّاعَةِ الحادِيَةَ عَشَرَة. لأنّى هَأنَذا بالآثامِ حُبِلَ بى، وفى الخَطايا وَلَدتْنى أُمّى. فَما أَجْسَرَ أنْ أنْظرَ إلَى عُلُوِّ السَّماءِ، لَكنّى أتَّكِلُ عَلَى غِنَى رَحْمتِكَ ومَحبَّتِكَ لِلْبَشَرِيَّة، صارِخاً قائِلاً: اللَّهُمَّ اغْفِرْ لى أَنا الخاطِئ وارْحَمنى. ( ذُو كصابترى )',
    },
    {
      'title': 'القطعة الثانية',
      'body':
          'أسْرِعْ لى يا مُخَلِّصَ بِفَتْحِ الأحْضانِ الأَبَوِيَّةِِ، لأنّى أفْنَيْتُ عُمْرى فى اللَّذاتِ والشهَواتِ وقَدْ مَضَى مِنّى النَّهارُ وفاتَ. فالآنَ أتَّكلُ عَلَى غِنَى رَأْفتِكَ الَّتى لا تَفرغُ. فلا تَتَخلَّ عَنْ قَلْبٍ خاشِعٍ مُفْتَقِرٍ لرَحْمتِكَ. لأنّى إليْكَ أصْرُخُ يا رَبُّ بتَخَشُّعٍ: أخْطَأْتُ يا أبَتاهُ فى السَّماءِ وقُدّامِكَ، ولَسْتُ مُسْتحقاً أنْ أُدْعَى لَكَ إبْناً بَل إجْعَلَنى كَأحَدِ أُجَرائِك. ( كى نين )',
    },
    {
      'title': 'القطعة الثالثة',
      'body':
          'لِكُلِّ إثْمٍ بِحرْصٍ ونَشاطٍ فَعلْتُ، ولِكُلِّ خَطِيَّةٍ بشَوْقٍ وإجْتِهادٍ إرْتكَبْتُ، ولِكُلِّ عَذابٍ وحُكْمٍ إسْتَوْجَبْتُ. فَهَيّئ لى أسْبابَ التَّوبَةِ أيَّتُها السَّيدَةُ العَذْراءُ. فَإلَيْكِ أتَضرَّعُ، وبِكِ أسْتَشفعُ وإيّاكِ أدْعو أنْ تُساعِدينى لئلاّ أخْزَى. وعِنْدَ مُفارقَةِ نَفْسى مِنْ جَسَدى احْضَرى عِنْدى، ولمؤامَرةِ الأعْداءِ إهْزمى، ولأبْوابِ الجَحيمِ إغْلقى، لئلاّ يَبْتَلعوا نَفْسى يا عَروس بلا عَيبٍ للخَتْنِ الحَقيقىِّ.',
    },
    {
      'title': 'كيريى لَيْسُون',
      'body': 'يُقال ( كيريى لَيْسُون ) يَارَبُّ ارْحَمْ 41 مرة.',
    },
    {
      'title': 'قدوس قدوس قدوس',
      'body':
          'قُدّوسٌ قُدّوسٌ قُدّوسٌ رَبُّ الصَّباؤوتِ. السَّماءُ والأرْضُ مَمْلوءتانِ مِنْ مَجْدكَ وكَرامَتكَ. إرْحَمْنا يا اللَّهُ الآبُ ضابِطُ الكُلِّ، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا. أيُّها الرَّبُّ إلهُ القُوّاتِ كُنْ مَعَنا، لأنَّهُ لَيسَ لَنا مُعينٌ فى شَدائِدنا وضيقاتِنا سِواكَ. حلّ واغْفِرْ واصْفَحْ لَنا يا اللَّهُ عَنْ سَيِّئاتِنا الَّتى صَنَعْناها بإرادَتِنا والَّتى صَنَعْناها بغَيرِ إرادَتنا، الَّتى فَعلْناها بمَعرِفةٍ والَّتى فَعلْناها بغَير مَعْرِفةٍ، الخَفيَّةِ والظاهِرةِ، يا رَبُّ اغْفِرها لَنا مِنْ أجْلِ إسْمِكَ القُدّوسِ الَّذى دُعى عَليْنا. كَرحْمتِكَ يا رَبُّ ولا كَخَطايانا.',
    },
    {
      'title': 'الصلاة الرانية',
      'body':
          'اللَّهُم اجْعلنا مُستحِقين أنْ نقولَ بِشكرٍ: أبانا الذي في السَّمَواتِ، لِيتَقدس اسْمكَ. ليأتِ مَلكوتُكَ. لتَكن مَشيئَتُكَ، كما في السّماءِ كَذلك على الأرْضِ. خُبزَنا الذي للغدِ اعطِنا اليومَ. واغفِر لنا ذنوبَنا كما نغْفر نحنُ أيضّا للمذنبينَ إلينا. ولا تُدخِلنا في تَجرِبةٍ. لكن نجّنا مِنْ الشّريرِ. بالمسيحِ يسوعُ ربُّنا، لأنَّ لَكَ المُلكَ والقوةَ والمجدَ إلى الأبدِ. آمين.',
    },
    {
      'title': 'التحليل',
      'body':
          'نَشْكُركَ يا مَلِكنا المتَحنِّنْ، لأنَّكَ مَنَحتَنا أنْ نَعبُر هَذا اليَوْمِ بِسَلامَةٍ وأتَيْتَ بِنا إلَى المَساءِ شاكِرينَ، وجَعلْتَنا مُسْتحِقّينَ أنْ نَنْظُر النّورَ إلَى الَمَساءِ. اللَّهُمَّ اقْبَلْ تَمْجيدَنا هَذا الَّذى صارَ الآنَ، ونَجِّنا مِن حِيَلِ المُضادِّ، وابْطِلْ سائِرَ فِِخاخِهِ المنْصوبَةِ لَنا. هَبْ لَنا فى هَذِه اللَّيْلَةِ المقْبِلَةِ سَلامَةً بِغَيْرِ ألَمٍ ولا قَلَقٍ ولا تَعَبٍ ولا خَيالٍ، لِنَجْتازَها أيْضاً بسَلامٍ وعَفافٍ، ونَنْهَضُ للتَّسابيحِ والصَّلَواتِ كُلَّ حيٍن وفى كُلِّ مَكانٍ نُمجِّد إسْمَكَ القُدّوسَ فى كُلِّ شَئٍ مَعَ الآبِ غَيْرِ المدْرَكِ ولا المبْتَدئ. والرّوحِ القُدُسِ المحْيي المُساوى لَكَ الآنَ وكُلّ أوانٍ وإلَى دَهرِ الدُّهور آمين.',
    },
    {
      'title': 'طلبات تقال اخر كل ساعة',
      'body':
          'إرْحَمْنا يا اللَّهُ ثمَّ إرْحَمْنا، يا مَنْ فى كلِّ وقْتٍ وكلِّ ساعَةٍ، فى السَّماءِ وعلَى الأرْض مَسْجودٌ لَهُ ومُمجَّدٌ، المسيحُ إلَهنا الصّالحُ الطَّويلُ الرّوحِ الكثيرُ الرَّحْمةِ الجَزيلُ التَّحنُّنِ، الَّذى يُحبُّ الصِّدّيقيَن ويَرْحمُ الخُطاةَ الَّذينَ أوَّلهُم أَنا، الَّذى لا يَشاءُ مَوْت الخاطِئ مِثل ما يَرجعُ ويَحْيا، الدّاعى الكُلَّ إلَى الخَلاصِ لأجْلِ الموْعدِ بالخَيْراتِ المنْتَظرةِ. يا رَبُّ اقْبَل مِنّا فى هَذهِ السّاعةِ وكُلِّ ساعَةٍ طلباتِنا. سَهِّلْ حَياتَنا، وأرشِدْنا إلَى العَمَل بوَصاياكَ. قَدِّسْ أرْواحَنا. طهِّرْ أجْسامَنا. قَوِّمْ أفْكارَنا. نَقِّ نِيّاتَنا واشْفِ أمْراضَنا واغْفِرْ خَطايانا. ونَجِّنا مِنْ كلِّ حُزنٍ رَدئٍ ووَجَِعِ قَلْبٍ، أحِطْنا بمَلائِكتِكَ القدّيسينَ لكىْ نَكونَ بمُعَسْكَرهِم مَحْفوظينَ ومُرْشَدينَ، لنَصِلَ إلَى إتِّحاد الإيمانِ وإلَى مَعْرفةِ مَجْدكَ غَيرِ المحْسوسِ وغَيْر المحْدود، فإنَّكَ مُبارَكٌ إلَى الأبَدِ. آمين.',
    },
  ];

  final List<Map<String, String>> nomPrayers = [
    {
      'title': 'صلاة الشكر',
      'body':
          'فَلْنشْكُرّ صَانِعَ الخَيراتِ الرَّحُومَ الله أبَا رَبِّنَا وإلهِنَا ومُخَلِصَنا يَسُوعِ المسِيحِ. لأنَّهُ سَتَرنَا، وأعَانَنَا، وحَفِظَنا، وقَبِلَنا إليهِ، وأشْفَقَ عَلينَا، وعَضَّدنَا، وأَتَى بنا إلى هَذِهِ السَّاعَة. هُو أيْضاً فَلْنَسْأَلَهُ أنْ يَحْفَظَنا فى هَذَا اليَومِ المقَدَّسِ وكُلِّ أيَّامِ حَيَاتنَا بكلِّ سَلامِ. الضَّابِطُ الكُلّ الرَّبُ إلَهنَا. أيُّهَا السَّيِدُ الرَّبُّ الإلَه ضَابطُ الكُلِّ أبُو ربِّنَا وإلهنَا ومُخَلصَّنَا يَسُوعِ المسِيح نَشْكرُكَ عَلَى كُلِّ حالٍ، ومِنْ أجْل كلِّ حَالٍ، وفى كُلِّ حالٍ، لأنَّكَ سَترْتَنا، وأعَنْتَنا، وحفِظْتنَا، وقَبلْتنَا إليْكَ، وأشْفَقْت عَلينا، وعَضَّدْتَنَا، وأتَيتَ بِنَا إلىَ هَذِه السَّاعةِ. من أجْلِ هَذَا نَسْألُ ونَطْلبُ مِنْ صَلاحِكَ يَامُحبَّ البَشَر، امْنَحنَا أنْ نُكْملَ هذا اليَوْمَ المقَدَّسَ وكلّ أيَّامِ حَياتِنَا بِكلِّ سَلامٍ مَعَ خَوفِكَ، كُلُّ حَسَدٍ، وكلُّ تَجربَةٍ. وكلُّ فِعْلِ الشَّيْطانِ، ومُؤامَرةِ النَّاسِ الأشْرارِ، وقِيام الأعْدَاءِ الخَفيِّينَ والظَّاهِرينَ، إنْزَعهَا عنَّا وعَنْ سَائِرِ شَعْبكَ وعَنْ مَوضِعِكَ المقَدَّسِ هَذا. أمَّاَ الصَّالِحاتُ والنَّافعاتُ فَارزُقْنا إيَّاهَا. لأنَّكَ أنْتَ الذِى أعْطَيتَنا السُّلْطانَ أنْ ندوسَ الحَيَّاتِ والعَقارِبَ وكُلَّ قوَّةِ العَدوِّ. ولا تُدْخِلنَا فى تَجربَةٍ، لَكنْ نَجِّنا مِنَ الشِّرِّيرِ. بالنِّعْمةِ والرَّأْفَاتِ ومَحبَّة البَشرِ اللَّواتِى لإبْنِك الوَحيدِ ربِّنا وإلهِنَا ومُخلِّصِنا يَسُوعِ المسيحِ. هَذَا الذِى مِنْ قِبَلِه الَمجْدُ والإكْرام والعزَّةُ والسُّجودُ تَلِيقُ بكَ مَعهُ مَعُ الرُّوحِ القُدُسِ الَمحْيى المسَاوِى لَكَ الآنَ وكلَّ أوَانٍ وإلىَ دَهرِ الدُّهُورِ. آمين.',
    },
    {
      'title': 'المزمور الخمسون',
      'body':
          'إرْحَمنِى يَا الله كَعَظيمِ رَحْمتِكَ، ومِثْل كَثْرةِ رَأفتِكَ تَمْحُو إثْمِى. تَغْسلُنِى كَثيراً مِنْ إثْمِى، ومِنْ خَطيَّتِى تُطهَّرنِى. لأنِّى عارفٌ بإثْمِى، وخَطيَّتِى أمَامِى فى كلِّ حينٍ. لَكَ وحْدَك أخْطأْت، والشَّرُّ قدامَكَ صَنعْتُ. لِكىْ تَتَبرَّرَ فى أقْوالِكَ. وتَغْلبَ إذَا حَاكمْت. لأنِّى هَا أنَذَا بالاثْمِ حُبلَ بِى، وبالَخَطايَا وَلَدتْنِى أمِّى. لأنَّكَ هَكَذا قَدْ أحْبَبتُ الحقَّ، إذْ أوْضَحتَ لِى غَوامِضَ حِكْمتِكَ ومَسْتورَاتِها. تَنضَحُ عَلىَّ بِزُوفَاكَ فأطَّهَّرُ، تَغْسلُنِى فَأبْيضُّ أكْثَر مِنَ الثَّلجِ، تَسْمعُنِى سُرُوراً وفَرحاً، فتَبْتهجُ عِظامِى المنْسَحقةُ. أصْرِفْ وجْهَكَ عَنْ خَطايَاىَ، وأمْحُ كلَّ اثَامِى. قَلبِاً نَقياً أخْلقْ فىَّ يَا الله، ورُوحاً مُسْتَقيماً جدِّدهُ فى أحْشَائِى. لا تَطْرحْنِى مِنْ قُدَّامَ وجْهكَ، ورُوحكَ القُدُّوسِ لا تَنْزعْهُ مِنِّى. امْنَحْنِى بَهْجةَ خَلاصِكَ، وبرُوحِ مُدبِّرٍ عَضِّدّنِى فأعْلمِ الأثَمَةَ طُرُقكَ، والمنَافِقونَ إليْكَ يَرجعونَ، نَجِّنِى مِنَ الدِّماء يا الله إلَه خَلاصِى، فيَبتَّهجُ لِسانِى ببرَّكَ. يَاربِّ إفْتَح شَفتَىَّ فَيُخبرُ فَمِى بَتَسْبيحِكَ. لأنَّكَ لَوْ أثَرتَ الذَّبيحةَ، لَكُنْتُ الآنَ أعْطِى. ولَكنَّكَ لا تُسرُّ بالَمحْرقَاتِ، فالذَبيحَةُ للهِ رُوحَّ مُنْسحقَّ. القَلْبُ المنْكسِرُ والمتَواضِعُ لايُرْزلهُ الله، أنْعمْ يَا ربّ بِمَسرتكَ عَلى صِهْيُون، ولْتَبنِ أسْوَارَ أورْشَلِيم. حِينَئذٍ تُسرُّ بذَبائِح البَرِّ قرباناً ومُحْرقَات ويُقَّربون عَلى مَذابِحكَ العُجُول. هَلِّلُويا.',
    },
    {
      'title': 'بدء الصلاة',
      'body':
          'تَسْبحَةُ النَّوْم المُبارَك أقدِّمها للْمَسيحِ مَلِكى وإلَهى وأرْجوهُ أنْ يَغْفرَ لِى خَطاياىَ.',
    },
    {
      'title': 'مز129: من الاعماق صرخت اليك يا رب',
      'body':
          'مِن الأعْماقِ صَرختُ إلَيكَ يا رَبُّ. يا رَبُّ إسْمعْ صَوتى، لتكنْ إذُناكَ مُصْغيَتْينِ إلى صوت تَضرُّعى. إن كنتَ لللآثامِ راصداً يا رَبُّ، يا رَبُّ مَن يَثبُتُ لأنّ مِن عِندِكَ المَغفرَةَ. مِن أجل إسْمكَ صَبرتُ لكَ يا رَبُّ، تَمسّكتْ نَفسى بناموسِكَ. إنْتظَرَتْ نَفسى الرّبَّ مِن مَحرسَ الصُبّحِ، فَلْينظِرْ إسرائيلُ الرّبَّ. لأنّ الرّحمةَ مِن عِندِ الرّبّ، وعظيمٌ هو خلاصُهُ، وهو يَفتَدى إسْرائيلَ مِن كُلِّ آثامِهِ. هَلِّلُويا.',
    },
    {
      'title': 'مز130: يارب لم يرتفع قلبي',
      'body':
          'يا رَبُّ لَمْ يَرْتَفِعْ قَلْبى ولَمْ تَسْتَعلِ عَيْناي، ولَمْ أسْلُكْ فى العَظائِمِ ولا فى العَجائِبِ. الَّتى هِىَ أَعْلَى مِنّى. أمّا إنْ كُنْت لَمْ أتَّضِعْ، لَكِنْ رَفعْتُ صَوْتى مِثْلُ الفَطيمِ مِنَ اللَّبَنِ عَلَى أمِّهِ، كَذَلكَ تَكونُ عَلَىَّ نَفْسى. فَلْيتَّكِلْ إسْرائيلُ عَلَى الرَّبِّ، مِنَ الآنَ وإلَى الأبَدِ. هَلِّلُويا.',
    },
    {
      'title': 'مز131: اذكر يارب داود وكل مذلته',
      'body':
          'اذْكُر يا رَبُّ داوُدَ وكُلّ مَذَلَّتِهِ. كَيْفَ أقْسَمَ للرَّبِّ، ونَذَرَ لإلَهِ يَعْقوبَ: إنّى لا أدْخُل إلَى مَسْكنِ بَيْتى، ولا أصْعَدُ عَلَى سَريرِ فِراشى. ولا أُعْطى نَوْماً لِعَيْنى، ولا نُعاساً لأجْفانى، ولا راحَةً لصدْغى. إلَى أنْ أجِدَ مَوْضِعاً لِلرَّبِّ، ومَسْكَناً لإلَهِ يَعْقوبَ. ها قَدْ سَمِعْنا بِهِ فى أفْراته، ووَجَدْناهُ فى مَوْضِعِ الغابةِ. لِنَدْخُل إلَى مَساكِنِهِ، ونَسْجدَ فى المَوْضِعِ الَّذى فيهِ إسْتَقَرَّتْ قَدماهُ. قُمْ يا رَبُّ إلَى راحَتكَ، أنْتَ وتابوتُ قُدْسِكَ. كَهَنتُكَ يَلْبَسونَ البِرَّ، وأبْرارُكَ يَبْتهِجونَ. مِنْ أجْلِ داوُدَ عَبدِكَ، لا تَردَّ وَجْهكَ عَنْ مَسيحِكَ. حَلفَ الرَّبُّ لِداوُدَ حَقًّا ولا يُخْلِف، لأجْعَلَنَّ مِنْ ثَمَرَةِ بَطْنِكَ عَلَى كُرْسيكَ. إنْ حَفِظَ بَنوكَ عَهْدى وشَهاداتى الَّتى أُعْلِمهُمْ إيّاها. فَبَنوهُم أيْضاً يَجْلِسونَ إلَى الأبَدِ عَلَى كُرسيكَ. لأنَّ الرَّبَّ اخْتار صِهْيونَ، وَرَضيها مَسْكَناً لَهُ: هَذا هُوَ مَوْضِعُ راحَتى إلَى أَبَدِ الأبَدِ، هَهُنا أسْكُنُ لأنّى أرَدْتُه. لِطَعامِها أُبارِكُ تَبْريكاً، لمَساكينِها أُشْبِعُ خُبْزاً. لكَهَنَتِها أُلْبِسُ الخَلاصَ، وأبْرارُها يَبْتَهِجونَ ابْتِهاجاً. هُناكَ أُقيمُ قَرناً لداوُدَ، هَيأتَ سِراجاً لِمَسيحى. لأعْدائِهِ أُلْبِسُ الخِزْىَ، وعَليْهِ تَزْدهِرُ قَداسَتى. هَلِّلُويا.',
    },
    {
      'title': 'مز132: هوذا ما احسن وما احلى',
      'body':
          'هُوَذا ما أحْسَنَ وما أحْلَى أنْ يَسْكُن الأخْوَةُ مَعاً. كالطّيبِ الكائِنِ عَلَى الرَّأْسِ الَّذى يَنْزلُ عَلَى اللِّحْيةِ، لِحْيَة هَرونَ النّازِلةِ عَلَى جَيْبِ قَميصِه. ومِثْلُ نَدَى حَرْمونَ المنْحَدِر عَلَى جَبَل صِهْيونَ، لأنَّ هُناكَ أمَرَ الرَّبُّ بالبَرَكَةِ والْحَياةِ إلَى الأبَدِ. هَلِّلُويا.',
    },
    {
      'title': 'مز133: ها باركوا الرب',
      'body':
          'ها بارِكوا الرَّبَّ يا عَبيدَ الرَّبِّ القائِمينَ فى بَيْتِ الرَّبِّ في دِيارِ إلَهِنا. فى اللَّيالى ارْفَعوا أيْديَكُم إلَى القُدسِ، وبارِكوا الرَّبَّ. يُبارِككُم الرَّبُّ مِنْ صِهْيونَ، الَّذى خَلَقَ السَّمَوات والأرْضَ. هَلِّلُويا.',
    },
    {
      'title': 'مز136: علي انهار بابل',
      'body':
          'عَلَى أنْهارِ بابِلَ هُناكَ جَلَسْنا، بَكَيْنا عِنْدَما تَذَكّرْنا صِهْيونَ. عَلَى الصِّفْصافِ فى وَسَطِها عَلَّقنا قيثاراتنا، لأنَّهُ هُناكَ سَألَنا الَّذينَ سَبَوْنا أقْوالَ التَّسْبيح. والَّذينَ اسْتاقونا إلَى هُناك قالوا: سَبِّحوا لَنا تَسْبِحَةً مِنْ تَسابيحِ صِهْيونَ. كَيفَ نُسَبِّحُ تَسْبِحَةَ الرَّبِّ فى أرْضٍ غَريبَةٍ؟ إنْ نَسيتكِ يا أورُشَليمَ تنْسَي يَمينى، ويَلْتَصِقُ لِسانى بِحَنَكى إنْ لَمْ أذْكُرك، إنْ لَمْ أُفضِّلْ أورُشَليمَ عَلَى أَعْظَم فَرَحى. اذْكُرْ يا رَبُّ بَني أَدومَ فى يَومَ أورُشَليمَ القائِلينَ: انْقُضوا انْقُضوا حَتَى الأساسَ مِنْها. يا بِنْتَ بابِلَ الشَّقِيَّة، طوبَى لِمَنْ يُكافِئك مُكافأتكِ الَّتى جازَيتِنا. طوبَى لِمَنْ يُمْسِكُ أطْفالَكِ، ويَضْرِبُ بِهِمُ الصَّخْرةَ. هَلِّلُويا.',
    },
    {
      'title': 'مز137: اعترف لك يارب',
      'body':
          'أعْتَرِفُ لَكَ يا رَبُّ مِنْ كُلِّ قَلْبى، لأنَّكَ إسْتَمعْتَ كُلَّ كَلِماتِ فَمى. أَمامَ الملائِكةِ أُرَتِّلُ لَكَ، وأسْجُدُ قُدّامَ هَيْكَلِكَ المقَدَّسِ، وأعْتَرِفُ لإسْمِكَ عَلَى رَحْمَتِكَ وحَقِّكَ، لأنَّكَ قَدْ عَظَّمْتَ إسْمَكَ القُدّوسَ عَلَى الكُلِّ. اليَومَ الَّذى أدْعوكَ فيهِ أجِبْنى بِسُرْعَةٍ، تُزَوِّدُ نَفْسى كَثيراً بِقُوَّةٍ. فَلْيَعْتَرِفْ لَكَ يا رَبُّ كُلُّ مُلوكِ الأرْضِ، لأنَّهُمْ سَمِعوا سائِرَ كَلِماتِ فَمِكَ. وليسبِّحوا فى طُرُقِ الرَّبِّ لأنَّ مَجْدَ الرَّبّ عَظيمٌ. لأنَّ الرَّبَّ عالٍ ويُعايِنُ المتواضِعينَ، أمّا المتَكبِّرونَ فَيَعْرِفهُم مِنْ بَعْد. إنْ سَلكْت فى وَسَطِ الشِّدَّةِ فَإنَّكَ تُحْيينى، عَلَى رِجْزِ الأعْداءِ مَدَدْتَ يَدَكَ وخَلصتنى يَمينك. الرَّبُّ يُجازى عَنّى. يارَبُّ رَحْمَتُكَ دائِمَةٌ إلَى الأبَدِ، أعْمالُ يَدَيْكَ يا رَبُّ لا تَتْرُكها. هَلِّلُويا.',
    },
    {
      'title': 'مز140: يارب اليك صرخت',
      'body':
          'يا رَبُّ إليْكَ صَرخْتُ فاسْتَمِعْ لى، انْصِتْ إلَى صَوْتِ تَضرُّعى إذا ما صَرخْتُ إليْكَ. لِتَسْتَقِمْ صَلاتى كالْبَخور قُدّامِكَ، ولِيَكُن رَفْعُ يَدىَّ كذبيحَةٍ مَسائِيَّةٍ. ضَعْ يا رَبُّ حافِظًا لِفَمى، وباباً حَصيناً لشَفَتىَّ، ولا تُمِلْ قَلْبى إلَى كَلامِ الشَّرِّ، فَيُمارِسُ الْخَطايا مَعَ أُناسٍ فاعِلى الإثْمِ ولا أشْتَركُ فى ولائِمِهِمْ. فَلْيؤدِّبْنى الصِّدّيقُ برَحْمةٍ ويُوَبِّخنى، أمّا زَيْتُ الخاطئ فَلا يَدْهنُ رَأسى. لأنَّ صَلاتى أيْضًا ضِدَّ رَغَباتِهِم الشِّرّيرَةِ. ذُهِلَ أقْوياؤُهُم عِنْدَ الصَّخْرَةِ، يَسْمَعونَ كَلِماتى اللَّيِّنَةَ، مِثْل شَحْمِ الأرْضِ انْشَقوا عَلَى الأرْضِ. تَبَدَّدَت عِظامُهُمْ عِنْدَ الْجَحيمِ، لأنَّ عُيونَنا إليْكَ يا رَبُّ. يا رَبُّ عَليْكَ تَوكَّلْتُ فَلا تَقْتُل نَفْسى. احْفَظنى مِنَ الفخِّ الَّذى نَصَبوهُ لى، ومِنْ شُكوكِ فاعِلى الإثْمِ. يَسْقُطُ الْخُطاةُ فى شِباكِهِمْ وأكونُ أَنا وَحْدى حَتَّى يَجوز الإثْمُ. هَلِّلُويا.',
    },
    {
      'title': 'مز141: بصوتى الي الرب صرخت',
      'body':
          'بصَوْتى إلَى الرَّبِّ صَرَخْتُ، بِصَوْتى إلَى الرَّبِّ تَضَرَّعْتُ أسْكُبُ أمامَه تَوَسُّلى، أبُثُّ لَدَيْهِ ضيقى عِنْدَ فَناءِ روحى مِنّى وأنْتَ عَلمت سُبُلى. فى الطَّريقِ الَّذى أسْلُكُ أخْفَوْا لى فَخّاً. تأمَّلْتُ عَنِ اليَمينِ وأبْصَرتُ، فلَمْ يَكُنْ مَنْ يَعْرفنى. ضاعَ الْمَهْرَبُ مِنّى ولَيْسَ مَنْ يَسْألُ عَنْ َنْفسى فَصَرخْتُ إليْكَ يا رَبُّ وقلْتُ: أنْتَ هُوَ رَجائى وحَظّى فى أرْضِ الأحْياءِ. أنْصِتْ إلَى طلبَتى، فإنّى قَدْ تَذلَّلْتُ جِدّاً. نَجِّنى مِنَ الَّذينَ يَضْطَهِدونى، لأنَّهُمْ قَدْ اعْتَزّوا أكثَرَ مِنّى. أَخْرِجْ مِنَ الْحَبْسِ نَفْسى، لِكَى أشْكُرَ إسْمَكَ يا رَبُّ. إيّاى ينْتَظِرُالصِّدّيقونَ حَتَى تُجازينى. هَلِّلُويا.',
    },
    {
      'title': 'مز145: سبحى يا نفسى الرب',
      'body':
          'سَبِّحى يا نَفْسى الرَّبَّ. أُسَبِّحُ الرَّبَّ فى حَياتى، وأُرَتِّلُ لإلَهى مادُمتُ حَيّاً. لا تَتَّكِلوا عَلَى الرُّؤساءِ ولا عَلَى بَنى البَشَرِ. الَّذينَ لَْسَ عِنْدهُمْ خَلاصٌ. تَخْرجُ روحُهُم فَيَعودونَ إلَى تُرابِهِمْ، فى ذَلِكَ اليَوْمِ تَهْلكُ كافَّة أفْكارِهِم. طوبَى لِمَنْ إلَهُ يَعْقوبَ مُعينُهُ، واتِّكالُهُ عَلَى الرَّبِّ إلَهِهِ. الَّذى صَنَعَ السَّماءَ والأرْضَ والبَحْرَ وكُلَّ ما فيها. الحافِظِ العَدْل إلَى الدَّهْرِ. الصّانِعِ الْحُكْمِ للمَظْلومينَ. المعْطى الطَّعامَ للجِياعِ. الرَّبُّ يَحلُّ المأْسورينَ، الرَّبُّ يُقيمُ السّاقِطينَ. الرَّبُّ يَحْكُم العُمْيانَ، الرَّبُّ يُحِبُّ الصِّدّيقينَ. الرَّبُّ يَحْفَظُ الغُرباءَ ويعضدُ اليَتيمَ والأرْمَلةَ، ويُبيدُ طُرقَ الْخُطاةِ. يَمْلكُ الرَّبُّ إلَى الدَّهْرِ، وإلَهُكِ يا صِهْيونُ مِنْ جيلٍ إلَى جيلٍ. هَلِّلُويا.',
    },
    {
      'title': 'مز146: سبحوا الرب فان المزمور جيد',
      'body':
          'سَبِّحوا الرَّبَّ فإنَّ المزْمورَ جَيِّدٌ، لإلَهِنا يَلذُّ التَّسْبيحُ. الرَّبُّ يَبْنى أورُشَليمَ، الرَّبُّ يَجْمعُ مُتَفرِّقى إسْرائيلَ. الرَّبُّ يَشْفى مُنْكَسِرى القُلوبِ، ويُجبرُ جَميعَ كَسْرهِمْ. الْمُحْصى كَثْرةَ الكَواكِبِ، ولكافَّتِها يُعْطى أسْماء. عَظيمٌ هُوَ الرَّبُّ وعَظيمَةٌ هِىَ قُوَّتُهُ، ولا إحْصاء لِفهْمِهِ. الرَّبُّ يَرْفَعُ الوُدَعاءَ، ويُذِلُّ الْخُطاةَ إلَى الأرْضِ. ابْتَدِئُوا للرَّبِّ بالاعْتِراف، رَتِّلوا لإلَهِنا بالقيثارَةِ. الَّذى يُجَلِّلُ السَّماءَ بالغَمامِ، الَّذى يُهَيّئ للأرْضِ المطَرَ. الَّذى يُنبتُ العُشْبَ عَلَى الْجِبالِ، والْخُضْرةِ لِخِدْمَةِ البَشَرِ، ويُعْطى البَهائِمَ طَعامَها ولِفِراخِ الغِرْبانِ الَّتى تَدْعوهُ لا يُؤْثرُ قُوَّةَ الْخَيْل، ولا يُسَرُّ بِساقى الرَّجُل، بَلْ يُسَرُّ الرَّبُّ بِخائِفيهِ، وبالرّاجينَ رَحْمتَهُ. هَلِّلُويا.',
    },
    {
      'title': 'مز147: سبحى الرب يا اورشليم',
      'body':
          'سَبِّحى الرَّبَّ يا أورُشَليمَ، سَبِّحى إلَهَكِ يا صِهْيونَ. لأنَّهُ قَدْ قَوَّى مَغاليقَ أبْوابِكِ، وبارَكَ بَنيكِ فيكِ. الَّذى جَعََََل تُخومَكِ فى سَلامٍ، ويُشْبِعُكِ مِنْ شَحْم الْحِنْطَةِ. الَّذى يُرْسِلُ كَلِمَتَهُ إلَى الأرْضِ، فَيُسْرعُ قَولُه عاجِلاً جِدّأ. المعْطى الثَّلْجَ كالصّوفِ، المذَرّى الضَّبابَ كالرَّمادِ. ويُلْقى الْجَليدَ مِثْل الفُتاتِ، قُدّامَ وَجْه بردِهِ مَنْ يَقومُ؟ يُرْسِلُ كَلمَتَه فَتُذيبَهُ، تَهبُّ ريحُهُ فَتَسيلُ المياهَ، المخبرُ كَلمتَهُ لِيَعْقوبَ، وفَرائِضَهُ وأَحْكامَهُ لإسْرائيلَ. لَمْ يَصْنَع هَكَذا بكلِّ الأممِ، وأحْكامَهُ لَمْ يُوَضِّحها لَهُمْ. هَلِّلُويا.',
    },
    {
      'title': 'الانجيل(لوقا2:25-32)',
      'body':
          'وإذا إنْسانٌ كانَ بأورُشَليمَ إسْمُهُ سِمْعانُ، وهَذا الإنْسانُ كانَ باراً تَقيّاً مُتَوقِّعاً تَعْزِيةَ إسْرائيلَ والرّوح القُدُس كانَ عَليهِ. وكانَ قَدْ أُعْلِمَ بِوَحْىٍ مِنَ الرّوحِ القُدُسِ أنَّهُ لا يَرَى الموْتَ قَبْل أنْ يُعاينَ المسيحَ الرَّبَّ فأقْبَلَ بالرّوحِ إلَى الهَيْكلِ، ولَمّا دَخَلََ بالطِّفْلِ يَسوعَ أبَواهُ ليَصْنَعا عَنْه كَما يَجبُ فى النّاموسِ، حَمَلهُ سِمْعانُ عَلَى ذِراعَيهِ وبارَكَ اللَّهُ قائِلاً: الآنَ يا سَيِّدى تُطْلِقُ عَبْدكَ بسَلامٍ حَسَبَ قَوْلكَ، لأنَّ عَيْنىَّ قَدْ أبْصَرتا خَلاصَكَ الِّذى أعْدَدتَهُ أمامَ جَميعِ الشُّعوبِ. نوراً تَجلَّى للأممِ، ومَجْدًا لِشَعْبِكَ إسْرائيلَ. والمجْدُ للَّهِ دائماً.',
    },
    {
      'title': 'القطعة الاولي',
      'body':
          'هُوَذا أَنا عَتيدٌ أَنْ أَقِفَ أَمامَ الدَّيّانِ العادِلِ مَرْعوباً ومُرْتَعبًا مِنْ كَثْرةِ ذُنوبى، لأنَّ العُمْرَ المنْقَضى فى الْمَلاهى يَسْتوجِبُ الدَّيْنونَةَ. لَكِنْ توبى يانَفْسى ما دُمْتِ فى الأرْضِ ساكِنةً لأنَّ التُّرابَ فى القَبْرِ لا يُسَبِّحُ ولَيْسَ فى الموْتَى مَنْ يَذْكُر ولا فى الْجَحيمِ مَنْ يَشْكُر. بَلْ انْهَضى مِنْ رُقادِ الكَسَل وتَضَرَّعى إلَى المخَلِّصِ بالتَّوْبَةِ قائِلةً: اللَّهُمَّ ارْحَمْنى وخَلِّصنى. ( ذُوكصابترى )',
    },
    {
      'title': 'القطعة الثانية',
      'body':
          'لَوْ كانَ العُمْرُ ثابتاً وهَذا العالَمُ مُؤَبَّدًا لَكانَ لَكِ يا نَفْسى حُجَّةٌ واضِحَةٌ. لَكِن إذا إنْكَشَفَتْ أفْعالُكِ الرَّديئة وشُروركِ القَبيحَة أَمامَ الدَّيّانِ العادِلِ، فَأَىُّ جَوابٍ تُجيبى وأنْتِ عَلَى سَريرِ الْخَطايا مُنْطَرحةً وفى إخْضاعِ الجَسَدِ مُتَهاونَةً؟ أيُّها المسيحُ إلَهُنا، لِكُرسى حُكْمِكَ المرْهوبِ أفْزَعُ. ولِمَجْلِسِ دَيْنونتِك أخْشَعُ. ولِنورِ شُعاعِ لاهوتكَ أجْزعُ. أَنا الشَّقِىُّ المتَدنِّسُ الرّاقِدُ عَلَى فِراشى، المتَهاوِنُ فى حَياتى. لَكنّى أَتَّخِذُ صورَة العشَّارِ قارِعاً صَدْرى قائِلاً: اللَّهُمَّ اغْفِرْ لى فإنّى خاطئ. ( كى نين )',
    },
    {
      'title': 'القطعة الثالثة',
      'body':
          'أيَّتُها العَذْراءُ الطّاهِرةُ أسْبِلى ظلَّكِ السَّريعَ المعونَةِ عَلَى عَبْدكِ، وابْعِدى أمْواجَ الأفْكارِ الرَّديئةِ عَنّى، وانْهضى نَفْسى المريضَةَ للصَّلاةِ والسَّهَرِ، لأنَّها اسْتَغرقَتْ فى سُباتٍ عَميقٍ، فإنَّكِ أُمٌّ قادِرةٌ رَحيمةٌ مُعينةٌ والِدَةُ ينْبوعِ الْحَياةِ مَلِكى وإلَهى يَسوعِ المسيحِ رَجائى.',
    },
    {
      'title': 'تفضل يارب',
      'body':
          'تفضَّلْ يا رَبُّ أنْ تَحْفَظَنا فى هَذِه اللَّيْلةِ بِغَيرِ خَطيَّةٍ. مُبارِكٌ أَنْتَ أيُّها الرَّبُّ إلهُ آبائِنا ومُتَزايدٌ بَرَكةً، وإسْمُكَ القُدّوسُ مَمْلوءٌ مَجْداً إلَى الأبَدِ آمين. فَلْتكنْ رَحمَتُكَ عَليْنا كَمثْلِ إتِّكالِنا عَليْكَ، لأنَّ أعْيُنَ الكُلَّ تَترَجّاكَ، لأنَّكَ أنْتَ الَّذى تُعْطيهم طَعامَهُم فى حينِه. إسْمَعنا يا اللَّهُ مُخلِّصَنا يا رَجاءَ أقْطارِ الأرْضِ كُلِّها. وأنْتَ يا رَبُّ تَحْفظُنا وتُنَجّينا مِنْ هَذا الجيلِ وإلَى الأبَدِ آمين. مُبارَكٌ أنْتَ يا رَبُّ عَلِّمنى عَدْلَك، مُبارَكٌ أنْتَ يا رَبُّ فَهِّمنى حُقوقَكَ. مُبارَكٌ أنْتَ يا رَبُّ أنِرْ لى بِرَّك، يا رَبُّ رَحْمَتُكَ دائِمَةٌ إلَى الأبَدِ. أعْمالُ يَديْكَ يا رَبُّ لا تَرفُضْها، لأنَّكَ صِرْتَ لى مَلجأً مِنْ جيلٍ إلَى جيلٍ. أَنا طَلبْتُ إلَى الرَّبِّ وقُلْتُ إرْحَمْنى وخَلِّصْ نَفْسى، فإنّى أخْطَأتُ إليْكَ. يارَبُّ إلْتَجأتُ إلَيكَ فَخلِّصنى، وعَلِّمنى أنْ أصْنَعَ مَشيئتَك. لأنَّكَ أنْتَ هُوَ إلَهى، وعِنْدكَ ينْبوعُ الْحَياةِ، وبِنورِكَ يا رَبُّ نُعاينُ النّورَ. فلْتَأتِ رَحْمتُكَ للَّذينَ يَعْرفونَكَ، وبِرُّكَ للْمُسْتقيمى القُلوبِ. لَكَ تجبُ البَركَةُ، لَكَ يَحقُّ التَّسْبيحُ. لَكَ يَنْبغى التَّمْجيدُ أيُّها الآبُ والإبْنُ والرّوحُ القُدُسُ الكائِنُ منْذُ البَدْءِ والآنَ وإلَى أبَدِ الأبَدِ. آمين. جَيِّدٌ هُوَ الإعْتِرافُ للرَّبِّ، والتَّرْتيلُ لإسْمِك أيُّها العَلىُّ. أنْ يُخبر برَحْمتِكَ فى الغَدَواتِ وحَقِّك فى كُلِّ لَيلةٍ.',
    },
    {
      'title': 'الثلاث تقديسات',
      'body':
          'قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الَّذى وُلِدَ مِنَ العَذْراءِ إرْحَمْنا. قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الَّذى صُلِبَ عنّا إرْحَمْنا. قُدّوسٌ اللَّهُ. قُدّوسٌ القَوىُّ. قُدّوسٌ الحَىُّ الَّذى لا يَموتُ الّذى قامَ مِنَ الأمْواتِ وصَعِدَ إلَى السَّمواتِ إرْحَمْنا. المجْدُ للآبِ والإبنِ والرّوحِ القُدُسِ، الآنَ وكلُّ أَوان وإلَى دَهْرِ الدّهورِ آمين. أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا، يا رَبُّ إغْفِرْ لَنا خَطايانا. يا رَبُّ إغْفِرْ لَنا آثامَنا، يا رَبُّ إغْفِرْ لَنا زَلاّتَنا. يا رَبُّ إفْتَقدْ مَرْضَى شَعْبكَ، إشْفِهمْ مِنْ أجْل إسْمكَ القُدّوسِ. آباؤُنا وإخْوَتنا الَّذينَ رَقدوا يا رَبُّ نَيِّحْ نُفوسَهُم، يا مَنْ هُوَ بِلا خَطيَّة يا رَبُّ إرْحَمْنا، يا الَّذى بِلا خَطيَّةِ يا رَبُّ أَعِنّا، واقْبَلْ طَلباتِنا إلَيْكَ. لأنَّ لَكَ المجْدَ والعِزَّةَ والتَّقْديسَ المثلَّثَ. يا رَبُّ إرْحَمْ، يا رَبُّ إرْحَمْ، يا رَبُّ بارِكْ. آمين.',
    },
    {
      'title': 'الصلاة الربانية',
      'body':
          'اللَّهُم اجْعلنا مُستحِقين أنْ نقولَ بِشكرٍ: أبانا الذي في السَّمَواتِ، لِيتَقدس اسْمكَ. ليأتِ مَلكوتُكَ. لتَكن مَشيئَتُكَ، كما في السّماءِ كَذلك على الأرْضِ. خُبزَنا الذي للغدِ اعطِنا اليومَ. واغفِر لنا ذنوبَنا كما نغْفر نحنُ أيضّا للمذنبينَ إلينا. ولا تُدخِلنا في تَجرِبةٍ. لكن نجّنا مِنْ الشّريرِ. بالمسيحِ يسوعُ ربُّنا، لأنَّ لَكَ المُلكَ والقوةَ والمجدَ إلى الأبدِ. آمين.',
    },
    {
      'title': 'السلام لك',
      'body':
          'السلام لك. نسألك أيتها القديسة الممتلئة مجدا العذراء كل حين، والدة الإله أم المسيح، أصعدي صلواتنا إلى ابنك الحبيب ليغفر لنا خطايانا. السلام للتي ولدت لنا النور الحقيقي المسيح إلهنا، العذراء القديسة، اسألي الرب عنا، ليصنع رحمة مع نفوسنا، ويغفر لنا خطايانا. أيتها العذراء مريم والدة الإله، القديسة الشفيعة الأمينة لجنس البشرية، اشفعي فينا أمام المسيح الذي ولدته لكي ينعم علينا بغفران خطايانا. السلام لك أيتها العذراء الملكة الحقيقية، السلام لفخر جنسنا، ولدت لنا عمانوئيل. نسألك: اذكرينا، أيتها الشفيعة المؤتمنة، أمام ربنا يسوع المسيح، ليغفر لنا خطايانا.',
    },
    {
      'title': 'بدء قانون الايمان',
      'body':
          'نُعظِّمُكِ يا أمَّ النّورِ الحَقيقىِّ ونُمجِّدكِ أيَّتُها العَذْراءُ القِدّيسةُ والِدةُ الإلهِ لأنَّكِ وَلدْتِ لَنا مُخلِّصَ العالَم، أتَى وخَلَّصَ نُفوسَنا. المجْدُ لكَ يا سَيِّدُنا ومَلكُنا المسيحُ، فَخْرَ الرُّسُل، إكْليلَ الشُهداءِ، تَهْليلَ الصِدّيقينَ، ثَباتَ الكَنائسِ، غُفْرانَ الخَطايا. نُبشِّرُ بالثَّالوثِ القُدّوسِ، لاهوتٌ واحِدٌ نَسجُدُ لهُ ونُمجِّدهُ يا رَبُّ إرْحَم. يا رَبُّ إرْحَم. يا رَبُّ بارِك. آمين.',
    },
    {
      'title': 'قانون الايمان',
      'body':
          'بالحَقيقَةِ نُؤمِنُ بإلهٍ واحدٍ اللَُّهُ الآبُ ضابطُ الكُلِّ خالِقُ السَّماءِ والأرضِ، ما يُرَى وما لا يُرَى. نُؤمِنُ بربٍّ واحدٍ يَسوعِ المسيحِ إبْن اللهِ الوَحيدِ الموْلودِ مِنَ الآبِ قَبْلَ كلِّ الدُّهورِ. نورٌ مِنْ نورٍ إلهٌ حَقٌ مِنْ إلهٍ حَقٍّ، مَولودٌ غَيْرُ مَخْلوقٍ، مُساوٍ للآبِ فى الجَوْهرِ. الَّذى بِهِ كانَ كلُّ شئٍ. هَذا الَّذى مِنْ أجْلنا نَحنُ البَشَرَ ومِنْ أجْلِ خَلاصِنا نَزلَ مِنَ السَّماءِ وتَجسَّدَ مِنَ الرّوحِ القُّدُسِ، ومِنْ مَرْيَم العَذْراءِ تَأنَّسَ. وصُلبَ عنّا علَى عَهدِ بيلاطُس البنْطى، تألَّمَ وقُبرَ وقامَ مِن بَين الأمْواتِ فى اليَومِ الثّالثِ كَما في الكتُبِ، وصَعِدَ إلَى السَّمواتِ وجَلسَ عَنْ يَمينِ أبيهِ وأيْضاً يَأتي فى مَجدهِ ليُدينَ الأحْياءَ والأمْوات َ، الَّذى لَيسَ لملْكِهِ إنْقِضاءٌ. نَعَم نُؤمِنُ بالرّوحِ القُدُسِ، الرَّبُّ المحْيى المنْبَثقِ مِنَ الآبِ نَسْجُد لهُ ونُمجِّدهُ مَعَ الآبِ والإبْنِ النّاطِقِ فى الأنْبياءِ. وبكنيسَةٍ واحِدَةٍ مُقدَّسةٍ جامعَةٍ رسوليَّةٍ، ونَعْترِفُ بمَعْموديَّةٍ واحِدَةٍ لمغْفِرَةِ الخَطايا. وننْتَظرُ قِيامَةَ الأمْواتِ وحَياةَ الدَّهرِ الآتى آمين.',
    },
    {
      'title': 'كيريى لَيْسُون',
      'body': 'يُقال ( كيريى لَيْسُون ) يَارَبُّ ارْحَمْ 41 مرة.',
    },
    {
      'title': 'قدوس قدوس قدوس',
      'body':
          'قُدّوسٌ قُدّوسٌ قُدّوسٌ رَبُّ الصَّباؤوتِ. السَّماءُ والأرْضُ مَمْلوءتانِ مِنْ مَجْدكَ وكَرامَتكَ. إرْحَمْنا يا اللَّهُ الآبُ ضابِطُ الكُلِّ، أيُّها الثّالوثُ القُدّوسُ إرْحَمْنا. أيُّها الرَّبُّ إلهُ القُوّاتِ كُنْ مَعَنا، لأنَّهُ لَيسَ لَنا مُعينٌ فى شَدائِدنا وضيقاتِنا سِواكَ. حلّ واغْفِرْ واصْفَحْ لَنا يا اللَّهُ عَنْ سَيِّئاتِنا الَّتى صَنَعْناها بإرادَتِنا والَّتى صَنَعْناها بغَيرِ إرادَتنا، الَّتى فَعلْناها بمَعرِفةٍ والَّتى فَعلْناها بغَير مَعْرِفةٍ، الخَفيَّةِ والظاهِرةِ، يا رَبُّ اغْفِرها لَنا مِنْ أجْلِ إسْمِكَ القُدّوسِ الَّذى دُعى عَليْنا. كَرحْمتِكَ يا رَبُّ ولا كَخَطايانا.',
    },
    {
      'title': 'الصلاة الربانية',
      'body':
          'اللَّهُم اجْعلنا مُستحِقين أنْ نقولَ بِشكرٍ: أبانا الذي في السَّمَواتِ، لِيتَقدس اسْمكَ. ليأتِ مَلكوتُكَ. لتَكن مَشيئَتُكَ، كما في السّماءِ كَذلك على الأرْضِ. خُبزَنا الذي للغدِ اعطِنا اليومَ. واغفِر لنا ذنوبَنا كما نغْفر نحنُ أيضّا للمذنبينَ إلينا. ولا تُدخِلنا في تَجرِبةٍ. لكن نجّنا مِنْ الشّريرِ. بالمسيحِ يسوعُ ربُّنا، لأنَّ لَكَ المُلكَ والقوةَ والمجدَ إلى الأبدِ. آمين.',
    },
    {
      'title': 'التحليل',
      'body':
          'يا رَبُّ جَميعُ ما أخْطأْنا بِهِ إليْكَ فى هَذا اليَومِ، إنْ كانَ بالفِعْلِ أوْ بالقَولِ أوْ بالفِكْر أو بِجَميعِ الْحَواسِّ، فاصْفَحْ واغفْر لَنا مِنْ أجْلِ إسْمِِِكَ القُدّوسِ كَصالحٍ ومُحبٍّ للبَشَرِ. وأنْعمْ عَلَيْنا اللَّهُمَّ بلَيلةٍ سالمةٍ، وبِهَذا النَّوْم طاهِراً مِنْ كُلِّ قَلقٍ وأرْسِلْ لَنا مَلاكَ السَّلامَةِ ليَحرُسَنا مِنْ كُلِّ شَرٍّ، ومِنْ كُلِّ ضَرْبَةٍ، ومِنْ كُلِّ تَجْربَةِ العَدُوِّ. بالنِّعْمةِ والرَّأفاتِ ومَحبَّةِ البَشَرِ اللَّواتي لإبْنِكَ الوَحيدِ رَبِّنا وإلَهِِنا ومُخلِّصِنا يَسوعِِِ المسيحِ. هَذا الَّذى مِنْ قِبَلهِ يَليقُ بِكَ مَعهُ المجْدُ والكَرامَةُ والعِزَّةُ، مَعَ الرّوحِ القُدُسِ الْمُحْيى الْمُساوى لَكَ الآنَ وكُلُّ أوانٍ وإلَى دَهْرِ الدُّهورِ آمين.',
    },
    {
      'title': 'طلبة تقال اخر كل ساعة',
      'body':
          'إرْحَمْنا يا اللَّهُ ثمَّ إرْحَمْنا، يا مَنْ فى كلِّ وقْتٍ وكلِّ ساعَةٍ، فى السَّماءِ وعلَى الأرْض مَسْجودٌ لَهُ ومُمجَّدٌ، المسيحُ إلَهنا الصّالحُ الطَّويلُ الرّوحِ الكثيرُ الرَّحْمةِ الجَزيلُ التَّحنُّنِ، الَّذى يُحبُّ الصِّدّيقيَن ويَرْحمُ الخُطاةَ الَّذينَ أوَّلهُم أَنا، الَّذى لا يَشاءُ مَوْت الخاطِئ مِثل ما يَرجعُ ويَحْيا، الدّاعى الكُلَّ إلَى الخَلاصِ لأجْلِ الموْعدِ بالخَيْراتِ المنْتَظرةِ. يا رَبُّ اقْبَل مِنّا فى هَذهِ السّاعةِ وكُلِّ ساعَةٍ طلباتِنا. سَهِّلْ حَياتَنا، وأرشِدْنا إلَى العَمَل بوَصاياكَ. قَدِّسْ أرْواحَنا.طهِّرْ أجْسامَنا. قَوِّمْ أفْكارَنا. نَقِّ نِيّاتَنا واشْفِ أمْراضَنا واغْفِرْ خَطايانا. ونَجِّنا مِنْ كلِّ حُزنٍ رَدئٍ ووَجَِعِ قَلْبٍ، أحِطْنا بمَلائِكتِكَ القدّيسينَ لكىْ نَكونَ بمُعَسْكَرهِم مَحْفوظينَ ومُرْشَدينَ، لنَصِلَ إلَى إتِّحاد الإيمانِ وإلَى مَعْرفةِ مَجْدكَ غَيرِ المحْسوسِ وغَيْر المحْدود، فإنَّكَ مُبارَكٌ إلَى الأبَدِ. آمين.',
    },
  ];

  late List<Map<String, String>> currentPrayers;

  @override
  void initState() {
    super.initState();
    switch (widget.prayerTime) {
      case 'صلاة باكر':
        currentPrayers = bakrPrayers;
        break;
      case 'صلاة الغروب':
        currentPrayers = arbonPrayers;
        break;
      case 'صلاة النوم':
        currentPrayers = nomPrayers;
        break;
      default:
        currentPrayers = bakrPrayers;
    }
    _pageController = PageController();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleList() {
    setState(() {
      _showList = !_showList;
      if (_showList) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    });
  }

  void _selectPrayer(int index) {
    setState(() {
      currentIndex = index;
      _toggleList();
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _nextPage() {
    if (currentIndex < currentPrayers.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _nextPage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _previousPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black;
    final bgColor = widget.isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Text(
                          widget.prayerTime,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: widget.isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: GestureDetector(
                      onTap: _toggleList,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.grey[850]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: widget.isDark
                                  ? Colors.white10
                                  : Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                currentPrayers[currentIndex]['title']!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: widget.fontSize * 0.7,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Icon(
                              _showList
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      reverse: true,
                      itemCount: currentPrayers.length,
                      onPageChanged: (index) {
                        setState(() {
                          currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final prayer = currentPrayers[index];
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(currentIndex),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: Text(
                                    prayer['body']!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: widget.fontSize,
                                      height: 1.8,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
              if (_showList)
                GestureDetector(
                  onTap: _toggleList,
                  child: Container(
                    color: Colors.black54,
                    child: Center(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 80,
                            ),
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: widget.isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      topRight: Radius.circular(25),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.menu_book,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "قائمة الصلوات",
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: currentPrayers.length,
                                    itemBuilder: (context, index) {
                                      final isSelected = currentIndex == index;
                                      return InkWell(
                                        onTap: () => _selectPrayer(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? (widget.isDark
                                                    ? Colors.blue.withOpacity(
                                                        0.2,
                                                      )
                                                    : Colors.blue.shade50)
                                                : null,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: widget.isDark
                                                    ? Colors.grey[800]!
                                                    : Colors.grey[200]!,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              if (isSelected)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Colors.blue,
                                                  size: 20,
                                                )
                                              else
                                                const SizedBox(width: 20),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  currentPrayers[index]
                                                      ['title']!,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: textColor,
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    onPressed: _toggleList,
                                    child: const Text(
                                      "إغلاق",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
