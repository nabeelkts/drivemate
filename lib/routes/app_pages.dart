import 'package:get/get.dart';
import 'package:mds/carousel/home_binding.dart';
import 'package:mds/screens/dashboard/dashboard.dart';

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
