/* lib/main.dart */
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mds/controller/dependency_injection.dart';
import 'package:mds/firebase_options.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/dashboard/form/new_forms/new_student_form.dart';
import 'package:mds/screens/dashboard/list/endorsement_list.dart';
import 'package:mds/screens/dashboard/list/license_only_list.dart';
import 'package:mds/screens/dashboard/list/students_list.dart';
import 'package:mds/screens/dashboard/list/vehicle_details_list.dart';
import 'package:mds/screens/onboarding/splash_screen.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
  DependencyInjection.init();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = GetStorage();
    // Check if the theme preference is already stored
    bool? isDarkMode = box.read('isDarkMode');

    // If not stored, use the system preference
    if (isDarkMode == null) {
      // ignore: deprecated_member_use
      final brightness = WidgetsBinding.instance.window.platformBrightness;
      isDarkMode = brightness == Brightness.dark;
      box.write('isDarkMode', isDarkMode);
    }

    // Define light and dark themes
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
      ),
      // Add other theme properties as needed
    );

    final ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.black,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
      ),
      // Add other theme properties as needed
    );

    return ChangeNotifierProvider(
      create: (context) => GoogleSignInProvider(),
      child: GetMaterialApp(
        title: 'MDS MANAGEMENT',
        debugShowCheckedModeBanner: false,
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        theme: lightTheme,
        darkTheme: darkTheme,
        routes: {
          '/students': (context) => const StudentList(userId: ''),
          '/license': (context) => const LicenseOnlyList(userId: ''),
          '/endorse': (context) => const EndorsementList(userId: ''),
          '/rc': (context) => const VehicleDetailsList(userId: ''),
          '/new_student': (context) => const NewStudent(),
        },
        home: const SplashScreen(),
      ),
    );
  }
}
