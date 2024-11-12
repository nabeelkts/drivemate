import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mds/controller/controllers.dart';
import 'package:mds/carousel/carousel_loading.dart';
import 'package:mds/carousel/carousel_with_indicator.dart';

Widget buildCarouselSection() {
  return Obx(() {
    if (carouselController.isLoading.value) {
      return const Center(
        child: CarouselLoading(),
      );
    } else {
      return carouselController.carouselItemList.isNotEmpty
          ? CarouselWithIndicator(data: carouselController.carouselItemList)
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty),
                  Text("Data not found!"),
                ],
              ),
            );
    }
  });
}
