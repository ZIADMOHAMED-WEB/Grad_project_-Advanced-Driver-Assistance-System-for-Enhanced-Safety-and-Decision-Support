import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Only import firebase_auth on mobile and web
// ignore: uri_does_not_exist
import 'package:firebase_auth/firebase_auth.dart'
    if (dart.library.io) 'firebase_auth_stub.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
