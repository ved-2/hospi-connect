import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';
import 'dashboard_screen.dart';

class TransferConfirmedScreen extends StatefulWidget {
  final Hospital hospital;
  final PatientCase patient;

  const TransferConfirmedScreen({
    super.key,
    required this.hospital,
    required this.patient,
  });

  @override
  State<TransferConfirmedScreen> createState() =>
      _TransferConfirmedScreenState();
}

class _TransferConfirmedScreenState extends State<TransferConfirmedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFFF3B30);
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF161B26);
    final eta = (widget.hospital.distanceKm * 3).round();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Success icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF32D74B).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF32D74B).withValues(alpha: 0.3), width: 3),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Color(0xFF32D74B), size: 60),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'TRANSFER CONFIRMED',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 10),
                Text(
                  'Emergency request sent to ${widget.hospital.name}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 40),

                // ETA card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFF007AFF).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('ESTIMATED ARRIVAL',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Text(
                        '$eta',
                        style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 56,
                            fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'MINUTES',
                        style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.hospital.distanceKm} km to destination',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hospital info
                _infoCard(
                  icon: Icons.local_hospital_rounded,
                  color: primaryRed,
                  title: 'DESTINATION',
                  value: widget.hospital.name,
                  subtitle: widget.hospital.address,
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.person_rounded,
                  color: const Color(0xFF32D74B),
                  title: 'PATIENT',
                  value: widget.patient.name,
                  subtitle:
                      '${widget.patient.condition} · ${widget.patient.severity}',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFFAF52DE),
                  title: 'HOSPITAL CONTACT',
                  value: widget.hospital.phone,
                  subtitle: 'Call now to alert ER team',
                ),

                const SizedBox(height: 24),

                // Alert chip
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFF9500).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Color(0xFFFF9500), size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Hospital ER has been alerted. They are preparing resources for your arrival.',
                          style: TextStyle(
                              color: const Color(0xFFFF9500).withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DashboardScreen(
                              ambulanceId: 'AMB-001',
                              driverName: 'Rajesh Patil',
                              uid: FirebaseAuth.instance.currentUser?.uid ?? 'unknown')),
                      (r) => false,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.explore_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('BACK TO DASHBOARD',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    const surfaceColor = Color(0xFF161B26);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
