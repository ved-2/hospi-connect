import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String driverName;
  final String initialAmbulanceId;

  const ProfileScreen({
    super.key,
    required this.uid,
    required this.driverName,
    required this.initialAmbulanceId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _ambController = TextEditingController();
  late String _currentAmbulanceId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentAmbulanceId = widget.initialAmbulanceId;
    _ambController.text = _currentAmbulanceId;
  }

  @override
  void dispose() {
    _ambController.dispose();
    super.dispose();
  }

  Future<void> _updateAmbulance() async {
    final newId = _ambController.text.trim().toUpperCase();
    if (newId.isEmpty || newId == _currentAmbulanceId) return;

    setState(() => _isSaving = true);
    await _firebaseService.updateAmbulanceId(widget.uid, newId);
    setState(() {
      _currentAmbulanceId = newId;
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ambulance ID updated to $newId'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF0F172A);
    const Color surface = Color(0xFF1E293B);
    const Color primaryRed = Color(0xFFEF4444);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textSecondary = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('DRIVER PROFILE'),
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context, _currentAmbulanceId),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Driver Profile Header
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: primaryRed.withValues(alpha: 0.1),
                      child: const Icon(Icons.person_rounded, size: 60, color: primaryRed),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.driverName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Emergency Dispatch Operator',
                      style: const TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF334155)),
                    const SizedBox(height: 24),
                    _buildStatRow('Unit Status', 'ACTIVE', const Color(0xFF10B981)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Change Ambulance Section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSIGNED AMBULANCE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ambController,
                      style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: background.withValues(alpha: 0.5),
                        hintText: 'Enter Ambulance ID',
                        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.emergency_rounded, color: primaryRed, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryRed, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateAmbulance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'UPDATE AMBULANCE ID',
                                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Logout Section
              Material(
                color: textPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    await _firebaseService.updateAmbulanceStatus(widget.uid, false);
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      final navigator = Navigator.of(context);
                      navigator.popUntil((route) => route.isFirst);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout_rounded, color: primaryRed, size: 20),
                        SizedBox(width: 12),
                        const Text(
                          'SECURE LOGOUT',
                          style: TextStyle(
                            color: primaryRed,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: valueColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
