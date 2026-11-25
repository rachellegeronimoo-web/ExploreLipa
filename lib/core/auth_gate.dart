
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'favorites_store.dart';
import '../screens/auth_page.dart';
import '../screens/dashboard_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('AUTH GATE BUILDING');

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('AUTH GATE STATE: ${snapshot.connectionState}');
        debugPrint('AUTH GATE USER: ${snapshot.data?.email}');

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data != null) {
          return const _AuthenticatedDashboard();
        }

        return const AuthPage();
      },
    );
  }
}

class _AuthenticatedDashboard extends StatefulWidget {
  const _AuthenticatedDashboard();

  @override
  State<_AuthenticatedDashboard> createState() =>
      _AuthenticatedDashboardState();
}

class _AuthenticatedDashboardState
    extends State<_AuthenticatedDashboard> {
  @override
  void initState() {
    super.initState();
    _loadSavedFavorites();
  }

  Future<void> _loadSavedFavorites() async {
    debugPrint('AUTH GATE: Loading saved favorites...');

    await FavoritesStore.load();

    debugPrint(
      'AUTH GATE: Favorites loaded: '
      '${FavoritesStore.favorites.value.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}
