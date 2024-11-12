import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    AppController appController=Get.put(AppController());
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profile',
            ),
            actions: [GestureDetector(onTap: () {
   final appController = Get.find<AppController>();
          appController.checkForUpdate(); 
                },
                child: const Icon(
                  Icons.update,
                ),
                ),
              GestureDetector(
                onTap: () {
                  final provider =
                      Provider.of<GoogleSignInProvider>(context, listen: false);
                  provider.logout();
                  FirebaseAuth.instance.signOut();
                },
                child: const Icon(
                  Icons.logout,
                ),
              ),
            ],
          ),
          body: Container(
            alignment: Alignment.center,
            color: kWhite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(user.photoURL!),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text('Name: ${user.displayName!}'),
                const SizedBox(
                  height: 8,
                ),
                Text('Email: ${user.email!}')
              ],
            ),
          ),
          ),
    );
  }
}
