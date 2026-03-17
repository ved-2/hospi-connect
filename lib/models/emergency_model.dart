import 'package:cloud_firestore/cloud_firestore.dart';

enum EmergencyStatus {
  incoming,
  preparing,
  pending,
  assigned,
  accepted,
  arrived,
  patientOnboard,
  completed,
}

extension EmergencyStatusExtension on EmergencyStatus {
  String get value {
    switch (this) {
      case EmergencyStatus.incoming:
        return 'incoming';
      case EmergencyStatus.preparing:
        return 'preparing';
      case EmergencyStatus.pending:
        return 'pending';
      case EmergencyStatus.assigned:
        return 'assigned';
      case EmergencyStatus.accepted:
        return 'accepted';
      case EmergencyStatus.arrived:
        return 'arrived';
      case EmergencyStatus.patientOnboard:
        return 'patientOnboard';
      case EmergencyStatus.completed:
        return 'completed';
    }
  }

  static EmergencyStatus fromString(String status) {
    switch (status) {
      case 'incoming':
        return EmergencyStatus.incoming;
      case 'preparing':
        return EmergencyStatus.preparing;
      case 'assigned':
        return EmergencyStatus.assigned;
      case 'accepted':
        return EmergencyStatus.accepted;
      case 'arrived':
        return EmergencyStatus.arrived;
      case 'patientOnboard':
        return EmergencyStatus.patientOnboard;
      case 'completed':
        return EmergencyStatus.completed;
      default:
        return EmergencyStatus.pending;
    }
  }
}

class EmergencyModel {
  final String id;
  final String patientId;
  final String patientName;
  final String symptoms;
  final double latitude;
  final double longitude;
  final String location;
  final EmergencyStatus status;
  final String? hospitalId;
  final String? ambulanceId;
  final String? priority;
  final int? eta;
  final Map<String, dynamic>? medicalSnapshot;
  final String transportType;
  final bool guardianAlerted;
  final DateTime? createdAt;

  EmergencyModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.symptoms,
    required this.latitude,
    required this.longitude,
    this.location = '',
    this.status = EmergencyStatus.pending,
    this.hospitalId,
    this.ambulanceId,
    this.priority,
    this.eta,
    this.medicalSnapshot,
    this.transportType = 'ambulance',
    this.guardianAlerted = false,
    this.createdAt,
  });

  factory EmergencyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      patientName: data['patientName'] ?? '',
      symptoms: data['symptoms'] ?? '',
      latitude: (data['gpsLat'] ?? 0).toDouble(),
      longitude: (data['gpsLng'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      status: EmergencyStatusExtension.fromString(data['status'] ?? 'pending'),
      hospitalId: data['hospitalId'],
      ambulanceId: data['ambulanceId'],
      priority: data['priority'],
      eta: data['eta'],
      medicalSnapshot: data['medicalSnapshot'],
      transportType: data['transportType'] ?? 'ambulance',
      guardianAlerted: data['guardianAlerted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'symptoms': symptoms,
      'gpsLat': latitude,
      'gpsLng': longitude,
      'location': location,
      'status': status.value,
      'hospitalId': hospitalId,
      'ambulanceId': ambulanceId,
      'priority': priority ?? 'high',
      'eta': eta,
      'medicalSnapshot': medicalSnapshot,
      'transportType': transportType,
      'guardianAlerted': guardianAlerted,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  EmergencyModel copyWith({
    EmergencyStatus? status,
    String? hospitalId,
    String? ambulanceId,
    int? eta,
  }) {
    return EmergencyModel(
      id: id,
      patientId: patientId,
      patientName: patientName,
      symptoms: symptoms,
      latitude: latitude,
      longitude: longitude,
      location: location,
      status: status ?? this.status,
      hospitalId: hospitalId ?? this.hospitalId,
      ambulanceId: ambulanceId ?? this.ambulanceId,
      priority: priority,
      eta: eta ?? this.eta,
      createdAt: createdAt,
    );
  }
}
