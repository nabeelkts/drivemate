import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:drivemate/constants/colors.dart';
import 'package:drivemate/screens/widget/custom_back_button.dart';

class AttendanceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> attendanceData;
  final String studentId;
  final String targetId;

  const AttendanceDetailsPage({
    required this.attendanceData,
    required this.studentId,
    required this.targetId,
    super.key,
  });

  @override
  State<AttendanceDetailsPage> createState() => _AttendanceDetailsPageState();
}

class _AttendanceDetailsPageState extends State<AttendanceDetailsPage> {
  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};
  List<LatLng> _pathPoints = [];
  bool _isLoadingPath = true;

  @override
  void initState() {
    super.initState();
    _loadPath();
  }

  Future<void> _loadPath() async {
    final sessionId = widget.attendanceData['lessonSessionId'];
    if (sessionId == null) {
      setState(() => _isLoadingPath = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(sessionId)
          .collection('points')
          .orderBy('timestamp', descending: false)
          .get();

      if (snapshot.docs.isNotEmpty) {
        _pathPoints = snapshot.docs.map((doc) {
          final data = doc.data();
          return LatLng(data['lat'], data['lng']);
        }).toList();

        _polylines.add(Polyline(
          polylineId: const PolylineId('lesson_path'),
          points: _pathPoints,
          color: kPrimaryColor,
          width: 5,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }
    } catch (e) {
      debugPrint('Error loading path: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingPath = false);
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_pathPoints.isNotEmpty) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_pathPoints.isEmpty || _mapController == null) return;

    double minLat = _pathPoints.first.latitude;
    double maxLat = _pathPoints.first.latitude;
    double minLng = _pathPoints.first.longitude;
    double maxLng = _pathPoints.first.longitude;

    for (final point in _pathPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = Theme.of(context).cardColor;

    final date = (widget.attendanceData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final startTime = (widget.attendanceData['startTime'] as Timestamp?)?.toDate();
    final endTime = (widget.attendanceData['endTime'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Details'),
        leading: const CustomBackButton(),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(date)),
                  const Divider(),
                  _buildDetailRow('Time', startTime != null && endTime != null
                      ? '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}'
                      : 'N/A'),
                  const Divider(),
                  _buildDetailRow('Duration', widget.attendanceData['duration'] ?? 'N/A'),
                  const Divider(),
                  _buildDetailRow('Instructor', widget.attendanceData['instructorName'] ?? 'Unknown'),
                  const Divider(),
                  _buildDetailRow('Vehicle', widget.attendanceData['vehicleNumber'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Distance Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('Start KM', widget.attendanceData['startKm']?.toString() ?? '0'),
                  _buildStatColumn('End KM', widget.attendanceData['endKm']?.toString() ?? '0'),
                  _buildStatColumn('Total KM', widget.attendanceData['distance']?.toString() ?? '0 KM'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Route Trace',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Map Container
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: _isLoadingPath
                  ? const Center(child: CircularProgressIndicator())
                  : _pathPoints.isEmpty
                      ? const Center(child: Text('No route trace recorded for this session.'))
                      : GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _pathPoints.first,
                            zoom: 15,
                          ),
                          polylines: _polylines,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: true,
                          mapType: MapType.normal,
                        ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimaryColor)),
      ],
    );
  }
}
