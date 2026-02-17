import 'package:get/get.dart';
import 'package:mds/controller/network_controller.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/services/app_lifecycle_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mds/features/tracking/data/repositories/firebase_tracking_repository.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';
import 'package:mds/features/tracking/services/background_service.dart';

class DependencyInjection {
  static void init() {
    Get.put<NetworkController>(NetworkController(), permanent: true);
    Get.put<AppLifecycleService>(AppLifecycleService(), permanent: true);
    Get.put<AppController>(AppController(), permanent: true);
    Get.put<WorkspaceController>(WorkspaceController(), permanent: true);

    // Tracking Services
    final database = FirebaseDatabase.instance;
    final trackingRepo = FirebaseTrackingRepository(database);
    Get.put<TrackingRepository>(trackingRepo, permanent: true);
    Get.put<LocationTrackingService>(LocationTrackingService(),
        permanent: true);
  }
}
