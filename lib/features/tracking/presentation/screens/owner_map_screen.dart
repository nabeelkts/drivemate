import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mds/constants/colors.dart';
import 'package:mds/features/tracking/data/repositories/tracking_repository.dart';
import 'package:mds/features/tracking/domain/entities/driver_location.dart';
import 'package:mds/controller/workspace_controller.dart';

/// Owner dashboard — Uber-style real-time driver tracking
/// with persistent path history loaded from Firestore
class OwnerMapScreen extends StatefulWidget {
  const OwnerMapScreen({super.key});

  @override
  State<OwnerMapScreen> createState() => _OwnerMapScreenState();
}

class _OwnerMapScreenState extends State<OwnerMapScreen>
    with TickerProviderStateMixin {
  final TrackingRepository _repository = Get.find<TrackingRepository>();
  final WorkspaceController _workspaceController =
      Get.find<WorkspaceController>();

  GoogleMapController? _mapController;

  final Map<String, Marker> _markers = {};

  // Two trail sources per driver:
  // _historicalTrails  — loaded once from Firestore on lesson detect
  // _liveTrails        — accumulated from real-time RTDB updates this session
  final Map<String, List<LatLng>> _historicalTrails = {};
  final Map<String, List<_TrailPoint>> _liveTrails = {};

  final Map<String, _MarkerAnimation> _animations = {};
  final Map<String, DriverLocation> _driverData = {};
  final Map<String, String?> _knownLessonIds = {}; // driverId -> lessonId
  final Map<String, StreamSubscription> _pathSubscriptions = {};

  BitmapDescriptor? _carIconLight;
  BitmapDescriptor? _carIconDark;
  final Set<Polyline> _polylines = {};

  Timer? _animationTimer;
  Timer? _trailRebuildTimer;

  bool _isLocationGranted = false;
  bool _hasInitialCameraPosition = false;
  String? _followingDriverId;
  bool _lastDarkMode = false;

  StreamSubscription<List<DriverLocation>>? _locationSubscription;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(25.2048, 55.2708),
    zoom: 14,
  );

  static const int _maxLiveTrailPoints = 200;
  static const int _trailSegments = 24;

  static const String _darkStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1a1a2e"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#16213e"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [{"color": "#b0d5ce"}]},
  {"featureType": "transit.line", "elementType": "geometry.fill", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "transit.station", "elementType": "geometry", "stylers": [{"color": "#3a4762"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
  ''';

  @override
  void initState() {
    super.initState();
    _buildCarIcons();
    _checkPermission();
    _startListening();
    _startAnimationLoop();
    _startTrailRebuildLoop();
  }

  // ── Car icons ─────────────────────────────────────────────────────────────

  Future<void> _buildCarIcons() async {
    _carIconLight = await _renderCarIcon(const Color(0xFF1976D2));
    _carIconDark = await _renderCarIcon(const Color(0xFF00D4AA));
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _renderCarIcon(Color color) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    const cx = size / 2;
    const cy = size / 2;

    paint.color = color.withOpacity(0.15);
    canvas.drawCircle(const Offset(cx, cy), size * 0.46, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(cx, cy), size * 0.38, paint);
    paint.color = color;
    canvas.drawCircle(const Offset(cx, cy), size * 0.34, paint);

    paint.color = Colors.white;
    canvas.drawPath(
      Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(cx, cy + size * 0.05),
              width: size * 0.30,
              height: size * 0.38),
          const Radius.circular(5),
        ))
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: const Offset(cx, cy - size * 0.06),
              width: size * 0.22,
              height: size * 0.22),
          const Radius.circular(4),
        )),
      paint,
    );

    paint.color = color.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: const Offset(cx, cy - size * 0.10),
            width: size * 0.17,
            height: size * 0.12),
        const Radius.circular(3),
      ),
      paint,
    );

    paint.color = Colors.white.withOpacity(0.95);
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - size * 0.30)
        ..lineTo(cx - size * 0.07, cy - size * 0.18)
        ..lineTo(cx + size * 0.07, cy - size * 0.18)
        ..close(),
      paint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _iconFor(bool isDark) =>
      (isDark ? _carIconDark : _carIconLight) ??
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  void _refreshAllMarkerIcons(bool isDark) {
    final icon = _iconFor(isDark);
    setState(() {
      _markers.updateAll((_, m) => m.copyWith(iconParam: icon));
    });
  }

  // ── Path loading from Firestore ───────────────────────────────────────────

  /// Called whenever a driver's lessonId changes.
  /// Loads all historical points from Firestore, then subscribes
  /// to new points in real-time so the trail stays up-to-date
  /// even if the owner just opened the map mid-lesson.
  Future<void> _loadAndSubscribePath(String driverId, String lessonId) async {
    // Cancel any existing subscription for this driver
    await _pathSubscriptions[driverId]?.cancel();
    _historicalTrails[driverId] = [];
    _liveTrails[driverId] = [];

    try {
      // 1. Load all existing points in one batch
      final snapshot = await FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(lessonId)
          .collection('points')
          .orderBy('timestamp')
          .get();

      final historical = snapshot.docs.map((doc) {
        final d = doc.data();
        return LatLng(
          (d['lat'] as num).toDouble(),
          (d['lng'] as num).toDouble(),
        );
      }).toList();

      if (mounted) {
        setState(() => _historicalTrails[driverId] = historical);
      }

      // 2. Subscribe to new points added after our last fetch
      // Use the last doc as a cursor so we don't re-load everything
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      Query query = FirebaseFirestore.instance
          .collection('lesson_paths')
          .doc(lessonId)
          .collection('points')
          .orderBy('timestamp');

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      _pathSubscriptions[driverId] = query.snapshots().listen((snap) {
        if (!mounted) return;
        final newPoints = snap.docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return LatLng(
            (d['lat'] as num).toDouble(),
            (d['lng'] as num).toDouble(),
          );
        }).toList();

        if (newPoints.isNotEmpty) {
          setState(() {
            _historicalTrails[driverId] ??= [];
            _historicalTrails[driverId]!.addAll(newPoints);
          });
        }
      });

      print(
          'Loaded ${historical.length} historical points for lesson $lessonId');
    } catch (e) {
      print('Error loading lesson path: $e');
    }
  }

  // ── Animation loops ───────────────────────────────────────────────────────

  void _startAnimationLoop() {
    _animationTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void _startTrailRebuildLoop() {
    _trailRebuildTimer = Timer.periodic(
        const Duration(milliseconds: 500), (_) => _rebuildTrails());
  }

  void _tick() {
    if (_animations.isEmpty) return;
    final now = DateTime.now();
    final done = <String>[];

    for (final entry in _animations.entries) {
      final id = entry.key;
      final anim = entry.value;
      final t = (now.difference(anim.startTime).inMilliseconds /
              anim.duration.inMilliseconds)
          .clamp(0.0, 1.0);
      final e = _easeInOut(t);

      _updateMarkerPosition(
        id,
        LatLng(
          anim.start.latitude + (anim.end.latitude - anim.start.latitude) * e,
          anim.start.longitude +
              (anim.end.longitude - anim.start.longitude) * e,
        ),
        _lerpAngle(anim.startRotation, anim.endRotation, e),
      );
      if (t >= 1.0) done.add(id);
    }
    for (final k in done) _animations.remove(k);

    if (_followingDriverId != null &&
        _markers.containsKey(_followingDriverId)) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(_markers[_followingDriverId]!.position),
      );
    }

    if (mounted) setState(() {});
  }

  /// Merge historical (Firestore) + live (RTDB session) into fading polylines
  void _rebuildTrails() {
    if (!mounted) return;
    final newPolylines = <Polyline>{};

    final allDriverIds = {
      ..._historicalTrails.keys,
      ..._liveTrails.keys,
    };

    for (final driverId in allDriverIds) {
      // Merge: historical first, then live (deduplicate nearby points)
      final historical = _historicalTrails[driverId] ?? [];
      final live =
          (_liveTrails[driverId] ?? []).map((p) => p.position).toList();

      // Combine — live points after last historical point
      List<LatLng> allPoints;
      if (historical.isEmpty) {
        allPoints = live;
      } else if (live.isEmpty) {
        allPoints = historical;
      } else {
        // Avoid duplicating the junction point
        final lastHist = historical.last;
        final liveUnique =
            live.where((p) => _calcDistance(lastHist, p) > 1.0).toList();
        allPoints = [...historical, ...liveUnique];
      }

      // Build polylines even with just 2 points (minimum needed for a line)
      if (allPoints.length < 2) continue;

      final segSize = (allPoints.length / _trailSegments).ceil().clamp(1, 9999);

      for (int s = 0; s < _trailSegments; s++) {
        final start = s * segSize;
        final end = ((s + 1) * segSize).clamp(0, allPoints.length);
        if (start >= allPoints.length - 1) break;

        final points = allPoints.sublist(start, end);
        if (points.length < 2) continue;

        // Older segments are fainter and thinner — Uber style fade
        final opacity = 0.05 + (s / _trailSegments) * 0.68;
        final width = (1.0 + (s / _trailSegments) * 4.0).round();

        newPolylines.add(Polyline(
          polylineId: PolylineId('${driverId}_seg_$s'),
          points: points,
          color: kPrimaryColor.withOpacity(opacity),
          width: width,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _polylines
          ..clear()
          ..addAll(newPolylines);
      });
    }
  }

  double _easeInOut(double t) =>
      t < 0.5 ? 4 * t * t * t : 1 - math.pow(-2 * t + 2, 3) / 2;

  double _lerpAngle(double a, double b, double t) {
    double diff = b - a;
    while (diff > 180) diff -= 360;
    while (diff < -180) diff += 360;
    return a + diff * t;
  }

  void _updateMarkerPosition(String id, LatLng pos, double rot) {
    if (_markers.containsKey(id)) {
      _markers[id] =
          _markers[id]!.copyWith(positionParam: pos, rotationParam: rot);
    }
  }

  // ── Location listener ─────────────────────────────────────────────────────

  void _startListening() {
    _locationSubscription = _repository
        .getOnlineDriversForSchool(_workspaceController.targetId)
        .listen(_updateMarkers, onError: (e) => print('Map stream error: $e'));
  }

  void _updateMarkers(List<DriverLocation> locations) {
    final activeIds = locations.map((l) => l.driverId).toSet();
    final isDark = _lastDarkMode;
    final icon = _iconFor(isDark);

    setState(() {
      // Remove offline drivers and cancel their path subscriptions
      final removedIds =
          _markers.keys.where((id) => !activeIds.contains(id)).toList();
      for (final id in removedIds) {
        _pathSubscriptions[id]?.cancel();
        _pathSubscriptions.remove(id);
        _historicalTrails.remove(id);
        _liveTrails.remove(id);
        _knownLessonIds.remove(id);
      }
      _markers.removeWhere((id, _) => !activeIds.contains(id));
      _animations.removeWhere((id, _) => !activeIds.contains(id));
      _driverData.removeWhere((id, _) => !activeIds.contains(id));

      for (final loc in locations) {
        _driverData[loc.driverId] = loc;
        if (loc.latitude == 0.0 && loc.longitude == 0.0) continue;

        final pos = LatLng(loc.latitude, loc.longitude);

        // ── Detect lesson change — load Firestore path ─────────────────
        final previousLessonId = _knownLessonIds[loc.driverId];
        final currentLessonId = loc.lessonId;
        if (currentLessonId != null && currentLessonId != previousLessonId) {
          _knownLessonIds[loc.driverId] = currentLessonId;
          // Load outside setState (async)
          Future.microtask(
              () => _loadAndSubscribePath(loc.driverId, currentLessonId));
        } else if (currentLessonId == null && previousLessonId != null) {
          // Lesson ended — keep the trail visible but stop updating
          _knownLessonIds[loc.driverId] = null;
          _pathSubscriptions[loc.driverId]?.cancel();
        }

        // ── Update live trail ─────────────────────────────────────────
        _liveTrails.putIfAbsent(loc.driverId, () => []);
        final live = _liveTrails[loc.driverId]!;
        // Reduced threshold from 1.0 to 0.5 meters for more accurate tracking
        if (live.isEmpty || _calcDistance(live.last.position, pos) > 0.5) {
          live.add(_TrailPoint(position: pos, timestamp: DateTime.now()));
          if (live.length > _maxLiveTrailPoints) live.removeAt(0);
        }

        final driverName =
            loc.driverName ?? 'Driver ${loc.driverId.substring(0, 6)}';

        if (_markers.containsKey(loc.driverId)) {
          final dist = _calcDistance(_markers[loc.driverId]!.position, pos);
          if (dist > 0.5) {
            _animations[loc.driverId] = _MarkerAnimation(
              start: _markers[loc.driverId]!.position,
              end: pos,
              startRotation: _markers[loc.driverId]!.rotation,
              endRotation: loc.heading,
              startTime: DateTime.now(),
              duration: const Duration(milliseconds: 1200),
            );
          } else {
            _markers[loc.driverId] =
                _markers[loc.driverId]!.copyWith(rotationParam: loc.heading);
          }
        } else {
          _markers[loc.driverId] = Marker(
            markerId: MarkerId(loc.driverId),
            position: pos,
            rotation: loc.heading,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            zIndex: 2,
            onTap: () => _onDriverTap(loc.driverId),
            infoWindow: InfoWindow(
              title: driverName,
              snippet: loc.lessonId != null
                  ? '📚 In Lesson'
                  : '${(loc.speed * 3.6).toStringAsFixed(1)} km/h',
            ),
          );
        }
      }
    });

    if (!_hasInitialCameraPosition && _markers.isNotEmpty) {
      _hasInitialCameraPosition = true;
      Future.delayed(const Duration(milliseconds: 800), _fitBounds);
    }
  }

  void _onDriverTap(String driverId) {
    setState(() {
      _followingDriverId = _followingDriverId == driverId ? null : driverId;
    });
    if (_followingDriverId != null && _markers.containsKey(driverId)) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_markers[driverId]!.position, 17),
      );
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty || _mapController == null) return;
    if (_markers.length == 1) {
      _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_markers.values.first.position, 16));
      return;
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final m in _markers.values) {
      if (m.position.latitude < minLat) minLat = m.position.latitude;
      if (m.position.latitude > maxLat) maxLat = m.position.latitude;
      if (m.position.longitude < minLng) minLng = m.position.longitude;
      if (m.position.longitude > maxLng) maxLng = m.position.longitude;
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      80,
    ));
  }

  Future<void> _checkPermission() async {
    final granted = await Permission.location.isGranted;
    if (mounted) setState(() => _isLocationGranted = granted);
  }

  double _calcDistance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final sa = math.sin(dLat / 2);
    final sb = math.sin(dLng / 2);
    final c = sa * sa +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            sb *
            sb;
    return R * 2 * math.atan2(math.sqrt(c), math.sqrt(1 - c));
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _animationTimer?.cancel();
    _trailRebuildTimer?.cancel();
    for (final sub in _pathSubscriptions.values) sub.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark != _lastDarkMode) {
      _lastDarkMode = isDark;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController?.setMapStyle(isDark ? _darkStyle : null);
        _refreshAllMarkerIcons(isDark);
      });
    }

    final bgColor = isDark ? const Color(0xFF0e1626) : Colors.grey.shade100;
    final cardColor =
        isDark ? const Color(0xFF1a1a2e).withOpacity(0.95) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.07);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black45;
    final pillBg = isDark
        ? const Color(0xFF1a1a2e).withOpacity(0.92)
        : Colors.white.withOpacity(0.95);
    final accentColor = isDark ? const Color(0xFF00D4AA) : kPrimaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: Set<Marker>.of(_markers.values),
            polylines: _polylines,
            myLocationEnabled: _isLocationGranted,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            compassEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(isDark ? _darkStyle : null);
            },
            onTap: (_) {
              if (_followingDriverId != null) {
                setState(() => _followingDriverId = null);
              }
            },
          ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _GlassPill(
                  bg: pillBg,
                  border: borderColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _markers.isEmpty
                              ? Colors.grey.shade400
                              : accentColor,
                          shape: BoxShape.circle,
                          boxShadow: _markers.isEmpty
                              ? []
                              : [
                                  BoxShadow(
                                    color: accentColor.withOpacity(0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  )
                                ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onLongPress: () => Get.snackbar(
                          'Diagnostics',
                          'Target: ${_workspaceController.targetId}\n'
                              'Online: ${_markers.length}',
                          backgroundColor: accentColor.withOpacity(0.9),
                          colorText: Colors.black,
                          duration: const Duration(seconds: 4),
                        ),
                        child: Text(
                          _markers.isEmpty
                              ? 'No Active Staff'
                              : '${_markers.length} Active Staff',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_followingDriverId != null) ...[
                  const SizedBox(width: 8),
                  _GlassPill(
                    bg: accentColor.withOpacity(0.12),
                    border: accentColor.withOpacity(0.3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded,
                            size: 13, color: accentColor),
                        const SizedBox(width: 5),
                        Text(
                          _driverData[_followingDriverId]?.driverName ??
                              'Following',
                          style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                _CircleButton(
                  icon: Icons.fit_screen_rounded,
                  bg: pillBg,
                  border: borderColor,
                  iconColor: accentColor,
                  onTap: () {
                    setState(() => _followingDriverId = null);
                    _fitBounds();
                  },
                ),
              ],
            ),
          ),

          // ── Driver cards ─────────────────────────────────────────────────
          if (_driverData.isNotEmpty)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _driverData.length,
                  itemBuilder: (context, i) {
                    final id = _driverData.keys.elementAt(i);
                    final driver = _driverData.values.elementAt(i);
                    final isFollowing = _followingDriverId == id;
                    final name = driver.driverName ?? 'Driver ${i + 1}';
                    final speedKmh = driver.speed * 3.6;
                    final distKm = (driver.lessonDistance > 0
                            ? driver.lessonDistance
                            : driver.totalDistance) /
                        1000;
                    final pathCount = (_historicalTrails[id]?.length ?? 0) +
                        (_liveTrails[id]?.length ?? 0);

                    return GestureDetector(
                      onTap: () => _onDriverTap(id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 185,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isFollowing
                              ? accentColor.withOpacity(0.12)
                              : cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isFollowing ? accentColor : borderColor,
                            width: isFollowing ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isFollowing
                                  ? accentColor.withOpacity(0.15)
                                  : Colors.black
                                      .withOpacity(isDark ? 0.4 : 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isFollowing)
                                  Icon(Icons.near_me_rounded,
                                      size: 13, color: accentColor),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.speed_rounded,
                                  value: '${speedKmh.toStringAsFixed(0)} km/h',
                                  color: subTextColor,
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  icon: Icons.route_rounded,
                                  value: '${distKm.toStringAsFixed(2)} km',
                                  color: subTextColor,
                                ),
                              ],
                            ),
                            if (driver.lessonId != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '📚 In Lesson',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.shade600,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // ✅ Show how many path points loaded
                                  if (pathCount > 0)
                                    Text(
                                      '$pathCount pts',
                                      style: TextStyle(
                                          fontSize: 9, color: subTextColor),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Empty state ───────────────────────────────────────────────────
          if (_markers.isEmpty)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                margin: const EdgeInsets.symmetric(horizontal: 48),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
                      blurRadius: 30,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.directions_car_rounded,
                          size: 40, color: accentColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Staff Online',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Staff will appear here when\nthey start a lesson',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: subTextColor, height: 1.5),
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

// ── Helpers ───────────────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  final Widget child;
  final Color bg, border;
  const _GlassPill(
      {required this.child, required this.bg, required this.border});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ],
        ),
        child: child,
      );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color bg, border, iconColor;
  final VoidCallback onTap;
  const _CircleButton(
      {required this.icon,
      required this.bg,
      required this.border,
      required this.iconColor,
      required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatChip(
      {required this.icon, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      );
}

class _TrailPoint {
  final LatLng position;
  final DateTime timestamp;
  _TrailPoint({required this.position, required this.timestamp});
}

class _MarkerAnimation {
  final LatLng start, end;
  final double startRotation, endRotation;
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
