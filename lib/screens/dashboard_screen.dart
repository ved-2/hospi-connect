import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;

import '../models/emergency_model.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

// --- Design System Colors ---
class AppColors {
  static const Color background = Color(0xFF0F172A); // Deep Slate
  static const Color surface = Color(0xFF1E293B); // Elevated Slate
  static const Color surfaceLight = Color(0xFF334155);
  static const Color primaryRed = Color(0xFFEF4444); // Urgent Alert
  static const Color successGreen = Color(0xFF10B981); // Active/Safe
  static const Color accentBlue = Color(0xFF3B82F6); // Routes & Highlights
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
}

class DashboardScreen extends StatefulWidget {
  final String ambulanceId;
  final String driverName;
  final String uid;

  static final StreamController<String> logController =
      StreamController<String>.broadcast();
  static final Set<String> completedTrips = {};
  static void log(String msg) {
    debugPrint('DEBUG: $msg');
    logController.add(msg);
  }

  const DashboardScreen({
    super.key,
    required this.ambulanceId,
    required this.driverName,
    required this.uid,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  StreamSubscription? _pendingSubscription;
  StreamSubscription? _locationSubscription;
  StreamSubscription? _ambulanceSubscription;
  StreamSubscription? _debugLogSubscription;
  final List<String> _debugLogs = [];
  late String _currentAmbulanceId;

  ll.LatLng? _currentLocation;
  final Map<String, ll.LatLng> _ambulanceLocations = {};
  List<ll.LatLng> _routePointsLeg1 = [];
  List<ll.LatLng> _routePointsLeg2 = [];
  String? _etaText;

  EmergencyModel? _activeEmergency;
  Hospital? _targetHospital; // The hospital with most beds & best match
  String? _toPatientEta;
  String? _toHospitalEta;
  double _distMetersLeg1 = 0;
  double _distMetersLeg2 = 0;
  int _secondsLeg1 = 0;
  int _secondsLeg2 = 0;
  final Set<String> _shownDialogs = {};
  final MapController _mapController = MapController();
  bool _isUpdatingEmergencyStatus = false;

  static const double _maxDistanceMeters =
      50000000; // Practically unlimited for demo

  @override
  void initState() {
    super.initState();
    _currentAmbulanceId = widget.ambulanceId;
    _debugLogSubscription = DashboardScreen.logController.stream.listen((msg) {
      if (mounted) setState(() => _debugLogs.insert(0, msg));
    });
    DashboardScreen.log(
        'Init Dashboard for $_currentAmbulanceId (UID: ${widget.uid})');
    _firebaseService.updateAmbulanceStatus(
        widget.uid, false); // Use UID consistently
    _startLocationService();
    _listenForAmbulanceLocations();
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _locationSubscription?.cancel();
    _ambulanceSubscription?.cancel();
    _debugLogSubscription?.cancel();
    super.dispose();
  }

  void _startLocationService() async {
    DashboardScreen.log('Starting Location Service...');
    _currentLocation = await _locationService.getCurrentLocation();
    if (_currentLocation != null && mounted) {
      DashboardScreen.log(
          'Initial location found: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      setState(() {});
      _firebaseService.updateAmbulanceLocation(widget.uid, _currentLocation!);
    } else {
      DashboardScreen.log('Initial location search returned null.');
    }

    DashboardScreen.log('Subscribing to live location stream...');
    // Restore active mission if exists
    _restoreActiveMission();

    _locationSubscription = _locationService.getLocationStream().listen((loc) {
      if (mounted) {
        setState(() => _currentLocation = loc);
        _firebaseService.updateAmbulanceLocation(widget.uid, loc);

        if (_activeEmergency != null) {
          final isPatientOnboard = _activeEmergency!.status.index >=
              EmergencyStatus.patientOnboard.index;
          if (isPatientOnboard) {
            if (_activeEmergency!.hospitalLat != null) {
              _fetchLeg1(
                  loc,
                  ll.LatLng(_activeEmergency!.hospitalLat!,
                      _activeEmergency!.hospitalLng!));
              // Clear Leg 2 once patient is onboard to avoid overlapping lines
              if (_routePointsLeg2.isNotEmpty) {
                setState(() => _routePointsLeg2 = []);
              }
            }
          } else {
            _fetchLeg1(
                loc,
                ll.LatLng(
                    _activeEmergency!.latitude, _activeEmergency!.longitude));
          }
        }
      }
    });

    _listenForEmergencies();
  }

  Future<void> _restoreActiveMission() async {
    final active =
        await _firebaseService.getActiveEmergencyForDriver(_currentAmbulanceId);
    if (active != null && mounted) {
      DashboardScreen.log('Restoring active mission: ${active.id}');
      Hospital? hospital;
      if (active.hospitalId != null) {
        hospital = await _firebaseService.getHospitalById(active.hospitalId!);
      }

      setState(() {
        _activeEmergency = active;
        _targetHospital = hospital;
      });

      if (_currentLocation != null) {
        _fetchLeg1(
            _currentLocation!, ll.LatLng(active.latitude, active.longitude));
        if (active.hospitalLat != null) {
          _fetchLeg2(ll.LatLng(active.latitude, active.longitude),
              ll.LatLng(active.hospitalLat!, active.hospitalLng!));
        }
      }
    }
  }

  void _fitRouteBounds() {
    final allPoints = [..._routePointsLeg1, ..._routePointsLeg2];
    if (allPoints.isEmpty) return;

    var minLat = allPoints[0].latitude;
    var maxLat = allPoints[0].latitude;
    var minLng = allPoints[0].longitude;
    var maxLng = allPoints[0].longitude;

    for (var p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          ll.LatLng(minLat, minLng),
          ll.LatLng(maxLat, maxLng),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _listenForEmergencies() {
    _pendingSubscription =
        _firebaseService.getPendingEmergencies().listen((emergencies) {
      // BLOCKER: If driver is currently busy with a trip, COMPLETELY IGNORE all background SOS alerts!
      if (_activeEmergency != null) {
        DashboardScreen.log(
            'Driver is currently BUSY. Ignoring incoming ${emergencies.length} emergencies.');
        return;
      }

      if (_currentLocation == null) {
        DashboardScreen.log(
            'Location is null. Evaluating emergencies without sequence blocking.');
      }

      const distance = ll.Distance();
      DashboardScreen.log(
          'Scanning ${emergencies.length} candidate emergencies...');

      final candidates = emergencies.where((e) {
        if (_shownDialogs.contains(e.id)) return false;
        if (e.ambulanceId != null && e.ambulanceId!.isNotEmpty) {
          DashboardScreen.log(
              'Skipping ${e.id}: Already assigned to ${e.ambulanceId}');
          return false;
        }
        // Removed local clock sync requirement - rely on the 15min global backend filter!

        double meters = 0;
        if (_currentLocation != null) {
          meters = distance(
            _currentLocation!,
            ll.LatLng(e.latitude, e.longitude),
          );
        }

        bool inRange = meters <= _maxDistanceMeters;
        if (!inRange) {
          DashboardScreen.log(
              'Skipping ${e.id}: Out of range (${meters.toStringAsFixed(0)}m)');
          return false;
        }

        // Check if I am the absolutely nearest IDLE ambulance for this emergency
        if (_currentLocation != null) {
          bool isNearest =
              _isNearestAmbulanceForEmergency(e, _currentLocation!);
          if (!isNearest) {
            DashboardScreen.log(
                'Skipping ${e.id}: Another idle ambulance is closer.');
            return false;
          }
        }

        return true;
      }).toList();

      if (candidates.isEmpty) return;

      // Sort purely by time, newest first, ignoring distance!
      // This ensures ONLY the SOS the citizen just submitted pops up.
      candidates.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      // Mark all candidates as shown immediately to prevent older pending ones
      // from popping up one-by-one sequentially after we close this dialog.
      for (var e in candidates) {
        _shownDialogs.add(e.id);
      }

      final newestAlert = candidates.first;
      DashboardScreen.log('Showing Newest Emergency ${newestAlert.id}');

      _showEmergencyDialog(newestAlert);
    });
  }

  void _listenForAmbulanceLocations() {
    _ambulanceSubscription =
        _firebaseService.getAmbulanceLocations().listen((locations) {
      _ambulanceLocations
        ..clear()
        ..addAll(locations);
    });
  }

  bool _isNearestAmbulanceForEmergency(
      EmergencyModel emergency, ll.LatLng myLocation) {
    if (_ambulanceLocations.isEmpty) {
      DashboardScreen.log(
          'Targeting: No other ambulances found in registry. I am the only candidate.');
      return true;
    }

    final target = ll.LatLng(emergency.latitude, emergency.longitude);
    const distance = ll.Distance();

    var nearestDistance = distance(myLocation, target);

    DashboardScreen.log(
        'Self check: $_currentAmbulanceId is ${nearestDistance.toStringAsFixed(1)}m from target.');

    bool someoneElseIsCloser = false;
    String closerId = '';
    double closerDist = 0;

    _ambulanceLocations.forEach((id, loc) {
      if (id == widget.uid) return; // FIX: Correctly exclude self using UID

      final d = distance(loc, target);
      // Added a 5-meter tolerance to favor the ACTIVE driver in case of stale/identical demo data
      if (d < (nearestDistance - 5)) {
        someoneElseIsCloser = true;
        closerId = id;
        closerDist = d;
      }
    });

    if (someoneElseIsCloser) {
      DashboardScreen.log(
          'NEAREST CHECK FAILED: Ambulance $closerId is closer (${closerDist.toStringAsFixed(1)}m) than me (${nearestDistance.toStringAsFixed(1)}m)');
      return false;
    }

    DashboardScreen.log(
        'NEAREST CHECK PASSED: I am the closest available unit.');
    return true;
  }

  Future<void> _fetchLeg1(ll.LatLng start, ll.LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          final double distance = (route['distance'] as num).toDouble();
          final double duration = (route['duration'] as num).toDouble();
          if (mounted) {
            setState(() {
              _routePointsLeg1 = coordinates
                  .map((c) => ll.LatLng(c[1] as double, c[0] as double))
                  .toList();

              _distMetersLeg1 = distance;
              _secondsLeg1 = duration.round();

              bool isPatientOnboard = _activeEmergency != null &&
                  _activeEmergency!.status.index >=
                      EmergencyStatus.patientOnboard.index;

              if (isPatientOnboard) {
                _toHospitalEta = _formatDuration(_secondsLeg1);
                _toPatientEta = "Arrived";
              } else {
                _toPatientEta = _formatDuration(_secondsLeg1);
                // Total duration to hospital via patient
                _toHospitalEta = _formatDuration(_secondsLeg1 + _secondsLeg2);
              }
            });
            _fitRouteBounds();
          }
        }
      }
    } catch (e) {
      DashboardScreen.log('Error fetching leg 1: $e');
    }
  }

  Future<void> _fetchLeg2(ll.LatLng start, ll.LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;
          if (mounted) {
            setState(() {
              _routePointsLeg2 = coordinates
                  .map((c) => ll.LatLng(c[1] as double, c[0] as double))
                  .toList();
              _distMetersLeg2 = (route['distance'] as num).toDouble();
              _secondsLeg2 = (route['duration'] as num).round();
              _toHospitalEta = _formatDuration(_secondsLeg1 + _secondsLeg2);
            });
            _fitRouteBounds();
          }
        }
      }
    } catch (e) {
      DashboardScreen.log('Error fetching leg 2: $e');
    }
  }

  void _showEmergencyDialog(EmergencyModel emergency) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              elevation: 24,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: AppColors.primaryRed.withValues(alpha: 0.3),
                    width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: AppColors.primaryRed, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                      child: Text('EMERGENCY SOS',
                          style: TextStyle(
                              color: AppColors.primaryRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.surfaceLight),
                  const SizedBox(height: 12),
                  _infoRow(
                      Icons.person_rounded, 'Patient', emergency.patientName),
                  const SizedBox(height: 16),
                  _infoRow(Icons.monitor_heart_rounded, 'Condition',
                      emergency.symptoms,
                      isHighlight: true),
                  const SizedBox(height: 16),
                  _infoRow(Icons.location_on_rounded, 'Location',
                      emergency.location),
                ],
              ),
              actionsPadding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 20, top: 8),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('DECLINE',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          // Extract numeric minutes from _etaText (e.g. "15 min" -> 15)
                          int? estimatedMinutes;
                          if (_etaText != null) {
                            final match =
                                RegExp(r'(\d+)').firstMatch(_etaText!);
                            if (match != null) {
                              estimatedMinutes = int.tryParse(match.group(1)!);
                            }
                          }

                          // 1. Identify best hospital based on symptoms and proximity
                          final req =
                              DiseaseMapper.getRequirements(emergency.symptoms);
                          final hospitals =
                              await _firebaseService.fetchHospitals(req,
                                  userLocation: ll.LatLng(
                                      emergency.latitude, emergency.longitude));
                          final bestHospital =
                              hospitals.isNotEmpty ? hospitals.first : null;

                          await _firebaseService.acceptEmergency(
                            emergency.id,
                            _currentAmbulanceId,
                            eta: estimatedMinutes,
                          );

                          // Update emergency with hospital info
                          if (bestHospital != null) {
                            await FirebaseFirestore.instance
                                .collection('emergencies')
                                .doc(emergency.id)
                                .update({
                              'hospitalId': bestHospital.id,
                              'hospitalName': bestHospital.name,
                              'hospitalAddress': bestHospital.address,
                              'hospitalLat': bestHospital.latitude,
                              'hospitalLng': bestHospital.longitude,
                            });
                          }

                          await _firebaseService.updateAmbulanceStatus(
                              widget.uid, true);

                          final updatedEmergency = emergency.copyWith(
                            status: EmergencyStatus.accepted,
                            eta: estimatedMinutes,
                            hospitalId: bestHospital?.id,
                            hospitalName: bestHospital?.name,
                            hospitalAddress: bestHospital?.address,
                            hospitalLat: bestHospital?.latitude,
                            hospitalLng: bestHospital?.longitude,
                          );

                          setState(() {
                            _targetHospital = bestHospital;
                            _activeEmergency = updatedEmergency;
                          });

                          if (_currentLocation != null) {
                            _fetchLeg1(
                                _currentLocation!,
                                ll.LatLng(updatedEmergency.latitude,
                                    updatedEmergency.longitude));
                            if (updatedEmergency.hospitalLat != null) {
                              _fetchLeg2(
                                  ll.LatLng(updatedEmergency.latitude,
                                      updatedEmergency.longitude),
                                  ll.LatLng(updatedEmergency.hospitalLat!,
                                      updatedEmergency.hospitalLng!));
                            }
                          }
                        },
                        child: const Text('ACCEPT',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ),
                  ],
                )
              ],
            ));
  }

  Widget _infoRow(IconData icon, String label, String value,
      {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon,
              size: 20,
              color:
                  isHighlight ? AppColors.primaryRed : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: isHighlight
                        ? AppColors.primaryRed
                        : AppColors.textPrimary,
                    fontSize: isHighlight ? 16 : 14,
                    height: 1.3,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Refined Professional Header ──────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primaryRed.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.emergency_rounded,
                        color: AppColors.primaryRed, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_currentAmbulanceId.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                )),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.successGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('ONLINE',
                                      style: TextStyle(
                                        color: AppColors.successGreen,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.driverName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ── Immersive Map Layout ───────────────────────────
            Expanded(
              child: _currentLocation == null
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed))
                  : Stack(
                      children: [
                        // Background Map
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentLocation!,
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.example.ambulance_app',
                            ),
                            if (_routePointsLeg2.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePointsLeg2,
                                    strokeWidth: 8.0,
                                    color: Colors.blue.withValues(alpha: 0.6),
                                    strokeCap: StrokeCap.round,
                                    strokeJoin: StrokeJoin.round,
                                  ),
                                ],
                              ),
                            if (_routePointsLeg1.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePointsLeg1,
                                    strokeWidth: 20.0, // Maximum visibility
                                    color: Colors.blueAccent,
                                    strokeCap: StrokeCap.round,
                                    strokeJoin: StrokeJoin.round,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 50,
                                  height: 50,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: const Icon(
                                        Icons.local_shipping_rounded,
                                        color: AppColors.primaryRed,
                                        size: 30),
                                  ),
                                ),
                                if (_activeEmergency != null) ...[
                                  // Patient Marker
                                  Marker(
                                    point: ll.LatLng(_activeEmergency!.latitude,
                                        _activeEmergency!.longitude),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                        Icons.person_pin_circle_rounded,
                                        color: AppColors.primaryRed,
                                        size: 40),
                                  ),
                                  // Hospital Marker (if set)
                                  if (_activeEmergency!.hospitalLat != null &&
                                      _activeEmergency!.hospitalLat != 0)
                                    Marker(
                                      point: ll.LatLng(
                                          _activeEmergency!.hospitalLat!,
                                          _activeEmergency!.hospitalLng!),
                                      width: 50,
                                      height: 50,
                                      child: const Icon(
                                          Icons.local_hospital_rounded,
                                          color: Color(0xFF3B82F6),
                                          size: 48),
                                    ),
                                ],
                              ],
                            ),
                          ],
                        ),

                        _buildTopStatusBanner(),

                        // Map Controls (Right Side)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: SizedBox(
                            width: 170,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FloatingActionButton(
                                  mini: true,
                                  heroTag: 'map_traffic',
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.textPrimary,
                                  child: const Icon(Icons.traffic_rounded,
                                      size: 20),
                                  onPressed: () {},
                                ),
                                const SizedBox(height: 12),
                                FloatingActionButton(
                                  mini: true,
                                  heroTag: 'map_center',
                                  backgroundColor: AppColors.surface,
                                  foregroundColor: AppColors.accentBlue,
                                  child: const Icon(Icons.my_location_rounded,
                                      size: 20),
                                  onPressed: () {
                                    if (_currentLocation != null) {
                                      _mapController.move(
                                          _currentLocation!, 15);
                                    }
                                  },
                                ),
                                if (_activeEmergency != null &&
                                    _nextEmergencyStatus != null) ...[
                                  const SizedBox(height: 12),
                                  FloatingActionButton.extended(
                                    heroTag: 'map_pickup_status',
                                    backgroundColor: AppColors.primaryRed,
                                    foregroundColor: Colors.white,
                                    icon: _isUpdatingEmergencyStatus
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.sync_alt_rounded),
                                    label: Text(_nextEmergencyStatusLabel),
                                    onPressed: _isUpdatingEmergencyStatus
                                        ? null
                                        : _advanceEmergencyStatus,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Expanded Trip Details (Taller for visibility)
                        _buildRichTripDetails(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
              top: BorderSide(
                  color: AppColors.surfaceLight.withValues(alpha: 0.5))),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          elevation: 0,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 11, height: 1.5),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 11, height: 1.5),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.explore_rounded), label: 'DASHBOARD'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_toggle_off_rounded), label: 'HISTORY'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'PROFILE'),
          ],
          onTap: (i) async {
            if (i == 1) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          HistoryScreen(ambulanceId: widget.ambulanceId)));
            }
            if (i == 2) {
              Navigator.push(
                  context,
                  MaterialPageRoute<String>(
                      builder: (_) => ProfileScreen(
                            uid: widget.uid,
                            driverName: widget.driverName,
                            initialAmbulanceId: _currentAmbulanceId,
                          ))).then((newId) {
                if (newId != null && mounted) {
                  setState(() => _currentAmbulanceId = newId);
                }
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildTopStatusBanner() {
    if (_activeEmergency == null) return const SizedBox.shrink();

    String statusText = "Picking up patient";
    if (_activeEmergency!.status.index >=
        EmergencyStatus.patientOnboard.index) {
      statusText = "Heading to hospital";
    }

    return Positioned(
      top: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                    fontSize: 16),
              ),
            ),
            const Icon(Icons.add_box_rounded,
                color: Color(0xFF10B981), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRichTripDetails() {
    if (_activeEmergency == null) return const SizedBox.shrink();
    bool isPatientOnboard =
        _activeEmergency!.status.index >= EmergencyStatus.patientOnboard.index;

    // Get the current action button text and callback
    String actionText = "";
    VoidCallback? onTap;
    Color buttonColor = Colors.green;

    if (_activeEmergency!.status == EmergencyStatus.accepted) {
      actionText = 'ARRIVED AT PICKUP';
      buttonColor = Colors.green;
      onTap = _advanceEmergencyStatus;
    } else if (_activeEmergency!.status == EmergencyStatus.arrived) {
      actionText = 'COMPLETE RIDE';
      buttonColor = Colors.redAccent;
      onTap = _advanceEmergencyStatus;
    } else if (_activeEmergency!.status == EmergencyStatus.patientOnboard) {
      actionText = 'COMPLETE RIDE';
      buttonColor = Colors.redAccent;
      onTap = _advanceEmergencyStatus;
    }

    if (onTap == null) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            // Small Patient Identity & ETA info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeEmergency!.patientName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPatientOnboard
                        ? "Hospital ETA: ${_toHospitalEta ?? 'Calculating...'}"
                        : "Patient ETA: ${_toPatientEta ?? 'Calculating...'}",
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Clean modern button to trigger update
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: onTap,
              child: Text(
                actionText,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  EmergencyStatus? get _nextEmergencyStatus {
    switch (_activeEmergency?.status) {
      case EmergencyStatus.accepted:
        return EmergencyStatus.arrived;
      case EmergencyStatus.arrived:
        return EmergencyStatus.completed;
      case EmergencyStatus.patientOnboard:
        return EmergencyStatus.completed;
      default:
        return null;
    }
  }

  String get _nextEmergencyStatusLabel {
    switch (_nextEmergencyStatus) {
      case EmergencyStatus.arrived:
        return 'Arrived';
      case EmergencyStatus.completed:
        return 'Complete';
      default:
        return 'Update';
    }
  }

  Future<void> _advanceEmergencyStatus() async {
    final emergency = _activeEmergency;
    final nextStatus = _nextEmergencyStatus;
    if (emergency == null || nextStatus == null || _isUpdatingEmergencyStatus) {
      return;
    }

    setState(() => _isUpdatingEmergencyStatus = true);
    var succeeded = false;
    try {
      if (nextStatus == EmergencyStatus.completed) {
        succeeded = await _firebaseService.completeEmergency(emergency.id);
        if (succeeded) {
          await _firebaseService.updateAmbulanceStatus(widget.uid, false);
        }
      } else {
        succeeded = await _firebaseService.updateEmergencyStatus(
          emergency.id,
          nextStatus,
        );
      }

      if (succeeded && mounted) {
        setState(() {
          _activeEmergency = nextStatus == EmergencyStatus.completed
              ? null
              : emergency.copyWith(status: nextStatus);
          _isUpdatingEmergencyStatus = false;
          if (nextStatus == EmergencyStatus.completed) {
            _routePointsLeg1 = [];
            _routePointsLeg2 = [];
          }
        });
        if (nextStatus == EmergencyStatus.completed) {
          DashboardScreen.completedTrips.add(emergency.id);
        }
      } else if (mounted) {
        setState(() => _isUpdatingEmergencyStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save status. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isUpdatingEmergencyStatus = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save status. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '< 1 min';
    return '${(seconds / 60).round()} min';
  }
}
