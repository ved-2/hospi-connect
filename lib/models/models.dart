// ─────────────────────────────────────────────
//  MODELS
// ─────────────────────────────────────────────

// Disease / condition entered by citizen
class PatientCase {
  final String name;
  final int age;
  final String condition;        // e.g. "Cardiac Arrest"
  final String severity;         // Critical / Moderate / Mild
  final String citizenLocation;

  const PatientCase({
    required this.name,
    required this.age,
    required this.condition,
    required this.severity,
    required this.citizenLocation,
  });
}

// What resource a disease needs
class ResourceRequirement {
  final bool needsICU;
  final bool needsVentilator;
  final bool needsOxygenBed;
  final bool needsEmergencyOT;
  final String specialDept;      // e.g. "Cardiology", "Neurology"

  const ResourceRequirement({
    required this.needsICU,
    required this.needsVentilator,
    required this.needsOxygenBed,
    required this.needsEmergencyOT,
    required this.specialDept,
  });
}

// Hospital entity
class Hospital {
  final String id;
  final String name;
  final String address;
  final double distanceKm;
  final int icuAvailable;
  final int icuTotal;
  final int ventilatorsAvailable;
  final int ventilatorsTotal;
  final int oxygenBedsAvailable;
  final int oxygenBedsTotal;
  final bool hasEmergencyOT;
  final List<String> specialties;
  final String phone;
  final double latitude;
  final double longitude;
  final double matchScore; // 0-100, computed from patient needs

  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.distanceKm,
    required this.icuAvailable,
    required this.icuTotal,
    required this.ventilatorsAvailable,
    required this.ventilatorsTotal,
    required this.oxygenBedsAvailable,
    required this.oxygenBedsTotal,
    required this.hasEmergencyOT,
    required this.specialties,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.matchScore,
  });
}

extension HospitalLoad on Hospital {
  double get loadPercent {
    final total = icuTotal + ventilatorsTotal + oxygenBedsTotal;
    final available = icuAvailable + ventilatorsAvailable + oxygenBedsAvailable;
    if (total <= 0) return 1.0;
    final occupiedRatio = 1 - (available / total);
    return occupiedRatio.clamp(0.0, 1.0);
  }
}

// ─────────────────────────────────────────────
//  DISEASE → RESOURCE MAPPING
// ─────────────────────────────────────────────
class DiseaseMapper {
  static final Map<String, ResourceRequirement> _map = {
    'Cardiac Arrest': const ResourceRequirement(
      needsICU: true, needsVentilator: true,
      needsOxygenBed: false, needsEmergencyOT: true,
      specialDept: 'Cardiology',
    ),
    'Heart Attack': const ResourceRequirement(
      needsICU: true, needsVentilator: false,
      needsOxygenBed: true, needsEmergencyOT: true,
      specialDept: 'Cardiology',
    ),
    'Stroke': const ResourceRequirement(
      needsICU: true, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: false,
      specialDept: 'Neurology',
    ),
    'Brain Hemorrhage': const ResourceRequirement(
      needsICU: true, needsVentilator: true,
      needsOxygenBed: false, needsEmergencyOT: true,
      specialDept: 'Neurology',
    ),
    'Respiratory Failure': const ResourceRequirement(
      needsICU: true, needsVentilator: true,
      needsOxygenBed: true, needsEmergencyOT: false,
      specialDept: 'Pulmonology',
    ),
    'Pneumonia (Severe)': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: true, needsEmergencyOT: false,
      specialDept: 'Pulmonology',
    ),
    'COVID-19 (Severe)': const ResourceRequirement(
      needsICU: true, needsVentilator: true,
      needsOxygenBed: true, needsEmergencyOT: false,
      specialDept: 'Pulmonology',
    ),
    'Road Accident (Trauma)': const ResourceRequirement(
      needsICU: true, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: true,
      specialDept: 'Trauma Surgery',
    ),
    'Burns (Severe)': const ResourceRequirement(
      needsICU: true, needsVentilator: false,
      needsOxygenBed: true, needsEmergencyOT: true,
      specialDept: 'Burns & Plastic Surgery',
    ),
    'Kidney Failure': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: false,
      specialDept: 'Nephrology',
    ),
    'Diabetic Emergency': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: false,
      specialDept: 'Endocrinology',
    ),
    'Seizure / Epilepsy': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: false,
      specialDept: 'Neurology',
    ),
    'Snake Bite': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: false,
      specialDept: 'Emergency Medicine',
    ),
    'Sepsis': const ResourceRequirement(
      needsICU: true, needsVentilator: false,
      needsOxygenBed: true, needsEmergencyOT: false,
      specialDept: 'Critical Care',
    ),
    'Pregnancy Emergency': const ResourceRequirement(
      needsICU: false, needsVentilator: false,
      needsOxygenBed: false, needsEmergencyOT: true,
      specialDept: 'Obstetrics & Gynaecology',
    ),
  };

  static List<String> get allConditions => _map.keys.toList()..sort();

  static ResourceRequirement getRequirements(String condition) {
    return _map[condition] ??
        const ResourceRequirement(
          needsICU: false, needsVentilator: false,
          needsOxygenBed: false, needsEmergencyOT: false,
          specialDept: 'General Medicine',
        );
  }

  static List<Hospital> rankHospitals(
      List<Hospital> hospitals, ResourceRequirement req) {
    // Already ranked by matchScore; just return sorted
    return [...hospitals]
      ..sort((a, b) {
        final scoreCmp = b.matchScore.compareTo(a.matchScore);
        if (scoreCmp != 0) return scoreCmp;
        final distCmp = a.distanceKm.compareTo(b.distanceKm);
        if (distCmp != 0) return distCmp;
        return a.loadPercent.compareTo(b.loadPercent);
      });
  }

  static double computeScore(
    ResourceRequirement req,
    int icuAvail, int icuTotal,
    int ventAvail, int ventTotal,
    int oxyAvail, int oxyTotal,
    bool ot,
    List<String> specs,
    double dist,
  ) {
    double score = 0;
    
    // Resource Availability (Primary Focus: Most Beds)
    if (req.needsICU) score += icuAvail > 0 ? (40 + icuAvail * 2) : -30;
    if (req.needsVentilator) score += ventAvail > 0 ? (30 + ventAvail * 2) : -20;
    if (req.needsOxygenBed) score += oxyAvail > 0 ? (20 + oxyAvail) : -10;
    if (req.needsEmergencyOT) score += ot ? 20 : -10;
    
    // Specialty Match
    if (specs.contains(req.specialDept)) score += 25;
    
    // Total Capacity Bonus (Prioritize larger hospitals if they have room)
    final totalCapacity = icuTotal + ventTotal + oxyTotal;
    score += (totalCapacity / 20).clamp(0, 15);

    // Distance Penalty (Nearest)
    // 1km distance = -5 score. Highly sensitive to proximity.
    score -= dist * 5.0; 
    
    // Load Penalty (Avoid fully occupied hospitals)
    final available = icuAvail + ventAvail + oxyAvail;
    final loadPercent = totalCapacity > 0 ? 1 - (available / totalCapacity) : 1.0;
    score -= (loadPercent.clamp(0.0, 1.0) * 30); 
    
    return score.clamp(0, 100);
  }
}

// ─────────────────────────────────────────────
//  MOCK DATA (replace with Firebase/API later)
// ─────────────────────────────────────────────
class MockData {
  static List<Hospital> getHospitals(ResourceRequirement req) {
    final raw = [
      Hospital(
        id: 'h1',
        name: 'Ruby Hall Clinic',
        address: 'Sassoon Road, Pune',
        distanceKm: 2.1,
        icuAvailable: 3, icuTotal: 10,
        ventilatorsAvailable: 2, ventilatorsTotal: 5,
        oxygenBedsAvailable: 6, oxygenBedsTotal: 15,
        hasEmergencyOT: true,
        specialties: ['Cardiology', 'Neurology', 'Trauma Surgery', 'Critical Care'],
        phone: '+91-20-26163391',
        latitude: 18.5304, longitude: 73.8767,
        matchScore: DiseaseMapper.computeScore(req, 3, 10, 2, 5, 6, 15, true,
            ['Cardiology', 'Neurology', 'Trauma Surgery', 'Critical Care'], 2.1),
      ),
      Hospital(
        id: 'h2',
        name: 'Jehangir Hospital',
        address: 'Sassoon Road, Pune',
        distanceKm: 2.8,
        icuAvailable: 1, icuTotal: 8,
        ventilatorsAvailable: 0, ventilatorsTotal: 4,
        oxygenBedsAvailable: 4, oxygenBedsTotal: 12,
        hasEmergencyOT: true,
        specialties: ['Cardiology', 'Pulmonology', 'Nephrology', 'Obstetrics & Gynaecology'],
        phone: '+91-20-66814444',
        latitude: 18.5324, longitude: 73.8787,
        matchScore: DiseaseMapper.computeScore(req, 1, 8, 0, 4, 4, 12, true,
            ['Cardiology', 'Pulmonology', 'Nephrology', 'Obstetrics & Gynaecology'], 2.8),
      ),
      Hospital(
        id: 'h3',
        name: 'KEM Hospital',
        address: 'Rasta Peth, Pune',
        distanceKm: 3.5,
        icuAvailable: 5, icuTotal: 20,
        ventilatorsAvailable: 4, ventilatorsTotal: 10,
        oxygenBedsAvailable: 10, oxygenBedsTotal: 30,
        hasEmergencyOT: true,
        specialties: ['Trauma Surgery', 'Pulmonology', 'Critical Care', 'Burns & Plastic Surgery'],
        phone: '+91-20-26126300',
        latitude: 18.5204, longitude: 73.8657,
        matchScore: DiseaseMapper.computeScore(req, 5, 20, 4, 10, 10, 30, true,
            ['Trauma Surgery', 'Pulmonology', 'Critical Care', 'Burns & Plastic Surgery'], 3.5),
      ),
      Hospital(
        id: 'h4',
        name: 'Sahyadri Hospital',
        address: 'Deccan Gymkhana, Pune',
        distanceKm: 4.2,
        icuAvailable: 2, icuTotal: 12,
        ventilatorsAvailable: 1, ventilatorsTotal: 6,
        oxygenBedsAvailable: 8, oxygenBedsTotal: 20,
        hasEmergencyOT: false,
        specialties: ['Neurology', 'Endocrinology', 'Emergency Medicine', 'General Medicine'],
        phone: '+91-20-67210000',
        latitude: 18.5144, longitude: 73.8407,
        matchScore: DiseaseMapper.computeScore(req, 2, 12, 1, 6, 8, 20, false,
            ['Neurology', 'Endocrinology', 'Emergency Medicine', 'General Medicine'], 4.2),
      ),
      Hospital(
        id: 'h5',
        name: 'Deenanath Mangeshkar',
        address: 'Erandwane, Pune',
        distanceKm: 5.7,
        icuAvailable: 4, icuTotal: 15,
        ventilatorsAvailable: 3, ventilatorsTotal: 8,
        oxygenBedsAvailable: 12, oxygenBedsTotal: 25,
        hasEmergencyOT: true,
        specialties: ['Nephrology', 'Obstetrics & Gynaecology', 'Cardiology', 'Critical Care'],
        phone: '+91-20-49153000',
        latitude: 18.5084, longitude: 73.8297,
        matchScore: DiseaseMapper.computeScore(req, 4, 15, 3, 8, 12, 25, true,
            ['Nephrology', 'Obstetrics & Gynaecology', 'Cardiology', 'Critical Care'], 5.7),
      ),
      Hospital(
        id: 'h6',
        name: 'Sassoon General Hospital',
        address: 'Pune Station Area',
        distanceKm: 1.5,
        icuAvailable: 0, icuTotal: 18,
        ventilatorsAvailable: 0, ventilatorsTotal: 7,
        oxygenBedsAvailable: 2, oxygenBedsTotal: 22,
        hasEmergencyOT: true,
        specialties: ['General Medicine', 'Emergency Medicine'],
        phone: '+91-20-26128000',
        latitude: 18.5284, longitude: 73.8737,
        matchScore: DiseaseMapper.computeScore(req, 0, 18, 0, 7, 2, 22, true,
            ['General Medicine', 'Emergency Medicine'], 1.5),
      ),
    ];

    return raw..sort((a, b) => b.matchScore.compareTo(a.matchScore));
  }
}
