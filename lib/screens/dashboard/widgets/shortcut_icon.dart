import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:drivemate/widgets/persistent_cached_image.dart';

class ShortcutIcon extends StatefulWidget {
  const ShortcutIcon({super.key});

  @override
  _ShortcutIconState createState() => _ShortcutIconState();
}

class _ShortcutIconState extends State<ShortcutIcon> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> recentActivities = [];
  User? user = FirebaseAuth.instance.currentUser;
  StreamSubscription<QuerySnapshot>? _activitiesSubscription;

  @override
  void initState() {
    super.initState();
    _listenToRecentActivities();
  }

  void _listenToRecentActivities() {
    if (user != null) {
      _activitiesSubscription = _firestore
          .collection('users')
          .doc(user!.uid)
          .collection('recentActivity')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          final uniqueActivities =
              <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
          for (var doc in snapshot.docs) {
            final data = doc.data();
            if (data['studentId'] != null) {
              uniqueActivities[data['studentId']] = doc;
            }
          }
          setState(() {
            recentActivities = uniqueActivities.values.toList();
          });
        }
      }, onError: (error) {
        debugPrint('Recent activities stream error: $error');
      });
    }
  }

  @override
  void dispose() {
    _activitiesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return recentActivities.isEmpty
        ? _buildPlaceholder()
        : Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < recentActivities.length; i++) ...[
                    if (i > 0) const SizedBox(width: 24),
                    Builder(
                      builder: (context) {
                        final activity = recentActivities[i];
                        final data = activity.data();
                        final fullName =
                            _extractFullName(data['details'] ?? 'N/A');
                        return buildIconContainer(fullName,
                            data['title'] ?? 'No Title', data['imageUrl']);
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
  }

  Widget _buildPlaceholder() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.hourglass_empty,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(width: 10),
            Text(
              'No recent activity available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildIconContainer(
      String fullName, String activityDescription, String? imageUrl) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 74,
          decoration: const BoxDecoration(
            color: Colors.blueGrey,
            shape: BoxShape.circle,
          ),
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? PersistentCachedImage(
                  imageUrl: imageUrl,
                  borderRadius: BorderRadius.circular(40),
                  memCacheWidth: 150,
                  memCacheHeight: 150,
                  errorWidget: Center(
                    child: Text(
                      _getFirstSixLetters(fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    _getFirstSixLetters(fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
        ),
        Text(
          activityDescription,
          style: const TextStyle(
            fontSize: 10,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getFirstSixLetters(String fullName) {
    if (fullName.isEmpty) return 'N/A';
    return fullName.length > 6 ? fullName.substring(0, 6) : fullName;
  }

  String _extractFullName(String details) {
    final nameLine = details.split('\n').firstWhere(
          (line) => line.startsWith(''),
          orElse: () => 'N/A',
        );
    return nameLine.replaceFirst('', '').trim();
  }
}
