import 'package:get/get.dart';
import 'package:mds/controller/carousel_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(CarouselController());
  }
}
