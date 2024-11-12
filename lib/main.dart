import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mds/controller/dependency_injection.dart';
import 'package:mds/firebase_options.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (context) => GoogleSignInProvider(),
        child: GetMaterialApp(
          title: 'MDS MANAGEMENT',
          debugShowCheckedModeBanner: false,
          routes: {
            '/students': (context) => const StudentList(
                  userId: '',
                ),
            '/license': (context) => const LicenseOnlyList(
                  userId: '',
                ),
            '/endorse': (context) => const EndorsementList(
                  userId: '',
                ),
            '/rc': (context) => const VehicleDetailsList(
                  userId: '',
                ),
          },
          home:  const SplashScreen(),
          
        ),
      );
}
