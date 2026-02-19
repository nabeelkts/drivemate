import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/controller/permission_controller.dart';
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
  final Map<String, List<LatLng>> _driverPaths = {};
  final Map<String, _MarkerAnimation> _animations = {};
  Timer? _animationTimer;
  BitmapDescriptor? _carIcon;

  bool _isLocationGranted = false;
  bool _hasInitialCameraPosition = false;
  StreamSubscription<List<DriverLocation>>? _locationSubscription;

  // Initial camera position (can be customized)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(25.2048, 55.2708), // Dubai
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadCarIcon();
    _checkPermission();
    _startListening();
    _startAnimationLoop();
  }

  Future<void> _loadCarIcon() async {
    try {
      // Load custom car icon (using vehicle_rc as car icon)
      _carIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/icons/vehicle_rc.png',
      );
      setState(() {});
    } catch (e) {
      print('Error loading car icon: $e');
    }
  }

  void _startAnimationLoop() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _animateMarkers();
    });
  }

  void _animateMarkers() {
    if (_animations.isEmpty) return;

    bool needsUpdate = false;
    final now = DateTime.now();

    _animations.removeWhere((driverId, anim) {
      final elapsed = now.difference(anim.startTime).inMilliseconds;
      final duration = anim.duration.inMilliseconds;

      if (elapsed >= duration) {
        // Animation complete
        _updateMarkerPosition(driverId, anim.end, anim.endRotation);
        return true;
      }

      final t = elapsed / duration;
      final lat =
          anim.start.latitude + (anim.end.latitude - anim.start.latitude) * t;
      final lng = anim.start.longitude +
          (anim.end.longitude - anim.start.longitude) * t;
      final rotation = _lerpRotation(anim.startRotation, anim.endRotation, t);

      _updateMarkerPosition(driverId, LatLng(lat, lng), rotation);
      needsUpdate = true;
      return false;
    });

    if (needsUpdate) {
      setState(() {});
    }
  }

  double _lerpRotation(double start, double end, double t) {
    double diff = end - start;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return start + diff * t;
  }

  void _updateMarkerPosition(
      String driverId, LatLng position, double rotation) {
    if (_markers.containsKey(driverId)) {
      _markers[driverId] = _markers[driverId]!.copyWith(
        positionParam: position,
        rotationParam: rotation,
      );
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null) return;

    if (_markers.length == 1) {
      final position = _markers.values.first.position;
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 15));
      return;
    }

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;

    for (final marker in _markers.values) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng)
        minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng)
        maxLng = marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.location.isGranted;
    if (mounted) {
      setState(() {
        _isLocationGranted = granted;
      });
    }
  }

  void _startListening() {
    _locationSubscription = _repository.getOnlineDriverLocations().listen(
      (locations) {
        print('OwnerMapScreen received ${locations.length} locations');
        _updateMarkers(locations);
      },
      onError: (error) {
        print('Error listening to driver locations: $error');
      },
    );
  }

  /// Update markers with smooth animation
  void _updateMarkers(List<DriverLocation> locations) {
    final activeDriverIds = locations.map((l) => l.driverId).toSet();

    // Remove offline drivers
    setState(() {
      _markers.removeWhere((id, _) => !activeDriverIds.contains(id));
      _driverPaths.removeWhere((id, _) => !activeDriverIds.contains(id));
      _animations.removeWhere((id, _) => !activeDriverIds.contains(id));
    });

    for (final location in locations) {
      final position = LatLng(location.latitude, location.longitude);

      // Update path
      if (!_driverPaths.containsKey(location.driverId)) {
        _driverPaths[location.driverId] = [];
      }
      _driverPaths[location.driverId]!.add(position);

      if (_markers.containsKey(location.driverId)) {
        // Animate to new position
        final currentMarker = _markers[location.driverId]!;
        final startPos = currentMarker.position;
        final startRot = currentMarker.rotation;

        _animations[location.driverId] = _MarkerAnimation(
          start: startPos,
          end: position,
          startRotation: startRot,
          endRotation: location.heading,
          startTime: DateTime.now(),
          duration: const Duration(milliseconds: 1000),
        );
      } else {
        // Add new marker immediately
        final markerId = MarkerId(location.driverId);
        _markers[location.driverId] = Marker(
          markerId: markerId,
          position: position,
          rotation: location.heading,
          icon: _carIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5), // Center the icon
          infoWindow: InfoWindow(
            title: 'Driver ${location.driverId.substring(0, 8)}',
            snippet: 'Lesson: ${location.lessonId ?? "N/A"}',
          ),
        );
        setState(() {});
      }
    }

    // Initial camera fit
    if (!_hasInitialCameraPosition && _markers.isNotEmpty) {
      _hasInitialCameraPosition = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        _fitBounds();
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _animationTimer?.cancel();
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
              _fitBounds();
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
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: Set<Marker>.of(_markers.values),
            polylines: _driverPaths.entries.map((entry) {
              return Polyline(
                polylineId: PolylineId(entry.key),
                points: entry.value,
                color: kPrimaryColor,
                width: 4,
              );
            }).toSet(),
            myLocationEnabled: _isLocationGranted,
            myLocationButtonEnabled: _isLocationGranted,
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),

          // Driver count overlay
          Positioned(
            top: 16,
            left: 16, // Moved to left
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
              child: StreamBuilder<List<DriverLocation>>(
                stream: _repository.getOnlineDriverLocations(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$count Active Drivers',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (snapshot.hasError)
                        Text(
                          'Error: ${snapshot.error}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 10),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerAnimation {
  final LatLng start;
  final LatLng end;
  final double startRotation;
  final double endRotation;
  final DateTime startTime;
  final Duration duration;

  _MarkerAnimation({
    required this.start,
    required this.end,
    required this.startRotation,
    required this.endRotation,
    required this.startTime,
    required this.duration,
  });
}
