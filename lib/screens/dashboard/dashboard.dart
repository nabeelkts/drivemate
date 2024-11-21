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
    // ignore: unused_local_variable
    final AppController appController = Get.put(AppController());

    return const SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              DashAppBar(),
              SizedBox(
                height: 495,
                child: Stack(
                  children: [
                    FirstImageContainer(),
                    Positioned(
                      top: 200,
                      left: 0,
                      right: 0,
                      child: RegistrationHeader(),
                    ),
                  ],
                ),
              ),SizedBox(height: 20,),
              SecondImageContainer(),
            ],
          ),
        ),
      ),
    );
  }
}
