import 'package:get/get.dart';
import 'package:drivemate/carousel/home_binding.dart';
import 'package:drivemate/screens/dashboard/dashboard.dart';

import 'app_routes.dart';

class AppPages {
  static var list = [
    GetPage(
      name: AppRoutes.home,
      binding: HomeBinding(),
      page: () => const Dashboard(),
    ),
  ];
}
