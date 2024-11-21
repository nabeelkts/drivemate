// import 'package:flutter/material.dart';

// class StudentForm extends StatelessWidget {
//   const StudentForm({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 Container(
//                   width: 390,
//                   height: 728,
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Container(
//                         width: 150,
//                         height: 150,
//                         child: Stack(
//                           children: [
//                             Positioned(
//                               left: 0,
//                               top: 0,
//                               child: Container(
//                                 width: 150,
//                                 height: 150,
//                                 decoration: ShapeDecoration(
//                                   color: Colors.white,
//                                   shape: OvalBorder(
//                                     side: BorderSide(
//                                         width: 0.50, color: Color(0xFFF46B45)),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             Positioned(
//                               left: -41,
//                               top: 0,
//                               child: Container(
//                                 width: 232,
//                                 height: 156,
//                                 decoration: BoxDecoration(
//                                   image: DecorationImage(
//                                     image: NetworkImage(''),
//                                     fit: BoxFit.fill,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Container(
//                         width: 40,
//                         padding: const EdgeInsets.all(10),
//                         decoration: ShapeDecoration(
//                           color: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             side: BorderSide(
//                                 width: 0.50, color: Color(0xFFF46B45)),
//                             borderRadius: BorderRadius.circular(36),
//                           ),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             //,
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       Container(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           mainAxisAlignment: MainAxisAlignment.start,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.only(
//                                   top: 16, left: 7, right: 7, bottom: 63),
//                               clipBehavior: Clip.antiAlias,
//                               decoration: ShapeDecoration(
//                                 color: Colors.white,
//                                 shape: RoundedRectangleBorder(
//                                   side: BorderSide(
//                                       width: 0.50, color: Color(0xFFF46B45)),
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                               ),
//                               child: Column(
//                                 mainAxisSize: MainAxisSize.min,
//                                 mainAxisAlignment: MainAxisAlignment.start,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Container(
//                                     width: double.infinity,
//                                     padding: const EdgeInsets.all(8),
//                                     child: Column(
//                                       mainAxisSize: MainAxisSize.min,
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.start,
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         Container(
//                                           width: double.infinity,
//                                           padding: const EdgeInsets.all(8),
//                                           child: Row(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Text(
//                                                 'Name of Student          :',
//                                                 style: TextStyle(
//                                                   color: Colors.black,
//                                                   fontSize: 13,
//                                                   fontFamily: 'Inter',
//                                                   fontWeight: FontWeight.w500,
//                                                   height: 0,
//                                                 ),
//                                               ),
//                                               SizedBox(
//                                                   width:
//                                                       8), // Adjust the spacing between the label and the TextFormField
//                                               Container(
//                                                 width: 175,
//                                                 height:
//                                                     20, // Adjust the width of the TextFormField according to your needs
//                                                 child: TextFormField(
//                                                   decoration: InputDecoration(
//                                                     border: InputBorder.none,

//                                                     // labelText: 'Name of Student',
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         Container(
//                                           width: 360,
//                                           decoration: const ShapeDecoration(
//                                             shape: RoundedRectangleBorder(
//                                               side: BorderSide(
//                                                 width: 1,
//                                                 strokeAlign: BorderSide
//                                                     .strokeAlignCenter,
//                                                 color: Color(0xFFF46B45),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         const Text.rich(
//                                           TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: 'Student ID',
//                                                 style: TextStyle(
//                                                   color: Colors.black,
//                                                   fontSize: 13,
//                                                   fontFamily: 'Inter',
//                                                   fontWeight: FontWeight.w500,
//                                                   height: 0,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text:
//                                                     '                    : 390 35575 ',
//                                                 style: TextStyle(
//                                                   color: Color(0xFF737373),
//                                                   fontSize: 13,
//                                                   fontFamily: 'Inter',
//                                                   fontWeight: FontWeight.w500,
//                                                   height: 0,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Address                        : Rahul Nivas, Palarivattam P.O\n                                         Eranakulam',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Date of Birth                : 08-10-1995',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Phone Number             : +91 8137985674',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Blood Group                 : A-ve',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Fees                               : Rs. 9,500',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Advance Received      : Rs. 9,500',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text.rich(
//                                           TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text:
//                                                     'Advance Received      : Rs. 5,000   \n',
//                                                 style: TextStyle(
//                                                   color: Colors.black,
//                                                   fontSize: 13,
//                                                   fontFamily: 'Inter',
//                                                   fontWeight: FontWeight.w500,
//                                                   height: 0,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text:
//                                                     '                                             Balance Rs. 4,500',
//                                                 style: TextStyle(
//                                                   color: Color(0xFF8F8F8F),
//                                                   fontSize: 12,
//                                                   fontFamily: 'Inter',
//                                                   fontWeight: FontWeight.w500,
//                                                   height: 0,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Opacity(
//                                           opacity: 0.25,
//                                           child: Container(
//                                             width: 360,
//                                             decoration: ShapeDecoration(
//                                               shape: RoundedRectangleBorder(
//                                                 side: BorderSide(
//                                                   width: 1,
//                                                   strokeAlign: BorderSide
//                                                       .strokeAlignCenter,
//                                                   color: Color(0xFFF46B45),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Text(
//                                           'Course Selected      ',
//                                           style: TextStyle(
//                                             color: Colors.black,
//                                             fontSize: 13,
//                                             fontFamily: 'Inter',
//                                             fontWeight: FontWeight.w500,
//                                             height: 0,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         Container(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 75, vertical: 10),
//                                           decoration: ShapeDecoration(
//                                             color: Colors.white,
//                                             shape: RoundedRectangleBorder(
//                                               side: BorderSide(
//                                                   width: 0.50,
//                                                   color: Color(0xFFF46B45)),
//                                               borderRadius:
//                                                   BorderRadius.circular(10),
//                                             ),
//                                           ),
//                                           child: Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.center,
//                                             children: [
//                                               Expanded(
//                                                 child: SizedBox(
//                                                   child: Text(
//                                                     'LMV Study + M/C License',
//                                                     style: TextStyle(
//                                                       color: Color(0xFFF46B45),
//                                                       fontSize: 16,
//                                                       fontFamily: 'Inter',
//                                                       fontWeight:
//                                                           FontWeight.w600,
//                                                       height: 0,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             Container(
//                               width: 390,
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 136, vertical: 10),
//                               decoration: ShapeDecoration(
//                                 color: Color(0xFFFFFBF7),
//                                 shape: RoundedRectangleBorder(
//                                   side: BorderSide(
//                                       width: 0.50, color: Color(0xFFF46B45)),
//                                   borderRadius: BorderRadius.circular(15),
//                                 ),
//                               ),
//                               child: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.center,
//                                 children: [
//                                   Expanded(
//                                     child: SizedBox(
//                                       child: Text(
//                                         'Create Student',
//                                         style: TextStyle(
//                                           color: Color(0xFFF46B45),
//                                           fontSize: 16,
//                                           fontFamily: 'Inter',
//                                           fontWeight: FontWeight.w600,
//                                           height: 0,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
