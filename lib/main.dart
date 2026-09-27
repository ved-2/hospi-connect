import 'dart:async';
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebaseSafely();
  runApp(const AmbulanceApp());
}

Future<void> _initFirebaseSafely() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.log('Firebase Initialized Successfully');
  } on UnsupportedError catch (e) {
    AppLogger.log('Firebase Unsupported Platform: $e');
  } catch (e) {
    AppLogger.log('Firebase Init Error: $e');
  }
}

class AmbulanceApp extends StatelessWidget {
  const AmbulanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediRush Ambulance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF3B30),
          secondary: Color(0xFF1C222E),
          surface: Color(0xFF161B26),
          onSurface: Colors.white,
          error: Color(0xFFFF453A),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0E14),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF161B26),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3B30),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  Map<String, dynamic>? _ambulanceData;
  bool _loading = true;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    // Listen on the platform thread safely
    _authSub = FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        if (!mounted) return;
        if (user == null) {
          setState(() {
            _user = null;
            _loading = false;
          });
        } else {
          final data = await FirebaseService().getAmbulanceData(user.uid);
          if (!mounted) return;
          setState(() {
            _user = user;
            _ambulanceData = data;
            _loading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) setState(() => _loading = false);
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF090A0F),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF007AFF))),
      );
    }
    if (_user == null) return const LoginScreen();

    final ambulanceId = _ambulanceData?['ambulanceId'] ?? 'AMB-001';
    final driverName = (_ambulanceData?['driverName'] as String?)?.trim();
    final fallbackName = (_user!.email?.split('@').first ?? 'Driver').trim();
    final resolvedName = (driverName == null || driverName.isEmpty)
        ? (fallbackName.isEmpty ? 'Driver' : fallbackName)
        : driverName;

    return DashboardScreen(
      ambulanceId: ambulanceId,
      driverName: resolvedName,
      uid: _user!.uid,
    );
  }
}
