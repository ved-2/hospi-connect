import 'package:flutter/material.dart';
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
    final eta = (widget.hospital.distanceKm * 3).round(); // rough ETA

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 30),

                // Success icon
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: Colors.white, size: 65),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Transfer Confirmed!',
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency request sent to ${widget.hospital.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 36),

                // ETA card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('Estimated Arrival',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text(
                        '$eta minutes',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.hospital.distanceKm} km to destination',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hospital info
                _infoCard(
                  icon: Icons.local_hospital_rounded,
                  color: const Color(0xFFE53935),
                  title: 'Destination Hospital',
                  value: widget.hospital.name,
                  subtitle: widget.hospital.address,
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.person_rounded,
                  color: const Color(0xFF2E7D32),
                  title: 'Patient',
                  value: widget.patient.name,
                  subtitle:
                      '${widget.patient.condition} · ${widget.patient.severity}',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: Icons.phone_rounded,
                  color: const Color(0xFF6A1B9A),
                  title: 'Hospital Contact',
                  value: widget.hospital.phone,
                  subtitle: 'Call now to alert ER team',
                ),

                const SizedBox(height: 24),

                // Alert chip
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hospital ER has been alerted. They are preparing resources for your arrival.',
                          style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DashboardScreen(
                              ambulanceId: 'AMB-001',
                              driverName: 'Rajesh Patil')),
                      (r) => false,
                    ),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Back to Dashboard',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
    return Container(
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1A2E))),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
