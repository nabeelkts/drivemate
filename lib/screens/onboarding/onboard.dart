// import 'package:flutter/material.dart';

// class OnBoard extends StatefulWidget {
//   const OnBoard({super.key});

//   @override
//   State<OnBoard> createState() => _OnBoardState();
// }

// class _OnBoardState extends State<OnBoard> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         // onboarding11RN (412:484)
//         padding: EdgeInsets.fromLTRB(20, 16, 20, 168),
//         width: double.infinity,
//         decoration: BoxDecoration(
//           color: Color(0xffffffff),
//           borderRadius: BorderRadius.circular(30),
//         ),
//         child: Container(
//           // drivemate3Rv (412:489)
//           margin: EdgeInsets.fromLTRB(0, 0, 1, 73),
//           child: Text(
//             'Drivemate',
//             style: TextStyle(
//               fontFamily: 'Inter',
//               fontSize: 36,
//               fontWeight: FontWeight.w600,
//               height: 1.2125,
//             ),
//           ),
//         ),
//         child: Container(
//           // component1y4g (617:2343)
//           margin: EdgeInsets.fromLTRB(20, 0, 20, 46),
//           child: TextButton(
//             onPressed: () {},
//             style: TextButton.styleFrom(
//               padding: EdgeInsets.zero,
//             ),
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 boxShadow: [
//                   BoxShadow(
//                     color: Color(0x3f000000),
//                     offset: Offset(0, 4),
//                     blurRadius: 2,
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   Container(
//                     // autogroupfbtyEmJ (TavW8ywCky69VQAEQiFbtY)
//                     margin: EdgeInsets.fromLTRB(0, 0, 0, 16),
//                     width: double.infinity,
//                     height: 285,
//                     child: Stack(
//                       children: [
//                         Positioned(
//                           // iphone14plus1xSQ (I617:2343;617:2450)
//                           left: 219,
//                           top: 20,
//                           child: Align(
//                             child: SizedBox(
//                               width: 131,
//                               height: 264.79,
//                               child: Image.network(
//                                 '',
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           // noti2rng (I617:2343;617:2319)
//                           left: 0,
//                           top: 20,
//                           child: Align(
//                             child: SizedBox(
//                               width: 131,
//                               height: 265,
//                               child: Image.network(
//                                 '',
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           // home2k7N (I617:2343;617:2384)
//                           left: 104,
//                           top: 0,
//                           child: Align(
//                             child: SizedBox(
//                               width: 141,
//                               height: 285,
//                               child: Image.network(
//                                 '',
//                                 fit: BoxFit.cover,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     // autogroupejzksBz (TavWEeSS4AvZqUSRBiEjzk)
//                     margin: EdgeInsets.fromLTRB(125, 0, 125, 0),
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(58),
//                       gradient: LinearGradient(
//                         begin: Alignment(-0.234, -1.721),
//                         end: Alignment(-0.234, 2.092),
//                         colors: <Color>[Color(0x33f46b45), Color(0x33eea849)],
//                         stops: <double>[0, 1],
//                       ),
//                     ),
//                     child: Align(
//                       // rectangle11999W (I617:2343;617:2322)
//                       alignment: Alignment.centerLeft,
//                       child: SizedBox(
//                         width: 33.33,
//                         height: 5,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(58),
//                             gradient: LinearGradient(
//                               begin: Alignment(-0.234, -1.721),
//                               end: Alignment(-0.234, 2.092),
//                               colors: <Color>[
//                                 Color(0xfff46b45),
//                                 Color(0xffeea849)
//                               ],
//                               stops: <double>[0, 1],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         Container(
//           // effortlessstudentmanagementsim (617:2361)
//           margin: EdgeInsets.fromLTRB(3, 0, 0, 17),
//           constraints: BoxConstraints(
//             maxWidth: 330,
//           ),
//           child: Text(
//             'Effortless student management. Simplify enrollment, track progress, and nurture relationships with Drivemate’s comprehensive database',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: 'Inter',
//               fontSize: 12,
//               fontWeight: FontWeight.w400,
//               height: 1.2125,
//               color: Color(0xff000000),
//             ),
//           ),
//         ),
//         Container(
//           // financialclarityatyourfingerti (617:2362)
//           margin: EdgeInsets.fromLTRB(2, 0, 0, 33),
//           constraints: BoxConstraints(
//             maxWidth: 326,
//           ),
//           child: Text(
//             'Financial clarity at your fingertips. Manage fees, generate reports, and stay ahead of outstanding payments with Drivemate’s intuitive accounting tools',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontFamily: 'Inter',
//               fontSize: 12,
//               fontWeight: FontWeight.w400,
//               height: 1.2125,
//               color: Color(0xff000000),
//             ),
//           ),
//         ),
//         TextButton(
//           // exploreUDi (617:2379)
//           onPressed: () {},
//           style: TextButton.styleFrom(
//             padding: EdgeInsets.zero,
//           ),
//           child: Container(
//             width: double.infinity,
//             height: 44,
//             decoration: BoxDecoration(
//               color: Color(0xfffffbf7),
//               borderRadius: BorderRadius.circular(15),
//               border: Border(),
//             ),
//             child: Center(
//               child: Text(
//                 'Get Started',
//                 style: TextStyle(
//                   fontFamily: 'Inter',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                   height: 1.2125,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
