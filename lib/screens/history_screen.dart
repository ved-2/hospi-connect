import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final List<Map<String, dynamic>> _trips = const [
    {'condition': 'Cardiac Arrest', 'hospital': 'Ruby Hall Clinic', 'time': '09:14 AM', 'date': 'Today', 'severity': 'Critical'},
    {'condition': 'Road Accident', 'hospital': 'KEM Hospital', 'time': '07:52 AM', 'date': 'Today', 'severity': 'Critical'},
    {'condition': 'Stroke Patient', 'hospital': 'Sahyadri Hospital', 'time': '03:30 PM', 'date': 'Yesterday', 'severity': 'Moderate'},
    {'condition': 'Diabetic Emergency', 'hospital': 'Jehangir Hospital', 'time': '11:20 AM', 'date': 'Yesterday', 'severity': 'Mild'},
    {'condition': 'Respiratory Failure', 'hospital': 'Deenanath Mangeshkar', 'time': '08:05 AM', 'date': '15 Mar', 'severity': 'Critical'},
    {'condition': 'Snake Bite', 'hospital': 'Sassoon General', 'time': '02:45 PM', 'date': '14 Mar', 'severity': 'Moderate'},
    {'condition': 'Pregnancy Emergency', 'hospital': 'Jehangir Hospital', 'time': '06:10 PM', 'date': '13 Mar', 'severity': 'Moderate'},
    {'condition': 'Seizure / Epilepsy', 'hospital': 'Sahyadri Hospital', 'time': '10:33 AM', 'date': '12 Mar', 'severity': 'Mild'},
  ];

  @override
  Widget build(BuildContext context) {
    // Group by date
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final trip in _trips) {
      final date = trip['date'] as String;
      grouped.putIfAbsent(date, () => []).add(trip);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        title: const Text('Trip History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: entry.key == 'Today'
                            ? const Color(0xFFE53935)
                            : const Color(0xFF1A1A2E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(entry.key,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Divider(color: Colors.grey.withOpacity(0.3))),
                  ],
                ),
              ),
              // Trips for that date
              ...entry.value.map((trip) => _tripCard(trip)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _tripCard(Map<String, dynamic> trip) {
    final severityColor = trip['severity'] == 'Critical'
        ? const Color(0xFFE53935)
        : trip['severity'] == 'Moderate'
            ? const Color(0xFFFF8F00)
            : const Color(0xFF2E7D32);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_hospital_rounded,
                color: severityColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip['hospital'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(trip['condition'],
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(trip['time'],
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(trip['severity'],
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: severityColor)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}