import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _idCtrl = TextEditingController(text: 'AMB-001');
  final _passCtrl = TextEditingController(text: '1234');
  final _licenseCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _idCtrl.dispose();
    _passCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // Simulate network call
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          ambulanceId: _idCtrl.text.trim(),
          driverName: 'Rajesh Patil',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = const Color(0xFFE53935);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo / Siren icon
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: red.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: red, width: 2.5),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      size: 58, color: Color(0xFFE53935)),
                ),
                const SizedBox(height: 22),

                const Text(
                  'MediRush',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'AMBULANCE PORTAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 50),

                // Form card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter your ambulance credentials',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13),
                        ),
                        const SizedBox(height: 28),
                        _buildField(
                          controller: _idCtrl,
                          label: 'Ambulance ID',
                          hint: 'e.g. AMB-001',
                          icon: Icons.badge_outlined,
                          validator: (v) =>
                              v!.isEmpty ? 'Enter ambulance ID' : null,
                        ),
                        const SizedBox(height: 18),
                        _buildField(
  controller: _passCtrl,
  label: 'Password',
  hint: '••••••••',
  icon: Icons.lock_outline,
  obscure: _obscure,
  suffixIcon: IconButton(
    icon: Icon(
      _obscure
          ? Icons.visibility_off_outlined
          : Icons.visibility_outlined,
      color: Colors.white38,
    ),
    onPressed: () =>
        setState(() => _obscure = !_obscure),
  ),
  validator: (v) =>
      v!.length < 4 ? 'Min 4 characters' : null,
),
const SizedBox(height: 18),
                          _buildField(
                            controller: _licenseCtrl,
                            label: 'Driver\'s License Number',
                            hint: 'e.g. MH-1234567890123',
                            icon: Icons.credit_card_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Enter license number';
                              final regex = RegExp(r'^[A-Z]{2}-?\d{13}$');
                              if (!regex.hasMatch(v.trim().toUpperCase())) {
                                return 'Invalid format (e.g. MH-1234567890123)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 22),
                                      SizedBox(width: 10),
                                      Text('LOGIN',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.white38, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Demo: AMB-001 / 1234',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
            prefixIcon: Icon(icon, color: Colors.white38, size: 22),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.orange),
            ),
            errorStyle: const TextStyle(color: Colors.orange),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
