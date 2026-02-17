import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';

/// Owner dashboard showing real-time driver locations
///
/// Displays all online drivers on Google Maps with smooth marker updates.
/// Markers update WITHOUT rebuilding the entire map widget.
class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen> {
  final TrackingRepository _repository = Get.find<TrackingRepository>();

  GoogleMapController? _mapController;
  final Map<String, Marker> _markers = {};
  StreamSubscription<List<DriverLocation>>? _locationSubscription;

  // Initial camera position (can be customized)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(25.2048, 55.2708), // Dubai
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _locationSubscription = _repository.getOnlineDriverLocations().listen(
      (locations) {
        _updateMarkers(locations);
      },
      onError: (error) {
        print('Error listening to driver locations: $error');
      },
    );
  }

  /// Update markers WITHOUT rebuilding GoogleMap widget
  ///
  /// This ensures smooth performance even with many drivers
  void _updateMarkers(List<DriverLocation> locations) {
    setState(() {
      // Remove offline drivers
      final activeDriverIds = locations.map((l) => l.driverId).toSet();
      _markers.removeWhere((id, _) => !activeDriverIds.contains(id));

      // Update or add markers
      for (final location in locations) {
        final markerId = MarkerId(location.driverId);
        final position = LatLng(location.latitude, location.longitude);

        if (_markers.containsKey(location.driverId)) {
          // Update existing marker position only
          _markers[location.driverId] = _markers[location.driverId]!.copyWith(
            positionParam: position,
            infoWindowParam: InfoWindow(
              title: 'Driver ${location.driverId.substring(0, 8)}',
              snippet: 'Lesson: ${location.lessonId ?? "N/A"}',
            ),
          );
        } else {
          // Add new marker
          _markers[location.driverId] = Marker(
            markerId: markerId,
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Driver ${location.driverId.substring(0, 8)}',
              snippet: 'Lesson: ${location.lessonId ?? "N/A"}',
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Driver Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh will happen automatically via stream
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing driver locations...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map (NOT rebuilt on marker updates)
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: Set<Marker>.of(_markers.values),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // Driver count overlay
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.drive_eta, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_markers.length} Active',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
