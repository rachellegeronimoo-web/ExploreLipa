import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('========== EXPLORE LIPA STARTING ==========');
  debugPrint('MAIN: Initializing Firebase...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('MAIN: FIREBASE INITIALIZED SUCCESSFULLY');

    runApp(const ExploreLipaApp());
  } catch (e) {
    debugPrint('MAIN: FIREBASE INITIALIZATION ERROR: $e');

    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase initialization failed:\n$e',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ExploreLipaApp extends StatelessWidget {
  const ExploreLipaApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('MAIN: EXPLORE LIPA APP BUILDING');
    debugPrint('MAIN: OPENING AUTH GATE');

    return MaterialApp(
      title: 'Explore Lipa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}