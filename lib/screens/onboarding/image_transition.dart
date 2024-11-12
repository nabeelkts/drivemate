import 'dart:async';

import 'package:flutter/material.dart';

class ImageTransitionWidget extends StatefulWidget {
  const ImageTransitionWidget({super.key});

  @override
  _ImageTransitionWidgetState createState() => _ImageTransitionWidgetState();
}

class _ImageTransitionWidgetState extends State<ImageTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _currentImageIndex;
  final List<String> images = [
    'assets/images/onboard1.png',
    'assets/images/onboard2.png',
    'assets/images/onboard3.png',
  ];
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _currentImageIndex = 0;

    _controller.addListener(() {
      setState(() {});
    });

    // Start the timer to trigger animation every 2 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _animateToNextImage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Cancel the timer when disposing the widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: images.map((image) {
            int index = images.indexOf(image);
            return Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _controller.drive(
                  CurveTween(
                    curve: Interval(
                      (index / images.length),
                      ((index + 1) / images.length),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                child: Image.asset(image, fit: BoxFit.contain),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  double _calculateOpacity(int index) {
    if (index == _currentImageIndex) {
      return _controller.value;
    } else if (index == (_currentImageIndex + 1) % images.length) {
      return 1.0 - _controller.value;
    } else {
      return 0.0;
    }
  }

  void _animateToNextImage() {
    _currentImageIndex = (_currentImageIndex + 1) % images.length;
    _controller.forward(from: 0);
  }
}
