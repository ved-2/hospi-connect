import 'package:flutter/material.dart';
import '../models/models.dart';
import 'hospital_detail_screen.dart';

class HospitalResultsScreen extends StatefulWidget {
  final PatientCase patient;
  final ResourceRequirement requirement;

  const HospitalResultsScreen({
    super.key,
    required this.patient,
    required this.requirement,
  });

  @override
  State<HospitalResultsScreen> createState() => _HospitalResultsScreenState();
}

class _HospitalResultsScreenState extends State<HospitalResultsScreen> {
  bool _loading = true;
  List<Hospital> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));
    final results = MockData.getHospitals(widget.requirement);
    setState(() {
      _hospitals = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: red,
        foregroundColor: Colors.white,
        title: const Text('Matched Hospitals',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Patient summary bar
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: const Color(0xFFB71C1C),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle_rounded,
                    color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.patient.name}, ${widget.patient.age} yrs',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        '${widget.patient.condition} · ${widget.patient.severity}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _severityBadge(widget.patient.severity),
              ],
            ),
          ),

          // Resource needs
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1A1A2E),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text('Needs: ',
                      style:
                          TextStyle(color: Colors.white60, fontSize: 12)),
                  if (widget.requirement.needsICU)
                    _needChip('ICU'),
                  if (widget.requirement.needsVentilator)
                    _needChip('Ventilator'),
                  if (widget.requirement.needsOxygenBed)
                    _needChip('O₂ Bed'),
                  if (widget.requirement.needsEmergencyOT)
                    _needChip('OT'),
                  _needChip(widget.requirement.specialDept,
                      color: const Color(0xFF81C784)),
                ],
              ),
            ),
          ),

          // Results
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFE53935)),
                        SizedBox(height: 16),
                        Text('Scanning nearby hospitals…',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _hospitals.isEmpty
                    ? const Center(
                        child: Text(
                            'No hospitals found matching patient needs.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _hospitals.length,
                        itemBuilder: (ctx, i) =>
                            _hospitalCard(ctx, _hospitals[i], i),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(BuildContext context, Hospital h, int rank) {
    final isBest = rank == 0;
    final score = h.matchScore;
    final scoreColor = score >= 70
        ? const Color(0xFF2E7D32)
        : score >= 40
            ? const Color(0xFFFF8F00)
            : const Color(0xFFE53935);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HospitalDetailScreen(
            hospital: h,
            patient: widget.patient,
            requirement: widget.requirement,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isBest
              ? Border.all(color: const Color(0xFF2E7D32), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isBest
                    ? const Color(0xFF2E7D32).withOpacity(0.07)
                    : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isBest
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isBest
                          ? const Icon(Icons.star_rounded,
                              color: Colors.white, size: 20)
                          : Text('${rank + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(h.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF1A1A2E))),
                            ),
                            if (isBest)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('BEST MATCH',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1)),
                              )
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(h.address,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            const SizedBox(width: 10),
                            const Icon(Icons.directions_car,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text('${h.distanceKm} km',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Match score
                  Column(
                    children: [
                      Text(
                        '${score.toInt()}%',
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      Text('match',
                          style: TextStyle(
                              color: scoreColor.withOpacity(0.7),
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            // Resource grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _resBox('ICU', h.icuAvailable, h.icuTotal,
                      widget.requirement.needsICU),
                  _resBox('Ventilator', h.ventilatorsAvailable,
                      h.ventilatorsTotal, widget.requirement.needsVentilator),
                  _resBox('O₂ Bed', h.oxygenBedsAvailable,
                      h.oxygenBedsTotal, widget.requirement.needsOxygenBed),
                  _resOT(h.hasEmergencyOT, widget.requirement.needsEmergencyOT),
                ],
              ),
            ),

            // Specialty match
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                children: [
                  Icon(
                    h.specialties
                            .contains(widget.requirement.specialDept)
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 16,
                    color: h.specialties
                            .contains(widget.requirement.specialDept)
                        ? Colors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    h.specialties.contains(widget.requirement.specialDept)
                        ? '${widget.requirement.specialDept} dept available'
                        : '${widget.requirement.specialDept} not available',
                    style: TextStyle(
                        fontSize: 12,
                        color: h.specialties
                                .contains(widget.requirement.specialDept)
                            ? Colors.green.shade700
                            : Colors.grey),
                  ),
                  const Spacer(),
                  const Text('View Details →',
                      style: TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resBox(
      String label, int available, int total, bool needed) {
    final isOk = available > 0;
    final color = isOk ? const Color(0xFF2E7D32) : const Color(0xFFE53935);
    final highlight = needed && isOk;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: highlight
              ? color.withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: highlight
              ? Border.all(color: color.withOpacity(0.4))
              : null,
        ),
        child: Column(
          children: [
            Text('$available',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 9),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _resOT(bool has, bool needed) {
    final color = has ? const Color(0xFF2E7D32) : Colors.grey;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: needed && has
              ? const Color(0xFF2E7D32).withOpacity(0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: needed && has
              ? Border.all(
                  color: const Color(0xFF2E7D32).withOpacity(0.4))
              : null,
        ),
        child: Column(
          children: [
            Icon(has ? Icons.check_rounded : Icons.close_rounded,
                color: color, size: 18),
            const Text('OT',
                style: TextStyle(color: Colors.grey, fontSize: 9)),
          ],
        ),
      ),
    );
  }

  Widget _needChip(String label, {Color color = Colors.white}) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _severityBadge(String s) {
    final color = s == 'Critical'
        ? Colors.red.shade200
        : s == 'Moderate'
            ? Colors.orange.shade200
            : Colors.green.shade200;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Text(s,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold)),
    );
  }
}
