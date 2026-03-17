import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
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
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final loc = await _locationService.getCurrentLocation();
      final results = await _firebaseService.fetchHospitals(
        widget.requirement,
        userLocation: loc == null ? null : ll.LatLng(loc.latitude, loc.longitude),
      );
      if (!mounted) return;
      setState(() {
        _hospitals = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hospitals = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFFF3B30);
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF161B26);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: const Text('MATCHED FACILITIES',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14)),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Patient summary bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_pin_circle_rounded,
                      color: primaryRed, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.patient.name}, ${widget.patient.age} YRS',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.patient.condition} · ${widget.patient.severity}'.toUpperCase(),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFF0D1117),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text('REQUIRES: ',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  const SizedBox(width: 4),
                  if (widget.requirement.needsICU)
                    _needChip('ICU'),
                  if (widget.requirement.needsVentilator)
                    _needChip('VENTILATOR'),
                  if (widget.requirement.needsOxygenBed)
                    _needChip('O₂ BED'),
                  if (widget.requirement.needsEmergencyOT)
                    _needChip('OT'),
                  _needChip(widget.requirement.specialDept.toUpperCase(),
                      color: const Color(0xFF32D74B)),
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
                        CircularProgressIndicator(color: primaryRed, strokeWidth: 2),
                        SizedBox(height: 20),
                        Text('SCANNING NEARBY FACILITIES…',
                            style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  )
                : _hospitals.isEmpty
                    ? const Center(
                        child: Text(
                            'NO FACILITIES MATCHED PATIENT REQUIREMENTS',
                            style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
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
    const primaryRed = Color(0xFFFF3B30);
    const surfaceColor = Color(0xFF161B26);
    
    final isBest = rank == 0;
    final score = h.matchScore;
    final load = h.loadPercent;
    final scoreColor = score >= 70
        ? const Color(0xFF32D74B)
        : score >= 40
            ? const Color(0xFFFFCC00)
            : primaryRed;

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isBest ? const Color(0xFF32D74B).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.05),
            width: isBest ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isBest
                    ? const Color(0xFF32D74B).withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isBest
                          ? const Color(0xFF32D74B).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isBest
                          ? const Icon(Icons.star_rounded,
                              color: Color(0xFF32D74B), size: 20)
                          : Text('${rank + 1}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white24,
                                  fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(h.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Colors.white)),
                            ),
                            if (isBest)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF32D74B),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('BEST MATCH',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1)),
                              )
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(width: 4),
                            Text(h.address,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                            const SizedBox(width: 12),
                            Icon(Icons.directions_car_rounded,
                                size: 12, color: Colors.white.withValues(alpha: 0.2)),
                            const SizedBox(width: 4),
                            Text('${h.distanceKm} km',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Match score
                  Column(
                    children: [
                      _loadPill(load),
                      const SizedBox(height: 6),
                      Text(
                        '${score.toInt()}%',
                        style: TextStyle(
                            color: scoreColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 20),
                      ),
                      Text('MATCH',
                          style: TextStyle(
                              color: scoreColor.withValues(alpha: 0.5),
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),

            // Resource grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _resBox('ICU', h.icuAvailable, h.icuTotal,
                      widget.requirement.needsICU),
                  _resBox('Vent', h.ventilatorsAvailable,
                      h.ventilatorsTotal, widget.requirement.needsVentilator),
                  _resBox('O₂', h.oxygenBedsAvailable,
                      h.oxygenBedsTotal, widget.requirement.needsOxygenBed),
                  _resOT(h.hasEmergencyOT, widget.requirement.needsEmergencyOT),
                ],
              ),
            ),

            // Specialty match
            Padding(
              padding:
                  const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                children: [
                  Icon(
                    h.specialties
                            .contains(widget.requirement.specialDept)
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 14,
                    color: h.specialties
                            .contains(widget.requirement.specialDept)
                        ? const Color(0xFF32D74B)
                        : Colors.white24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    h.specialties.contains(widget.requirement.specialDept)
                        ? '${widget.requirement.specialDept} DEPT AVAILABLE'
                        : '${widget.requirement.specialDept} UNAVAILABLE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: h.specialties
                                .contains(widget.requirement.specialDept)
                            ? const Color(0xFF32D74B)
                            : Colors.white24),
                  ),
                  const Spacer(),
                  Text('VIEW DETAILS →',
                      style: TextStyle(
                          color: primaryRed.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5)),
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
    final color = isOk ? const Color(0xFF32D74B) : const Color(0xFFFF3B30);
    final highlight = needed && isOk;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? color.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: highlight
              ? Border.all(color: color.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Text('$available',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _resOT(bool has, bool needed) {
    final color = has ? const Color(0xFF32D74B) : Colors.white24;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: needed && has
              ? const Color(0xFF32D74B).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: needed && has
              ? Border.all(
                  color: const Color(0xFF32D74B).withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Icon(has ? Icons.check_rounded : Icons.close_rounded,
                color: color, size: 18),
            const SizedBox(height: 2),
            Text('OT',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _loadPill(double loadPercent) {
    final percent = (loadPercent * 100).round();
    final color = percent < 50
        ? const Color(0xFF32D74B)
        : percent < 75
            ? const Color(0xFFFFCC00)
            : const Color(0xFFFF3B30);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text('LOAD $percent%',
          style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }

  Widget _needChip(String label, {Color color = Colors.white}) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      );

  Widget _severityBadge(String s) {
    final color = s == 'Critical'
        ? const Color(0xFFFF3B30)
        : s == 'Moderate'
            ? const Color(0xFFFFCC00)
            : const Color(0xFF32D74B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(s.toUpperCase(),
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5)),
    );
  }
}
