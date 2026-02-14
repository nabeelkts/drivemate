import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mds/constants/colors.dart';
import 'package:shimmer/shimmer.dart';
import 'package:animate_do/animate_do.dart';

class TodayScheduleCard extends StatefulWidget {
  const TodayScheduleCard({super.key});

  @override
  State<TodayScheduleCard> createState() => _TodayScheduleCardState();
}

class _TodayScheduleCardState extends State<TodayScheduleCard> {
  static final DateFormat _storageDateFormat = DateFormat('yyyy-MM-dd');
  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  final List<StreamSubscription> _subscriptions = [];
  List<DocumentSnapshot> _learnersDocs = [];
  List<DocumentSnapshot> _drivingDocs = [];

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final dateStr = _storageDateFormat.format(DateTime.now());

    // Learners Stream
    _subscriptions.add(FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .where('learnersTestDate', isEqualTo: dateStr)
        .snapshots()
        .listen((snapshot) {
      _learnersDocs = snapshot.docs;
      _updateItems();
    }));

    // Driving Stream
    _subscriptions.add(FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('students')
        .where('drivingTestDate', isEqualTo: dateStr)
        .snapshots()
        .listen((snapshot) {
      _drivingDocs = snapshot.docs;
      _updateItems();
    }));
  }

  void _updateItems() {
    if (!mounted) return;

    final List<Map<String, dynamic>> newItems = [];
    final timeSlots = [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '12:00 PM',
      '01:00 PM'
    ];
    int slot = 0;

    for (var doc in _learnersDocs) {
      final d = doc.data() as Map<String, dynamic>;
      if (slot < timeSlots.length) {
        newItems.add({
          'time': timeSlots[slot],
          'name': d['fullName'] ?? 'N/A',
          'role': 'LL',
          'profileUrl': d['profileImageUrl'],
          'type': 'learners',
        });
        slot++;
      }
    }

    for (var doc in _drivingDocs) {
      final d = doc.data() as Map<String, dynamic>;
      if (slot < timeSlots.length) {
        newItems.add({
          'time': timeSlots[slot],
          'name': d['fullName'] ?? 'N/A',
          'role': 'DL',
          'profileUrl': d['profileImageUrl'],
          'type': 'driving',
        });
        slot++;
      }
    }

    setState(() {
      _items.clear();
      _items.addAll(newItems);
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    if (_isLoading) {
      return _buildLoadingState(context);
    }

    return _buildCard(context, textColor, _items.take(5).toList());
  }

  Widget _buildLoadingState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[850]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return _buildCard(
      context,
      Colors.transparent,
      [],
      isLoading: true,
      shimmerBase: baseColor,
      shimmerHighlight: highlightColor,
    );
  }

  Widget _buildCard(
    BuildContext context,
    Color textColor,
    List<Map<String, dynamic>> items, {
    bool isLoading = false,
    Color? shimmerBase,
    Color? shimmerHighlight,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF252525),
                  const Color(0xFF1A1A1A),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8F9FA),
                ],
        ),
        borderRadius: BorderRadius.circular(20), // More rounded
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: FadeInUp(
        duration: const Duration(milliseconds: 400),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/today_schedule'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: kOrange.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.event_note,
                                  color: kOrange, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Today's Schedule",
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          color: textColor.withOpacity(0.3), size: 18),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isLoading)
                    Column(
                      children: List.generate(
                        2,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Shimmer.fromColors(
                            baseColor: shimmerBase!,
                            highlightColor: shimmerHighlight!,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else if (items.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: textColor.withOpacity(0.1), size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'No exams scheduled',
                            style: TextStyle(
                                color: textColor.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length > 3 ? 3 : items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _ScheduleRow(
                          time: item['time'] as String,
                          name: item['name'] as String,
                          role: item['role'] as String,
                          profileUrl: item['profileUrl'] as String?,
                          textColor: textColor,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final String time;
  final String name;
  final String role;
  final String? profileUrl;
  final Color textColor;

  const _ScheduleRow({
    required this.time,
    required this.name,
    required this.role,
    this.profileUrl,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowColor = isDark ? Colors.white.withOpacity(0.03) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.02),
        ),
      ),
      child: Row(
        children: [
          _buildAvatar(isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: textColor.withOpacity(0.5),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (role == 'LL' ? Colors.blue : kOrange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: role == 'LL' ? Colors.blue : kOrange,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: kOrange.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 15,
        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
        backgroundImage: profileUrl != null && profileUrl!.isNotEmpty
            ? CachedNetworkImageProvider(profileUrl!)
            : null,
        child: profileUrl == null || profileUrl!.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: textColor.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }
}
