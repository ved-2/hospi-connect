import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/emergency_model.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';
import 'history_screen.dart';

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

  static final StreamController<String> logController = StreamController<String>.broadcast();
  static void log(String msg) {
    print('DEBUG: $msg');
    logController.add(msg);
  }

  const DashboardScreen({
    super.key,
    required this.ambulanceId,
    required this.driverName,
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
  bool _showDebug = true;
  
  ll.LatLng? _currentLocation;
  final Map<String, ll.LatLng> _ambulanceLocations = {};
  List<ll.LatLng> _routePoints = [];
  
  EmergencyModel? _activeEmergency;
  final Set<String> _shownDialogs = {};
  final MapController _mapController = MapController();
  final DateTime _sessionStart = DateTime.now();

  static const Duration _recentWindow = Duration(minutes: 30);
  static const double _maxDistanceMeters = 8000; // 8 km radius

  @override
  void initState() {
    super.initState();
    _debugLogSubscription = DashboardScreen.logController.stream.listen((msg) {
      if (mounted) setState(() => _debugLogs.insert(0, msg));
    });
    DashboardScreen.log('Init Dashboard for ${widget.ambulanceId}');
    _startLocationService();
    _listenForAmbulanceLocations();
    _listenForEmergencies();
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
      DashboardScreen.log('Initial location found: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      setState(() {}); 
      _firebaseService.updateAmbulanceLocation(widget.ambulanceId, _currentLocation!);
    } else {
      DashboardScreen.log('Initial location search returned null.');
    }

    DashboardScreen.log('Subscribing to live location stream...');
    _locationSubscription = _locationService.getLocationStream().listen((loc) {
      if (mounted) {
        setState(() => _currentLocation = loc);
        _firebaseService.updateAmbulanceLocation(widget.ambulanceId, loc);
      }
    });
  }

  void _listenForEmergencies() {
    _pendingSubscription = _firebaseService.getPendingEmergencies().listen((emergencies) {
      if (_activeEmergency != null) return; 
      if (_currentLocation == null) return;

      final now = DateTime.now();
      final windowCutoff = now.subtract(_recentWindow);
      final cutoff = _sessionStart.isAfter(windowCutoff) ? _sessionStart : windowCutoff;
      final distance = const ll.Distance();

      final candidates = emergencies.where((e) {
        if (_shownDialogs.contains(e.id)) return false;
        if (e.ambulanceId != null && e.ambulanceId!.isNotEmpty) return false;
        if (e.createdAt == null || e.createdAt!.isBefore(cutoff)) return false;
        final meters = distance(
          _currentLocation!,
          ll.LatLng(e.latitude, e.longitude),
        );
        return meters <= _maxDistanceMeters;
      }).toList();

      if (candidates.isEmpty) return;

      candidates.sort((a, b) {
        final da = distance(_currentLocation!, ll.LatLng(a.latitude, a.longitude));
        final db = distance(_currentLocation!, ll.LatLng(b.latitude, b.longitude));
        final cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta); 
      });

      for (var e in candidates) {
        if (_isNearestAmbulanceForEmergency(e, _currentLocation!)) {
          _shownDialogs.add(e.id);
          _showEmergencyDialog(e);
          break; 
        }
      }
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
    if (_ambulanceLocations.isEmpty) return true;
    final target = ll.LatLng(emergency.latitude, emergency.longitude);
    final distance = const ll.Distance();
    var nearestId = widget.ambulanceId;
    var nearestDistance = distance(myLocation, target);

    _ambulanceLocations.forEach((id, loc) {
      final d = distance(loc, target);
      if (d < nearestDistance) {
        nearestDistance = d;
        nearestId = id;
      }
    });

    return nearestId == widget.ambulanceId;
  }

  Future<void> _fetchRoute(ll.LatLng start, ll.LatLng end) async {
    final url = 'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
        if (mounted) {
          setState(() {
            _routePoints = coordinates
                .map((c) => ll.LatLng(c[1] as double, c[0] as double))
                .toList();
          });
        }
      }
    } catch (e) {
      DashboardScreen.log('Error fetching route: $e');
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
          side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColors.primaryRed, size: 24),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'EMERGENCY SOS', 
                style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)
              )
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: AppColors.surfaceLight),
            const SizedBox(height: 12),
            _infoRow(Icons.person_rounded, 'Patient', emergency.patientName),
            const SizedBox(height: 16),
            _infoRow(Icons.monitor_heart_rounded, 'Condition', emergency.symptoms, isHighlight: true),
            const SizedBox(height: 16),
            _infoRow(Icons.location_on_rounded, 'Location', emergency.location),
          ],
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('DECLINE', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _firebaseService.acceptEmergency(emergency.id, widget.ambulanceId);
                    setState(() {
                      _activeEmergency = emergency.copyWith(status: EmergencyStatus.accepted);
                    });
                    if (_currentLocation != null) {
                      _fetchRoute(_currentLocation!, ll.LatLng(emergency.latitude, emergency.longitude));
                    }
                  },
                  child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          )
        ],
      )
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: isHighlight ? AppColors.primaryRed : AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                value, 
                style: TextStyle(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                  color: isHighlight ? AppColors.primaryRed : AppColors.textPrimary,
                  fontSize: isHighlight ? 16 : 14,
                  height: 1.3,
                )
              ),
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
                    offset: const Offset(0, 4)
                  ),
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
                      border: Border.all(color: AppColors.primaryRed.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.emergency_rounded, color: AppColors.primaryRed, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(widget.ambulanceId.toUpperCase(), 
                              style: const TextStyle(
                                color: AppColors.textPrimary, 
                                fontSize: 15, 
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              )
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.15),
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
                                    )
                                  ),
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
                          )
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // ── Immersive Map Layout ───────────────────────────
            Expanded(
              child: _currentLocation == null
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
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
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.ambulance_app',
                              tileDisplay: const TileDisplay.fadeIn(),
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    strokeWidth: 5.0,
                                    color: AppColors.accentBlue,
                                    borderColor: Colors.white.withValues(alpha: 0.8),
                                    borderStrokeWidth: 2.0,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 60,
                                  height: 60,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentBlue.withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const Icon(Icons.navigation_rounded, color: AppColors.accentBlue, size: 36),
                                    ],
                                  ),
                                ),
                                if (_activeEmergency != null)
                                  Marker(
                                    point: ll.LatLng(_activeEmergency!.latitude, _activeEmergency!.longitude),
                                    width: 50,
                                    height: 50,
                                    child: const Icon(Icons.location_on_rounded, color: AppColors.primaryRed, size: 48),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        // Map Controls (Right Side)
                        Positioned(
                          right: 16,
                          top: 16,
                          child: Column(
                            children: [
                              FloatingActionButton(
                                mini: true,
                                heroTag: 'map_traffic',
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.textPrimary,
                                child: const Icon(Icons.traffic_rounded, size: 20),
                                onPressed: () {},
                              ),
                              const SizedBox(height: 12),
                              FloatingActionButton(
                                mini: true,
                                heroTag: 'map_center',
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.accentBlue,
                                child: const Icon(Icons.my_location_rounded, size: 20),
                                onPressed: () {
                                  if (_currentLocation != null) {
                                    _mapController.move(_currentLocation!, 15);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),

                        // Floating Active Mission Banner (Bottom)
                        if (_activeEmergency != null)
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.surfaceLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4), 
                                    blurRadius: 20, 
                                    offset: const Offset(0, 10)
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      color: AppColors.primaryRed.withValues(alpha: 0.1),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.shield_rounded, color: AppColors.primaryRed, size: 16),
                                          const SizedBox(width: 8),
                                          const Text('ACTIVE MISSION', 
                                            style: TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                                          const Spacer(),
                                          Text(_activeEmergency!.status.value.toUpperCase(), 
                                            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(_activeEmergency!.patientName, 
                                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                                                    const SizedBox(height: 6),
                                                    Text(_activeEmergency!.symptoms, 
                                                      style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14)),
                                                  ],
                                                ),
                                              ),
                                              Material(
                                                color: AppColors.surfaceLight,
                                                borderRadius: BorderRadius.circular(12),
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(12),
                                                  onTap: () { /* Call Action */ },
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Icon(Icons.call_rounded, color: AppColors.successGreen, size: 24),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          if (_activeEmergency!.status == EmergencyStatus.accepted)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.accentBlue,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 0,
                                                ),
                                                onPressed: () async {
                                                  await _firebaseService.updateEmergencyStatus(_activeEmergency!.id, EmergencyStatus.arrived);
                                                  setState(() {
                                                    _activeEmergency = _activeEmergency!.copyWith(status: EmergencyStatus.arrived);
                                                  });
                                                },
                                                child: const Text('ARRIVED AT SCENE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                                              )
                                            ),
                                          if (_activeEmergency!.status == EmergencyStatus.arrived)
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.successGreen,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  elevation: 0,
                                                ),
                                                onPressed: () async {
                                                  await _firebaseService.completeEmergency(_activeEmergency!.id);
                                                  setState(() {
                                                    _activeEmergency = null;
                                                    _routePoints.clear();
                                                  });
                                                },
                                                child: const Text('MISSION COMPLETED', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                                              )
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceLight.withValues(alpha: 0.5))),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          elevation: 0,
          selectedItemColor: AppColors.primaryRed,
          unselectedItemColor: AppColors.textSecondary,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, height: 1.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11, height: 1.5),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'DASHBOARD'),
            BottomNavigationBarItem(icon: Icon(Icons.history_toggle_off_rounded), label: 'HISTORY'),
            BottomNavigationBarItem(icon: Icon(Icons.logout_rounded), label: 'LOGOUT'),
          ],
          onTap: (i) {
            if (i == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(ambulanceId: widget.ambulanceId)));
            }
            if (i == 2) {
               FirebaseAuth.instance.signOut();
            }
          },
        ),
      ),
    );
  }
}