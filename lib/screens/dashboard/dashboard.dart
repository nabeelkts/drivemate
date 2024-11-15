import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/screens/dashboard/widgets/appbar.dart';
import 'package:mds/screens/dashboard/widgets/first_image_container.dart';
import 'package:mds/screens/dashboard/widgets/registration_header_widget.dart';
import 'package:mds/screens/dashboard/widgets/second_image_container.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.put(AppController());

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const DashAppBar(),
              SizedBox(
                height: 515,
                child: Stack(
                  children: [
                    FirstImageContainer(),
                    const Positioned(
                      top: 185,
                      left: 0,
                      right: 0,
                      child: RegistrationHeader(),
                    ),
                  ],
                ),
              ),
              SecondImageContainer(),
            ],
          ),
        ),
      ),
    );
  }
}
