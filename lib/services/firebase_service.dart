import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/emergency_model.dart';
import 'package:latlong2/latlong.dart';
import '../utils/app_logger.dart';
import '../models/models.dart';

class FirebaseService {
  final FirebaseFirestore? _firestore;

  FirebaseService() : _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  bool get isAvailable => _firestore != null;

  Stream<Map<String, LatLng>> getAmbulanceLocations() {
    if (_firestore == null) {
      AppLogger.log('Firestore NOT available in getAmbulanceLocations');
      return const Stream.empty();
    }
    return _firestore!.collection('ambulances').snapshots().map((snapshot) {
      final map = <String, LatLng>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Skip ambulances currently occupied with an emergency
        final bool isBusy = data['isBusy'] == true;
        if (isBusy) continue;
        
        final lat = data['gpsLat'];
        final lng = data['gpsLng'];
        if (lat is num && lng is num) {
          map[doc.id] = LatLng(lat.toDouble(), lng.toDouble());
        }
      }
      return map;
    });
  }

  Future<Map<String, dynamic>?> getAmbulanceData(String uid) async {
    if (_firestore == null) return null;
    try {
      final doc = await _firestore!.collection('ambulances').doc(uid).get();
      return doc.data();
    } catch (e) {
      AppLogger.log('Error fetching ambulance data: $e');
      return null;
    }
  }

  Stream<List<EmergencyModel>> getPendingEmergencies() {
    if (_firestore == null) {
      AppLogger.log('Firestore NOT available in getPendingEmergencies');
      return const Stream.empty();
    }
    
    // We strictly only want real recent SOS requests, NOT old demo dataset trips
    final cutoffTimestamp = Timestamp.fromDate(DateTime.now().subtract(const Duration(minutes: 15)));
    
    AppLogger.log('Starting getPendingEmergencies stream (Filtering for NEW SOS only)...');
    return _firestore!
        .collection('emergencies')
        .where('status', whereIn: ['pending', 'incoming'])
        .snapshots()
        .map((snapshot) {
          AppLogger.log('Firestore Snapshot: ${snapshot.docs.length} pending docs found.');
          final list = snapshot.docs
              .map((doc) {
                try {
                  final data = doc.data();
                  
                  // Very strict local filter to bypass ancient demo database records
                  final docCreatedAt = data['createdAt'];
                  if (docCreatedAt == null) return null; // Ignore if no timestamp
                  
                  DateTime docTime;
                  if (docCreatedAt is Timestamp) {
                    docTime = docCreatedAt.toDate();
                  } else {
                    docTime = DateTime.parse(docCreatedAt.toString());
                  }

                  if (docTime.isBefore(DateTime.now().subtract(const Duration(minutes: 15)))) {
                     AppLogger.log('Hard filtering out stale database record: ${doc.id}');
                     return null; // Ignore
                  }

                  AppLogger.log('Checking doc ${doc.id}: status=${data['status']}, transport=${data['transportType']}');
                  return EmergencyModel.fromFirestore(doc);
                } catch (e) {
                  AppLogger.log('Failed to parse emergency ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<EmergencyModel>()
              .where((emergency) {
                bool isAmb = emergency.transportType == 'ambulance';
                if (!isAmb) AppLogger.log('Filtering out ${emergency.id}: Transport is ${emergency.transportType}');
                return isAmb;
              })
              .toList();
          return list;
        }).handleError((error) {
          AppLogger.log('STREAM ERROR in getPendingEmergencies: $error');
        });
  }
  
  Stream<EmergencyModel?> emergencyStream(String emergencyId) {
    if (_firestore == null) return const Stream.empty();
    return _firestore!
        .collection('emergencies')
        .doc(emergencyId)
        .snapshots()
        .map((doc) => doc.exists ? EmergencyModel.fromFirestore(doc) : null);
  }

  Stream<List<EmergencyModel>> getAmbulanceHistory(String ambulanceId) {
    if (_firestore == null) return const Stream.empty();
    AppLogger.log('Querying history for ambulanceId: $ambulanceId');
    return _firestore!
        .collection('emergencies')
        .where('ambulanceId', isEqualTo: ambulanceId)
        .snapshots()
        .map((snapshot) {
          AppLogger.log('History Snapshot: ${snapshot.docs.length} docs found for $ambulanceId');
          final list = snapshot.docs
            .map((doc) {
              try {
                return EmergencyModel.fromFirestore(doc);
              } catch (e) {
                AppLogger.log('Error parsing history doc ${doc.id}: $e');
                return null;
              }
            })
            .whereType<EmergencyModel>()
            .toList();
          // Sort locally by createdAt desc
          list.sort((a, b) {
            final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return tb.compareTo(ta);
          });
          AppLogger.log('Returning ${list.length} parsed history items.');
          return list;
        });
  }

  Stream<Map<String, String>> getHospitalNames() {
    if (_firestore == null) return const Stream.empty();
    return _firestore!.collection('hospitals').snapshots().map((snapshot) {
      final map = <String, String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = data['name'];
        if (name is String && name.isNotEmpty) {
          map[doc.id] = name;
        }
      }
      return map;
    });
  }

  Future<List<Hospital>> fetchHospitals(
    ResourceRequirement req, {
    LatLng? userLocation,
  }) async {
    if (_firestore == null) return [];
    try {
      final snap = await _firestore!.collection('hospitals').get();
      final hospitals = snap.docs.map((doc) {
        final data = doc.data();

        final beds = data['beds'] as Map<String, dynamic>? ?? const {};
        final icu = beds['icu'] as Map<String, dynamic>? ?? const {};
        final emergency = beds['emergency'] as Map<String, dynamic>? ?? const {};

        final resources = data['resources'] as Map<String, dynamic>? ?? const {};

        final icuTotal = _asInt(icu['total']);
        final icuAvail = _asInt(icu['available']);
        final ventTotal = _asInt(resources['ventilators']);
        final ventAvail = ventTotal;
        final oxyTotal = _asInt(emergency['total']);
        final oxyAvail = _asInt(emergency['available']);

        final hasEmergencyOT = (data['hasEmergencyOT'] as bool?) ??
            (resources['emergencyOT'] as bool?) ??
            (oxyTotal > 0);

        final specialties = (data['specialties'] as List?)
                ?.whereType<String>()
                .toList() ??
            const <String>[];

        final distanceKm =
            _distanceKm(userLocation, data['gpsLat'], data['gpsLng']);

        final matchScore = DiseaseMapper.computeScore(
          req,
          icuAvail,
          icuTotal,
          ventAvail,
          ventTotal,
          oxyAvail,
          oxyTotal,
          hasEmergencyOT,
          specialties,
          distanceKm,
        );

        return Hospital(
          id: doc.id,
          name: data['name'] as String? ?? 'Unknown Hospital',
          address: data['address'] as String? ?? 'Unknown Address',
          distanceKm: distanceKm,
          icuAvailable: icuAvail,
          icuTotal: icuTotal,
          ventilatorsAvailable: ventAvail,
          ventilatorsTotal: ventTotal,
          oxygenBedsAvailable: oxyAvail,
          oxygenBedsTotal: oxyTotal,
          hasEmergencyOT: hasEmergencyOT,
          specialties: specialties,
          phone: data['phone'] as String? ?? 'N/A',
          matchScore: matchScore,
        );
      }).toList();

      return DiseaseMapper.rankHospitals(hospitals, req);
    } catch (e) {
      AppLogger.log('Error fetching hospitals: $e');
      return [];
    }
  }

  Future<void> acceptEmergency(String emergencyId, String ambulanceId) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('emergencies').doc(emergencyId).set({
        'status': EmergencyStatus.accepted.value,
        'ambulanceId': ambulanceId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.log('Successfully accepted emergency $emergencyId');
    } catch (e) {
      AppLogger.log('Error accepting emergency: $e');
    }
  }
  
  Future<void> updateEmergencyStatus(String emergencyId, EmergencyStatus status) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('emergencies').doc(emergencyId).update({
        'status': status.value,
      });
    } catch (e) {
      AppLogger.log('Error updating emergency status: $e');
    }
  }

  Future<void> completeEmergency(String emergencyId) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('emergencies').doc(emergencyId).update({
        'status': EmergencyStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(), // Permanently flag as completed
      });
      AppLogger.log('Successfully completed and sealed emergency $emergencyId');
    } catch (e) {
      AppLogger.log('Error completing emergency: $e');
    }
  }

  Future<void> updateAmbulanceLocation(String ambulanceId, LatLng location) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('ambulances').doc(ambulanceId).set({
        'gpsLat': location.latitude,
        'gpsLng': location.longitude,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Avoid spamming logs if permission is missing, just print once
      AppLogger.log('Error updating ambulance location (Rule issue?): $e');
    }
  }

  Future<void> updateAmbulanceStatus(String ambulanceId, bool isBusy) async {
    if (_firestore == null) return;
    try {
      await _firestore!.collection('ambulances').doc(ambulanceId).set({
        'isBusy': isBusy,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      AppLogger.log('Error updating ambulance status: $e');
    }
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  double _distanceKm(LatLng? userLocation, dynamic lat, dynamic lng) {
    if (userLocation == null) return 9999;
    if (lat is! num || lng is! num) return 9999;
    final lat1 = userLocation.latitude;
    final lon1 = userLocation.longitude;
    final lat2 = lat.toDouble();
    final lon2 = lng.toDouble();
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}
