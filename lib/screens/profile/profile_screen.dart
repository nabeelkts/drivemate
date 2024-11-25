import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/app_controller.dart';
import 'package:mds/screens/authentication/google_sign_in.dart';
import 'package:mds/screens/profile/action_button.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final AppController appController = Get.put(AppController());
  final box = GetStorage();
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = box.read('isDarkMode') ?? false;
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      box.write('isDarkMode', isDarkMode);
      Get.changeThemeMode(isDarkMode ? ThemeMode.dark : ThemeMode.light);
    });
  }

  void showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 30),
            decoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Confirm Logout?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 21.4,
                   // color: kBlack,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ActionButton(
                        text: 'Cancel',
                        backgroundColor: const Color(0xFFFFF1F1),
                        textColor: const Color(0xFFFF0000),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ActionButton(
                        text: 'Logout',
                        backgroundColor: const Color(0xFFF6FFF0),
                        textColor: kBlack,
                        onPressed: () {
                          Navigator.of(context).pop();
                          final provider = Provider.of<GoogleSignInProvider>(context, listen: false);
                          provider.logout();
                          FirebaseAuth.instance.signOut();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            GestureDetector(
              onTap: toggleTheme,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                            child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Name: ${user.displayName ?? "N/A"}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Email: ${user.email!}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    appController.checkForUpdate();
                    if (!appController.isLatestVersion.value) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('A new update is available!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You are using the latest version.'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  },
                  child: buildInfoCard(Icons.info_outline, 'Check for updates', textColor: const Color.fromARGB(255, 124, 124, 242)),
                ),
                const SizedBox(height: 8),
                Obx(() => buildInfoCard(Icons.system_update, 'App Version: ${appController.currentVersion.value}')),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: showLogoutConfirmationDialog,
                  child: buildInfoCard(Icons.logout, 'Logout', textColor: Colors.red, iconColor: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String text, {Color textColor = Colors.grey, Color iconColor = kOrange, Widget? trailing}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 16, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
