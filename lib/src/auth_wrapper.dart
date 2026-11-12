import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'complete_profile_screen.dart';
import 'theme/app_theme.dart';
import '../home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.orange),
            ),
          );
        }

        if (authSnapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(authSnapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.orange),
                  ),
                );
              }
              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;
              if (!userSnapshot.hasData ||
                  !userSnapshot.data!.exists ||
                  userData == null ||
                  userData['perfilCompleto'] != true) {
                return const CompleteProfileScreen();
              }
              return const HomeScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
