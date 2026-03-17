import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../models/models.dart';

// --- Blinkit Design System ---
class BlinkitTheme {
  static const Color background = Color(0xFFF4F6F8); // Light gray-blue
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color brandYellow = Color(0xFFF8CB46); // Blinkit Yellow
  static const Color textDark = Color(0xFF000000); // Pure Black
  static const Color textSecondary = Color(0xFF6B7280); // Gray
  static const Color alertRed = Color(0xFFE53935); // Emergency Red
  static const Color successGreen = Color(0xFF0C9547); // Blinkit Green
  static const Color accentPurple = Color(0xFF8B5CF6); // Info Purple
  static const Color borderLight = Color(0xFFE5E7EB);
  
  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderLight),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
    ],
  );
}

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
    // Logic kept entirely intact
    final eta = (widget.hospital.distanceKm * 3).round();

    return Scaffold(
      backgroundColor: BlinkitTheme.background,
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
                      color: BlinkitTheme.successGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: BlinkitTheme.successGreen.withOpacity(0.3), width: 3),
                    ),
                    child: const Icon(LucideIcons.check,
                        color: BlinkitTheme.successGreen, size: 60),
                  ),
                ),
                const SizedBox(height: 32),

                const Text(
                  'TRANSFER CONFIRMED',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: BlinkitTheme.textDark,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  'Emergency request sent to ${widget.hospital.name}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: BlinkitTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 40),

                // ETA card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BlinkitTheme.cardDecoration,
                  child: Column(
                    children: [
                      const Text('ESTIMATED ARRIVAL',
                          style: TextStyle(
                              color: BlinkitTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(height: 12),
                      Text(
                        '$eta',
                        style: const TextStyle(
                            color: BlinkitTheme.textDark,
                            fontSize: 64,
                            height: 1,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'MINUTES',
                        style: TextStyle(
                            color: BlinkitTheme.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: BlinkitTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${widget.hospital.distanceKm} km to destination',
                          style: const TextStyle(
                              color: BlinkitTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Hospital info
                _infoCard(
                  icon: LucideIcons.building,
                  color: BlinkitTheme.alertRed,
                  title: 'DESTINATION',
                  value: widget.hospital.name,
                  subtitle: widget.hospital.address,
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: LucideIcons.user,
                  color: BlinkitTheme.textDark,
                  title: 'PATIENT',
                  value: widget.patient.name,
                  subtitle:
                      '${widget.patient.condition} · ${widget.patient.severity}',
                ),
                const SizedBox(height: 12),
                _infoCard(
                  icon: LucideIcons.phoneCall,
                  color: BlinkitTheme.successGreen,
                  title: 'HOSPITAL CONTACT',
                  value: widget.hospital.phone,
                  subtitle: 'Call now to alert ER team',
                ),

                const SizedBox(height: 24),

                // Alert chip
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: BlinkitTheme.brandYellow.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: BlinkitTheme.brandYellow.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.bellRing,
                          color: Color(0xFFD97706), size: 24), // Darker amber for contrast
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Hospital ER has been alerted. They are preparing resources for your arrival.',
                          style: TextStyle(
                              color: const Color(0xFFB45309), // Darker amber text for readability
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Back to Dashboard Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BlinkitTheme.textDark, // High contrast black button
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.map, size: 20),
                        SizedBox(width: 10),
                        Text('BACK TO DASHBOARD',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
      padding: const EdgeInsets.all(20),
      decoration: BlinkitTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: BlinkitTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: BlinkitTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: BlinkitTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
