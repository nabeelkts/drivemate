import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:mds/controller/network_controller.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/controller/workspace_controller.dart';
import 'package:mds/services/app_lifecycle_service.dart';
import 'package:mds/features/tracking/data/repositories/firebase_tracking_repository.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';
import 'package:mds/controller/permission_controller.dart';

class DependencyInjection {
  static void init() {
    Get.put<PermissionController>(PermissionController(), permanent: true);
    Get.put<NetworkController>(NetworkController(), permanent: true);
    Get.put<AppLifecycleService>(AppLifecycleService(), permanent: true);
    Get.put<AppController>(AppController(), permanent: true);
    Get.put<WorkspaceController>(WorkspaceController(), permanent: true);

    // ✅ FIXED: Use explicit database URL to match the background service isolate.
    // Without this, FirebaseDatabase.instance may connect to a different
    // database instance than the one drivers are writing to.
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://smds-c1713-default-rtdb.firebaseio.com',
    );
    final trackingRepo = FirebaseTrackingRepository(database);
    Get.put<TrackingRepository>(trackingRepo, permanent: true);

    // LocationTrackingService reads metadata from GetStorage as fallback
    // so schoolId/branchId are always populated even in foreground mode
    Get.put<LocationTrackingService>(LocationTrackingService(),
        permanent: true);
  }
}
