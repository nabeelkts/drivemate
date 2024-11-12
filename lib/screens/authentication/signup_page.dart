// // ignore_for_file: use_build_context_synchronously, must_be_immutable

// import 'package:animate_do/animate_do.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:mds/constants/colors.dart';

// class SignUpPage extends StatefulWidget {
//   final Function()? onTap;
//   const SignUpPage({super.key, this.onTap});

//   @override
//   State<SignUpPage> createState() => _SignUpPageState();
// }

// class _SignUpPageState extends State<SignUpPage> {
//   final formKey = GlobalKey<FormState>();

//   bool isLoading = false;

//   final nameController = TextEditingController();
//   final emailController = TextEditingController();

//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();

//   Future addUserDetails(Map<String, String> userDetails, String uid) async {
//     await FirebaseFirestore.instance
//         .collection('users')
//         .doc(uid)
//         .set(userDetails);
//   }

//   @override
//   void dispose() {
//     List<TextEditingController> controllers = [
//       emailController,
//       passwordController,
//       nameController,
//     ];
//     for (var controller in controllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   Future signUp() async {
//     setState(() {
//       isLoading = true;
//     });

//     if (passwordConfirmed()) {
//       try {
//         UserCredential userCredential =
//             await FirebaseAuth.instance.createUserWithEmailAndPassword(
//           email: emailController.text.trim(),
//           password: passwordController.text.trim(),
//         );

//         User? user = userCredential.user;
//         if (user != null) {
//           String fullName = nameController.text.trim();
//           await user.updateDisplayName(fullName);

//           // Use the user UID as the document ID
//           await addUserDetails({
//             'name': nameController.text.trim(),
//             'email': emailController.text.trim(),
//             'password': passwordController.text.trim(),
//           }, user.uid); // Pass the user UID to the function

//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Your registration is successful'),
//             ),
//           );
//         }
//       } on FirebaseAuthException catch (e) {
//         if (e.code == 'weak-password') {
//           if (kDebugMode) {
//             print('The password provided is too weak.');
//           }
//         } else if (e.code == 'email-already-in-use') {
//           if (kDebugMode) {
//             print('The account already exists for that email.');
//           }
//         }
//       } catch (e) {
//         if (kDebugMode) {
//           print(e);
//         }
//       }
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   bool passwordConfirmed() {
//     if (passwordController.text.trim() ==
//         confirmPasswordController.text.trim()) {
//       return true;
//     } else {
//       return false;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: kBackgroundColor,
//       body: SingleChildScrollView(
//         child: Column(
//           children: <Widget>[
//             Container(
//               height: 400,
//               decoration: const BoxDecoration(
//                 image: DecorationImage(
//                     image: AssetImage('assets/images/background.png'),
//                     fit: BoxFit.fill),
//               ),
//               child: Stack(
//                 children: <Widget>[
//                   Positioned(
//                     left: 30,
//                     width: 80,
//                     height: 200,
//                     child: FadeInUp(
//                       duration: const Duration(seconds: 1),
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           image: DecorationImage(
//                             image: AssetImage('assets/images/light-1.png'),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     left: 140,
//                     width: 80,
//                     height: 150,
//                     child: FadeInUp(
//                       duration: const Duration(milliseconds: 1200),
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           image: DecorationImage(
//                             image: AssetImage('assets/images/light-2.png'),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     right: 40,
//                     top: 40,
//                     width: 80,
//                     height: 150,
//                     child: FadeInUp(
//                       duration: const Duration(milliseconds: 1300),
//                       child: Container(
//                         decoration: const BoxDecoration(
//                           image: DecorationImage(
//                             image: AssetImage('assets/images/clock.png'),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     child: FadeInUp(
//                         duration: const Duration(milliseconds: 1600),
//                         child: Container(
//                           margin: const EdgeInsets.only(top: 50),
//                           child: const Center(
//                             child: Text(
//                               "Signup",
//                               style: TextStyle(
//                                   color: kWhite,
//                                   fontSize: 40,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ),
//                         )),
//                   )
//                 ],
//               ),
//             ),
//             Padding(
//                 padding: const EdgeInsets.all(30.0),
//                 child: Form(
//                   key: formKey,
//                   child: Column(children: <Widget>[
//                     FadeInUp(
//                         duration: const Duration(milliseconds: 1800),
//                         child: Container(
//                           padding: const EdgeInsets.all(5),
//                           decoration: BoxDecoration(
//                               color: kWhite,
//                               borderRadius: BorderRadius.circular(10),
//                               border: Border.all(color: kPrimaryColor),
//                               boxShadow: const [
//                                 BoxShadow(
//                                     color: Color.fromRGBO(143, 148, 251, .2),
//                                     blurRadius: 20.0,
//                                     offset: Offset(0, 10))
//                               ]),
//                           child: Column(
//                             children: <Widget>[
//                               Container(
//                                   padding: const EdgeInsets.all(8.0),
//                                   decoration: const BoxDecoration(
//                                       border: Border(
//                                           bottom: BorderSide(
//                                               color: kPrimaryColor))),
//                                   child: TextFormField(
//                                     controller: nameController,
//                                     decoration: InputDecoration(
//                                         border: InputBorder.none,
//                                         labelText: 'Name',
//                                         hintStyle:
//                                             TextStyle(color: Colors.grey[700])),
//                                   )),
//                               Container(
//                                 padding: const EdgeInsets.all(8.0),
//                                 decoration: const BoxDecoration(
//                                   border: Border(
//                                     bottom: BorderSide(
//                                       color: kPrimaryColor,
//                                     ),
//                                   ),
//                                 ),
//                                 child: TextFormField(
//                                   controller: emailController,
//                                   validator: (text) {
//                                     if (text == null || text.isEmpty) {
//                                       return 'Email is empty';
//                                     }
//                                     return null;
//                                   },
//                                   decoration: InputDecoration(
//                                       border: InputBorder.none,
//                                       labelText: 'Email',
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700])),
//                                 ),
//                               ),
//                               Container(
//                                 padding: const EdgeInsets.all(8.0),
//                                 decoration: const BoxDecoration(
//                                     border: Border(
//                                         bottom:
//                                             BorderSide(color: kPrimaryColor))),
//                                 child: TextFormField(
//                                   controller: passwordController,
//                                   validator: (emailValidator) {
//                                     if (emailValidator == null ||
//                                         emailValidator.isEmpty) {
//                                       return 'Password is empty';
//                                     }
//                                     return null;
//                                   },
//                                   obscureText: true,
//                                   decoration: InputDecoration(
//                                       border: InputBorder.none,
//                                       labelText: 'Password',
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700])),
//                                 ),
//                               ),
//                               Container(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: TextFormField(
//                                   controller: confirmPasswordController,
//                                   validator: (text) {
//                                     if (text == null || text.isEmpty) {
//                                       return 'Confirm Password is empty';
//                                     }
//                                     return null;
//                                   },
//                                   obscureText: true,
//                                   decoration: InputDecoration(
//                                       border: InputBorder.none,
//                                       labelText: 'Confirm Password',
//                                       hintStyle:
//                                           TextStyle(color: Colors.grey[700])),
//                                 ),
//                               )
//                             ],
//                           ),
//                         )),
//                     const SizedBox(
//                       height: 30,
//                     ),
//                     FadeInUp(
//                       duration: const Duration(milliseconds: 1900),
//                       child: GestureDetector(
//                         onTap: () {
//                           signUp();
//                         },
//                         child: Container(
//                           height: 50,
//                           decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(10),
//                               gradient: const LinearGradient(
//                                   begin: AlignmentDirectional.topCenter,
//                                   end: AlignmentDirectional.bottomCenter,
//                                   colors: linearButtonColor)),
//                           child: Center(
//                             child: isLoading
//                                 ? const Center(
//                                     child: CircularProgressIndicator())
//                                 : const Text(
//                                     "Signup",
//                                     style: TextStyle(
//                                         color: Colors.white,
//                                         fontWeight: FontWeight.bold),
//                                   ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 70),
//                     FadeInUp(
//                       duration: const Duration(milliseconds: 1900),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Already have an account?',
//                             style: TextStyle(color: Colors.grey[700]),
//                           ),
//                           const SizedBox(width: 4),
//                           GestureDetector(
//                             onTap: widget.onTap,
//                             child: const Text(
//                               'Login now',
//                               style: TextStyle(
//                                 color: kPrimaryColor,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     )
//                   ]),
//                 ))
//           ],
//         ),
//       ),
//     );
//   }
// }
