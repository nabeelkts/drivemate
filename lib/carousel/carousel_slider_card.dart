import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mds/model/carousel_model.dart';
import 'package:shimmer/shimmer.dart';

class CarouselSliderCard extends StatefulWidget {
  final List<CarouselModel> data;
  const CarouselSliderCard({Key? key, required this.data}) : super(key: key);

  @override
  State<CarouselSliderCard> createState() => _CarouselSliderCardState();
}

class _CarouselSliderCardState extends State<CarouselSliderCard> {
  late final PageController pageController;
  int pageNo = 0;
  Timer? carouselTimer;

  Timer getTimer() {
    return Timer.periodic(const Duration(seconds: 3), (timer) {
      if (pageNo == widget.data.length - 1) {
        pageNo = 0;
      }
      pageController.animateToPage(
        pageNo,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCirc,
      );
      pageNo++;
    });
  }

  @override
  void initState() {
    pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.8, // Adjust the fraction as needed
    );
    carouselTimer = getTimer();
    super.initState();
  }

  @override
  void dispose() {
    carouselTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      highlightColor: Colors.white,
      baseColor: Colors.grey.shade300,
      child: Column(
        children: [
          SizedBox(
            height: 150, // Adjust the height as needed
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                pageNo = index;
                setState(() {});
              },
              itemBuilder: (_, index) {
                return GestureDetector(
                  onTap: () {},
                  onPanDown: (d) {
                    carouselTimer?.cancel();
                    carouselTimer = null;
                  },
                  onPanCancel: () {
                    carouselTimer = getTimer();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              itemCount: widget.data.length,
            ),
          ),
          const SizedBox(
            height: 12.0,
          ),
        ],
      ),
    );
  }
}
