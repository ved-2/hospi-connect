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
    const primaryRed = Color(0xFFFF3B30);
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF161B26);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('FACILITY DETAILS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hospital hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_hospital_rounded,
                            color: primaryRed, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hospital.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 12, color: Colors.white.withValues(alpha: 0.3)),
                                const SizedBox(width: 4),
                                Text(hospital.address,
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _infoPill(Icons.directions_car_rounded,
                            '${hospital.distanceKm} KM'),
                        const SizedBox(width: 8),
                        _infoPill(Icons.insights_rounded,
                            'LOAD ${(hospital.loadPercent * 100).round()}%'),
                        const SizedBox(width: 8),
                        _infoPill(Icons.phone_rounded, hospital.phone),
                        const SizedBox(width: 8),
                        _matchScorePill(hospital.matchScore),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resource availability
                  _sectionTitle('RESOURCE AVAILABILITY'),
                  const SizedBox(height: 16),
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
                        Divider(height: 28, color: Colors.white.withValues(alpha: 0.05)),
                        _resourceRow(
                          icon: Icons.air_outlined,
                          label: 'Ventilators',
                          available: hospital.ventilatorsAvailable,
                          total: hospital.ventilatorsTotal,
                          needed: requirement.needsVentilator,
                        ),
                        Divider(height: 28, color: Colors.white.withValues(alpha: 0.05)),
                        _resourceRow(
                          icon: Icons.masks_outlined,
                          label: 'Oxygen Beds',
                          available: hospital.oxygenBedsAvailable,
                          total: hospital.oxygenBedsTotal,
                          needed: requirement.needsOxygenBed,
                        ),
                        Divider(height: 28, color: Colors.white.withValues(alpha: 0.05)),
                        Row(
                          children: [
                            Icon(Icons.medical_services_outlined,
                                color: hospital.hasEmergencyOT
                                    ? const Color(0xFF32D74B)
                                    : Colors.white24,
                                size: 22),
                            const SizedBox(width: 14),
                            const Expanded(
                                child: Text('Emergency OT',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w700, color: Colors.white))),
                            if (requirement.needsEmergencyOT)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: primaryRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('REQUIRED',
                                    style: TextStyle(
                                        color: primaryRed,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5)),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: hospital.hasEmergencyOT
                                    ? const Color(0xFF32D74B).withValues(alpha: 0.1)
                                    : primaryRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                hospital.hasEmergencyOT
                                    ? 'AVAILABLE'
                                    : 'UNAVAILABLE',
                                style: TextStyle(
                                    color: hospital.hasEmergencyOT
                                        ? const Color(0xFF32D74B)
                                        : primaryRed,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  _sectionTitle('SPECIALTIES'),
                  const SizedBox(height: 16),
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

                  const SizedBox(height: 28),
                  _sectionTitle('PATIENT SUMMARY'),
                  const SizedBox(height: 16),
                  _card(
                    child: Column(
                      children: [
                        _summaryRow('PATIENT', patient.name),
                        _summaryRow('AGE', '${patient.age} years'),
                        _summaryRow('CONDITION', patient.condition),
                        _summaryRow('SEVERITY', patient.severity),
                        _summaryRow('PICKUP', patient.citizenLocation),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => _confirmTransfer(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF32D74B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('CONFIRM TRANSFER',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white38,
                        side:
                            BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('BACK TO RESULTS',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
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
    const primaryRed = Color(0xFFFF3B30);
    const surfaceColor = Color(0xFF161B26);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surfaceColor,
        title: const Text('CONFIRM TRANSFER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        content: Text(
            'Send emergency transfer request to ${hospital.name} for patient ${patient.name}?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF32D74B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
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
            child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white38,
          letterSpacing: 2));

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
    final color = available > 0 ? const Color(0xFF32D74B) : const Color(0xFFFF3B30);

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
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  if (needed) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('REQUIRED',
                          style: TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
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
                fontWeight: FontWeight.w900,
                fontSize: 14)),
      ],
    );
  }

  Widget _specialtyChip(String s, bool isMatch) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isMatch
            ? const Color(0xFF32D74B).withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isMatch
                ? const Color(0xFF32D74B).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMatch) ...[
            const Icon(Icons.star_rounded,
                color: Color(0xFF32D74B), size: 12),
            const SizedBox(width: 4),
          ],
          Text(s.toUpperCase(),
              style: TextStyle(
                  color: isMatch
                      ? const Color(0xFF32D74B)
                      : Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white)),
          ],
        ),
      );

  Widget _infoPill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 12),
            const SizedBox(width: 6),
            Text(text,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  Widget _matchScorePill(double score) {
    final color = score >= 70 ? const Color(0xFF32D74B) : const Color(0xFFFFCC00);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('${score.toInt()}% MATCH',
          style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5)),
    );
  }
}
