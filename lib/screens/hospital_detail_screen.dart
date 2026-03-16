import 'package:flutter/material.dart';
import '../models/models.dart';
import 'transfer_confirmed_screen.dart';

class HospitalDetailScreen extends StatelessWidget {
  final Hospital hospital;
  final PatientCase patient;
  final ResourceRequirement requirement;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    required this.patient,
    required this.requirement,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: red,
        foregroundColor: Colors.white,
        title: const Text('Hospital Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: red.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.local_hospital_rounded,
                            color: Color(0xFFE53935), size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hospital.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 13, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(hospital.address,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _infoPill(Icons.directions_car_outlined,
                          '${hospital.distanceKm} km away'),
                      const SizedBox(width: 10),
                      _infoPill(Icons.phone_outlined, hospital.phone),
                      const SizedBox(width: 10),
                      _matchScorePill(hospital.matchScore),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resource availability
                  _sectionTitle('Resource Availability'),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      children: [
                        _resourceRow(
                          icon: Icons.bed_outlined,
                          label: 'ICU Beds',
                          available: hospital.icuAvailable,
                          total: hospital.icuTotal,
                          needed: requirement.needsICU,
                        ),
                        const Divider(height: 24),
                        _resourceRow(
                          icon: Icons.air_outlined,
                          label: 'Ventilators',
                          available: hospital.ventilatorsAvailable,
                          total: hospital.ventilatorsTotal,
                          needed: requirement.needsVentilator,
                        ),
                        const Divider(height: 24),
                        _resourceRow(
                          icon: Icons.masks_outlined,
                          label: 'Oxygen Beds',
                          available: hospital.oxygenBedsAvailable,
                          total: hospital.oxygenBedsTotal,
                          needed: requirement.needsOxygenBed,
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.medical_services_outlined,
                                color: hospital.hasEmergencyOT
                                    ? Colors.green
                                    : Colors.grey,
                                size: 22),
                            const SizedBox(width: 14),
                            const Expanded(
                                child: Text('Emergency OT',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600))),
                            if (requirement.needsEmergencyOT)
                              const Text('REQUIRED',
                                  style: TextStyle(
                                      color: Color(0xFFE53935),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: hospital.hasEmergencyOT
                                    ? Colors.green.withOpacity(0.12)
                                    : Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                hospital.hasEmergencyOT
                                    ? 'Available'
                                    : 'Not Available',
                                style: TextStyle(
                                    color: hospital.hasEmergencyOT
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle('Specialties'),
                  const SizedBox(height: 12),
                  _card(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hospital.specialties
                          .map((s) => _specialtyChip(
                              s, s == requirement.specialDept))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionTitle('Patient Summary'),
                  const SizedBox(height: 12),
                  _card(
                    child: Column(
                      children: [
                        _summaryRow('Patient', patient.name),
                        _summaryRow('Age', '${patient.age} years'),
                        _summaryRow('Condition', patient.condition),
                        _summaryRow('Severity', patient.severity),
                        _summaryRow('Pickup', patient.citizenLocation),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmTransfer(context),
                      icon: const Icon(Icons.send_rounded, size: 22),
                      label: const Text('CONFIRM TRANSFER TO THIS HOSPITAL',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded,
                          size: 16),
                      label: const Text('Back to Results'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side:
                            const BorderSide(color: Color(0xFFE53935)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmTransfer(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Text(
            'Send emergency transfer request to ${hospital.name} for patient ${patient.name}?'),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => TransferConfirmedScreen(
                    hospital: hospital,
                    patient: patient,
                  ),
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1A2E)));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: child,
      );

  Widget _resourceRow({
    required IconData icon,
    required String label,
    required int available,
    required int total,
    required bool needed,
  }) {
    final pct = total > 0 ? available / total : 0.0;
    final color = available > 0 ? const Color(0xFF2E7D32) : const Color(0xFFE53935);

    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (needed) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('REQUIRED',
                          style: TextStyle(
                              color: Color(0xFFE53935),
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text('$available/$total',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }

  Widget _specialtyChip(String s, bool isMatch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isMatch
            ? const Color(0xFF2E7D32).withOpacity(0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isMatch
                ? const Color(0xFF2E7D32).withOpacity(0.5)
                : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatch) ...[
            const Icon(Icons.star_rounded,
                color: Color(0xFF2E7D32), size: 14),
            const SizedBox(width: 4),
          ],
          Text(s,
              style: TextStyle(
                  color: isMatch
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF555555),
                  fontSize: 12,
                  fontWeight:
                      isMatch ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
      );

  Widget _infoPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 13),
            const SizedBox(width: 5),
            Text(text,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      );

  Widget _matchScorePill(double score) {
    final color = score >= 70 ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text('${score.toInt()}% match',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11)),
    );
  }
}
