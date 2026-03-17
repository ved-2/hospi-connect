import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const MaterialApp(home: TestScreen()));
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String out = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('emergencies').get();
      setState(() {
        out = 'Found ${snap.docs.length} emergencies.\n';
        for (var doc in snap.docs) {
          out += '${doc.id}: status=${doc.data()['status']}, transportType=${doc.data()['transportType']}\n';
        }
      });
    } catch (e) {
      setState(() {
        out = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(child: Text(out)),
      ),
    );
  }
}
