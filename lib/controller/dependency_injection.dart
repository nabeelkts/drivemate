import 'package:get/get.dart';
import 'package:mds/controller/network_controller.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/services/app_lifecycle_service.dart';

class DependencyInjection {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
    Get.put<AppLifecycleService>(AppLifecycleService(), permanent: true);
    Get.put<AppController>(AppController(), permanent: true);
    Get.put<WorkspaceController>(WorkspaceController(), permanent: true);
  }
}
