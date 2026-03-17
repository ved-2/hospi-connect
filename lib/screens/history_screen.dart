import 'package:flutter/material.dart';
import '../models/emergency_model.dart';
import '../services/firebase_service.dart';

// --- Blinkit Design System ---
class BlinkitTheme {
  static const Color background = Color(0xFFF4F6F8); // Light gray-blue
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color brandYellow = Color(0xFFF8CB46); // Blinkit Yellow
  static const Color textDark = Color(0xFF000000); // Pure Black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color alertRed = Color(0xFFE53935); // Emergency Red
  static const Color successGreen = Color(0xFF0C9547); // Blinkit Green
  static const Color borderLight = Color(0xFFE5E7EB);
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  );
}

class HistoryScreen extends StatefulWidget {
  final String ambulanceId;

  const HistoryScreen({super.key, required this.ambulanceId});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlinkitTheme.background,
      appBar: AppBar(
        backgroundColor: BlinkitTheme.surface,
        title: const Text('MISSION LOGS',
            style: TextStyle(color: BlinkitTheme.textDark, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BlinkitTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<EmergencyModel>>(
        stream: _firebaseService.getAmbulanceHistory(widget.ambulanceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('LOG RETRIEVAL ERROR\n\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: BlinkitTheme.alertRed, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: BlinkitTheme.brandYellow, strokeWidth: 4),
            );
          }
          final emergencies = (snapshot.data ?? [])
              .where((e) => e.status != EmergencyStatus.pending)
              .toList();
          if (emergencies.isEmpty) {
            return const Center(
              child: Text('NO MISSION RECORDS FOUND',
                  style: TextStyle(color: BlinkitTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            );
          }

          return StreamBuilder<Map<String, String>>(
            stream: _firebaseService.getHospitalNames(),
            builder: (context, hospitalSnap) {
              final hospitalNames = hospitalSnap.data ?? const {};
              final Map<String, List<EmergencyModel>> grouped = {};
              for (final e in emergencies) {
                final dateLabel = _formatDateLabel(e.createdAt);
                grouped.putIfAbsent(dateLabel, () => []).add(e);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: grouped.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 12),
                        child: Text(entry.key.toUpperCase(),
                            style: const TextStyle(
                                color: BlinkitTheme.textSecondary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 1.5)),
                      ),
                      ...entry.value.map((e) => _tripCard(context, e, hospitalNames)),
                    ],
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }

  // LOGIC KEPT EXACTLY THE SAME
  String _formatDateLabel(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return '${date.day} ${_monthName(date.month)}';
  }

  String _monthName(int m) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '--:--';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  Widget _tripCard(
    BuildContext context,
    EmergencyModel trip,
    Map<String, String> hospitalNames,
  ) {
    final severity = trip.priority ?? 'Moderate';
    final hospitalName = trip.hospitalId != null
        ? (hospitalNames[trip.hospitalId!] ?? 'Hospital')
        : 'Hospital';
    
    // Mapped to Blinkit theme colors
    final severityColor = severity == 'Critical'
        ? BlinkitTheme.alertRed
        : severity == 'Moderate'
            ? const Color(0xFFF59E0B) // A slightly darker yellow/amber for text readability
            : BlinkitTheme.successGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BlinkitTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryDetailScreen(
                  emergency: trip,
                  hospitalName: hospitalName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medical_information_rounded,
                      color: severityColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trip.patientName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: BlinkitTheme.textDark)),
                      const SizedBox(height: 4),
                      Text(hospitalName.toUpperCase(),
                          style: const TextStyle(
                              color: BlinkitTheme.textSecondary, 
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(trip.createdAt),
                        style: const TextStyle(
                            color: BlinkitTheme.textDark, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(severity.toUpperCase(),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: severityColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryDetailScreen extends StatelessWidget {
  final EmergencyModel emergency;
  final String hospitalName;

  const HistoryDetailScreen({
    super.key,
    required this.emergency,
    required this.hospitalName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlinkitTheme.background,
      appBar: AppBar(
        backgroundColor: BlinkitTheme.surface,
        title: const Text('MISSION DEBRIEF',
            style: TextStyle(color: BlinkitTheme.textDark, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 16)),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.black.withOpacity(0.2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: BlinkitTheme.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BlinkitTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, color: BlinkitTheme.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    const Text('PATIENT IDENTIFIER', style: TextStyle(color: BlinkitTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: BlinkitTheme.textDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emergency.status.value.toUpperCase(),
                          style: const TextStyle(
                              color: BlinkitTheme.brandYellow,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(emergency.patientName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        color: BlinkitTheme.textDark)),
                const SizedBox(height: 8),
                Text(emergency.symptoms, style: const TextStyle(color: BlinkitTheme.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text('LOGISTICS SUMMARY', style: TextStyle(color: BlinkitTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
          ),
          _infoRow('INCIDENT LOC', emergency.location.isEmpty ? 'UNSPECIFIED' : emergency.location.toUpperCase()),
          _infoRow('PRIORITY LVL', (emergency.priority ?? 'MODERATE').toUpperCase()),
          _infoRow('HOSPITAL DST', hospitalName.toUpperCase()),
          _infoRow('ASSIGNED UNIT', (emergency.ambulanceId ?? 'UNSPECIFIED').toUpperCase()),
          _infoRow('TRANS TYPE', emergency.transportType.toUpperCase()),
          _infoRow('EST TRAVEL', '${emergency.eta ?? "N/A"} MINS'),
          _infoRow('TIMESTAMP', emergency.createdAt?.toString().toUpperCase() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: BlinkitTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BlinkitTheme.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ]
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: BlinkitTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: BlinkitTheme.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
