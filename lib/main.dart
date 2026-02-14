import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mds/controller/dependency_injection.dart';
import 'package:mds/controller/theme_controller.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/firebase_options.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/dashboard/form/new_forms/new_student_form.dart';
import 'package:mds/screens/dashboard/list/endorsement_list.dart';
import 'package:mds/screens/dashboard/list/license_only_list.dart';
import 'package:mds/screens/dashboard/list/students_list.dart';
import 'package:mds/screens/dashboard/list/vehicle_details_list.dart';
import 'package:mds/screens/dashboard/today_schedule_page.dart';
import 'package:mds/screens/navigation_screen.dart';
import 'package:mds/screens/onboarding/splash_screen.dart';
import 'package:mds/screens/dashboard/test_date_updater_screen.dart';
import 'package:mds/screens/notification/notification_screen.dart';
import 'package:mds/screens/dashboard/list/dl_services_list.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await GetStorage.init();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Get.put<ThemeController>(ThemeController(), permanent: true);
  runApp(const MyApp());
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    bool? isDarkMode = box.read('isDarkMode');

    if (isDarkMode == null) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
      box.write('isDarkMode', isDarkMode);
    }

    // Set initial status bar style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDarkMode ? Colors.black : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return Obx(() {
      final themeController = Get.find<ThemeController>();
      final primaryColor = Color(themeController.themeColorValue.value);
      final lightTheme = ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor, brightness: Brightness.light),
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: primaryColor),
      );

      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor, brightness: Brightness.dark),
        primaryColor: primaryColor,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: primaryColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
        floatingActionButtonTheme:
            FloatingActionButtonThemeData(backgroundColor: primaryColor),
      );

      return ChangeNotifierProvider(
        create: (context) => GoogleSignInProvider(),
        child: GetMaterialApp(
          title: 'MDS MANAGEMENT',
          debugShowCheckedModeBanner: false,
          themeMode: themeController.themeMode.value,
          theme: lightTheme,
          darkTheme: darkTheme,
          builder: (context, child) {
            // Update status bar style based on current theme
            final brightness = Theme.of(context).brightness;
            final isDark = brightness == Brightness.dark;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor:
                      isDark ? Colors.black : Colors.white,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                ),
              );
            });

            return child!;
          },
          routes: {
            '/home': (context) => const BottomNavScreen(),
            '/students': (context) => StudentList(userId: ''),
            '/license': (context) => const LicenseOnlyList(userId: ''),
            '/endorse': (context) => const EndorsementList(userId: ''),
            '/rc': (context) => const VehicleDetailsList(),
            '/new_student': (context) => const NewStudent(),
            '/today_schedule': (context) => const TodaySchedulePage(),
            '/test_dates': (context) => const TestDateUpdaterScreen(),
            '/notification': (context) => const NotificationsScreen(),
            '/dl_services': (context) => const DlServicesList(userId: ''),
          },
          home: const SplashScreen(),
        ),
      );
    });
  }
}
