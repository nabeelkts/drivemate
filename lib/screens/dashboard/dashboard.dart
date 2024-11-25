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
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                DashAppBar(),
                SizedBox(height: 10),
                  FirstImageContainer(),
                  SizedBox(height: 10),
                  RegistrationHeader(),
                  SizedBox(height: 10),
                  SecondImageContainer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
