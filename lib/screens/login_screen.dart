import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _isSignup = false;
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
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String ambulanceId;
      String driverName;

      if (Firebase.apps.isNotEmpty) {
        final email = _usernameCtrl.text.trim();
        final password = _passCtrl.text;
        final cred = _isSignup
            ? await FirebaseAuth.instance
                .createUserWithEmailAndPassword(email: email, password: password)
            : await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
        final user = cred.user;
        if (user == null) {
          throw Exception('Auth failed: no user');
        }

        final docRef =
            FirebaseFirestore.instance.collection('ambulances').doc(user.uid);
        final doc = await docRef.get();
        final existingId = doc.data()?['ambulanceId'] as String?;
        ambulanceId = existingId ?? _generateAmbulanceId(user.uid);
        driverName = doc.data()?['driverName'] as String? ??
            _deriveDriverName(email);
        await docRef.set({
          'ambulanceId': ambulanceId,
          'username': email,
          'license': _licenseCtrl.text.trim(),
          'driverName': driverName,
          'updatedAt': FieldValue.serverTimestamp(),
          if (_isSignup) 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        ambulanceId = _generateAmbulanceId('');
        driverName = _deriveDriverName(_usernameCtrl.text.trim());
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            ambulanceId: ambulanceId,
            driverName: driverName,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Login failed');
    } catch (e) {
      _showError('Login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _generateAmbulanceId(String uid) {
    final clean = uid.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.isNotEmpty) {
      return 'AMB-${clean.substring(0, clean.length >= 6 ? 6 : clean.length).toUpperCase()}';
    }
    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    final tail = ms.substring(ms.length >= 6 ? ms.length - 6 : 0);
    return 'AMB-$tail';
  }

  String _deriveDriverName(String username) {
    if (username.isEmpty) return 'Driver';
    final base = username.split('@').first;
    return base.isEmpty ? 'Driver' : base[0].toUpperCase() + base.substring(1);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFFF3B30);
    const bgColor = Color(0xFF0B0E14);
    const surfaceColor = Color(0xFF161B26);

    return Scaffold(
      backgroundColor: bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Premium Logo with Glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryRed.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: const Icon(Icons.local_hospital_rounded,
                          size: 50, color: primaryRed),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                const Text(
                  'MediRush',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AMBULANCE PORTAL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 60),

                // High Contrast Form Container
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isSignup ? 'Register Unit' : 'Operator Secure Login',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildField(
                          controller: _usernameCtrl,
                          label: 'SECURE IDENTIFIER',
                          hint: 'ID or Email Address',
                          icon: Icons.shield_outlined,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Identifier required' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildField(
                          controller: _passCtrl,
                          label: 'ACCESS CODE',
                          hint: 'Enter passcode',
                          icon: Icons.key_outlined,
                          obscure: _obscure,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) =>
                              v!.length < 6 ? 'Min 6 characters' : null,
                        ),
                        if (_isSignup) ...[
                          const SizedBox(height: 24),
                          _buildField(
                            controller: _confirmCtrl,
                            label: 'VERIFY ACCESS CODE',
                            hint: 'Re-enter passcode',
                            icon: Icons.verified_user_outlined,
                            obscure: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (!_isSignup) return null;
                              if (v == null || v.isEmpty) return 'Verify passcode';
                              if (v != _passCtrl.text) return 'Codes do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          _buildField(
                            controller: _licenseCtrl,
                            label: 'OPERATOR LICENSE',
                            hint: 'State-issued License No.',
                            icon: Icons.badge_outlined,
                            validator: (v) {
                              if (!_isSignup) return null;
                              if (v == null || v.trim().isEmpty) return 'License required';
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(_isSignup ? 'CREATE SECURE ACCOUNT' : 'SECURE SIGN IN',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _authToggle(),
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
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
            prefixIcon: Icon(icon, color: const Color(0xFFFF3B30).withValues(alpha: 0.6), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF3B30), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF453A)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _authToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignup ? 'ALREADY REGISTERED?' : 'NEW OPERATOR?',
          style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() => _isSignup = !_isSignup),
          child: Text(
            _isSignup ? 'SIGN IN' : 'REGISTER',
            style: const TextStyle(
                color: Color(0xFFFF3B30), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
}
