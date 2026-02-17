import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/features/tracking/services/background_service.dart';
import 'package:mds/features/tracking/services/location_tracking_service.dart';

/// Staff dashboard for tracking status
///
/// Shows current tracking status and allows manual control.
class StaffTrackingScreen extends StatefulWidget {
  const StaffTrackingScreen({super.key});

  @override
  State<StaffTrackingScreen> createState() => _StaffTrackingScreenState();
}

class _StaffTrackingScreenState extends State<StaffTrackingScreen> {
  final LocationTrackingService _trackingService =
      Get.find<LocationTrackingService>();

  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    final isRunning = await BackgroundService.isRunning();
    setState(() {
      _isServiceRunning = isRunning;
    });
  }

  Future<void> _toggleTracking() async {
    if (_isServiceRunning) {
      await BackgroundService.stop();
      await _trackingService.stopTracking();
    } else {
      await BackgroundService.start();
    }
    await _checkServiceStatus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isServiceRunning
                      ? Colors.green.shade400
                      : Colors.grey.shade400,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _isServiceRunning ? Icons.location_on : Icons.location_off,
                    size: 64,
                    color: _isServiceRunning
                        ? Colors.green.shade400
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isServiceRunning ? 'Tracking Active' : 'Tracking Inactive',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isServiceRunning
                        ? 'Your location is being shared'
                        : 'Start a lesson to enable tracking',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Cards
            if (_trackingService.isTracking) ...[
              _buildInfoCard(
                'Current Lesson',
                _trackingService.currentLessonId ?? 'None',
                Icons.school,
                textColor,
                cardColor,
              ),
              const SizedBox(height: 12),
            ],

            // Control Button
            const Spacer(),
            ElevatedButton(
              onPressed: _toggleTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isServiceRunning ? Colors.red.shade400 : kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isServiceRunning ? 'Stop Tracking' : 'Start Tracking Service',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Note: Tracking starts automatically when you begin a lesson',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color textColor,
    Color cardColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
